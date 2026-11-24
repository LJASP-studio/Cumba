import Foundation
import Testing

@testable import Cumba

struct StatusLineBridgeTests {
  private let socket = "/Users/example/Library/Application Support/Cumba/hook.sock"
  private let token = String(repeating: "ab", count: 16)

  @Test func wrapsTheUsersCommandAndPutsItBack() throws {
    let previous = #"bash ~/.claude/line.sh "it's" $HOME"#
    let settings: [String: Any] = [
      "statusLine": ["type": "command", "command": previous, "padding": 1], "model": "opus",
    ]
    let installed = HookInstaller.installingStatusLine(
      socketPath: socket, token: token, into: settings)
    let line = try #require(installed["statusLine"] as? [String: Any])
    let command = try #require(line["command"] as? String)
    #expect(line["padding"] as? Int == 1)
    #expect(HookInstaller.previousStatusLine(in: command) == .some(previous))
    #expect(
      HookInstaller.statusLineStatus(of: installed, socketPath: socket, token: token) == .installed)
    #expect(
      HookInstaller.statusLineStatus(of: installed, socketPath: socket, token: "other")
        == .outdated)
    // Installing again keeps the user's command, not ours inside ours.
    let again = HookInstaller.installingStatusLine(
      socketPath: socket, token: token, into: installed)
    #expect(HookInstaller.render(again) == HookInstaller.render(installed))
    let removed = HookInstaller.removingStatusLine(from: installed)
    #expect(HookInstaller.render(removed) == HookInstaller.render(settings))
  }

  @Test func withoutAStatusLineRemovingLeavesNone() {
    let installed = HookInstaller.installingStatusLine(socketPath: socket, token: token, into: [:])
    #expect(
      HookInstaller.statusLineStatus(of: [:], socketPath: socket, token: token) == .notInstalled)
    #expect(HookInstaller.removingStatusLine(from: installed).isEmpty)
    // Someone else's status line isn't touched by Remove.
    let other: [String: Any] = ["statusLine": ["type": "command", "command": "echo hi"]]
    #expect(
      HookInstaller.render(HookInstaller.removingStatusLine(from: other))
        == HookInstaller.render(other))
  }

  @Test func theDiffHidesTheToken() {
    let installed = HookInstaller.installingStatusLine(socketPath: socket, token: token, into: [:])
    let plan = HookInstaller.plan(file: "", from: [:], to: installed)
    #expect(!plan.diff.map(\.text).joined().contains(token))
  }

  @Test func runsTheUsersCommandWithTheSameInput() throws {
    let previous = #"cat; printf ' %s' "it's""#
    let command = HookInstaller.statusLineCommand(
      socketPath: "/nonexistent/hook.sock", token: token, previous: previous)
    let process = Process()
    process.executableURL = URL(filePath: "/bin/sh")
    process.arguments = ["-c", command]
    let input = Pipe()
    let output = Pipe()
    process.standardInput = input
    process.standardOutput = output
    try process.run()
    input.fileHandleForWriting.write(Data(#"{"session_id":"s"}"#.utf8))
    try input.fileHandleForWriting.close()
    process.waitUntilExit()
    let text = String(decoding: output.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
    #expect(text == #"{"session_id":"s"} it's"#)
  }

  @Test func readsContextAndLimits() throws {
    let data = Data(
      #"{"session_id":"s1","context_window":{"used_percentage":42.5,"context_window_size":200000},"rate_limits":{"five_hour":{"used_percentage":30,"resets_at":1764633600},"seven_day":{"used_percentage":8}}}"#
        .utf8)
    let input = try #require(StatusLineRoute.Input.decode(data))
    #expect(input.contextFraction == 0.425)
    #expect(input.limits.map(\.windowMinutes) == [300, 10080])
    #expect(input.limits[0].resetsAt == Date(timeIntervalSince1970: 1_764_633_600))
    // Early on, before the first answer, the fields can be missing.
    let early = try #require(StatusLineRoute.Input.decode(Data(#"{"session_id":"s1"}"#.utf8)))
    #expect(early.contextFraction == nil)
    #expect(early.limits.isEmpty)
  }

  @MainActor
  @Test func statusLineNumbersWinOverTheTranscript() throws {
    let service = ClaudeCodeService(liveActivities: LiveActivityCenter())
    let prompt = try #require(
      HookPayload.decode(
        Data(#"{"session_id":"s1","hook_event_name":"UserPromptSubmit","cwd":"/r/demo"}"#.utf8)))
    service.handle(prompt)
    service.setUsage(
      of: "s1", context: 0.4, limits: [UsageLimit(usedFraction: 0.3, windowMinutes: 300)],
      fromStatusLine: true)
    let session = try #require(service.sessions.first)
    #expect(session.hasStatusLine)
    #expect(session.contextFraction == 0.4)
    #expect(session.limits.count == 1)
  }
}
