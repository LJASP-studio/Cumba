import FlyingFox
import Foundation
import Testing

@testable import Cumba

struct TerminalTabsTests {
  @Test func acceptsOnlyTerminalDevices() {
    #expect(TerminalTabs.device("ttys003") == "/dev/ttys003")
    #expect(TerminalTabs.device(" ttys12 ") == "/dev/ttys12")
    for value in ["??", "", "ttys", "ttys1\"", "../ttys1", "console", nil] as [String?] {
      #expect(TerminalTabs.device(value) == nil)
    }
  }

  @Test func scriptsOnlyKnownTerminals() throws {
    let script = try #require(TerminalTabs.script(for: TerminalTabs.terminal, tty: "/dev/ttys003"))
    #expect(script.contains(#"tty of t is "/dev/ttys003""#))
    #expect(TerminalTabs.script(for: TerminalTabs.iTerm, tty: "/dev/ttys003") != nil)
    #expect(TerminalTabs.script(for: "com.example.Other", tty: "/dev/ttys003") == nil)
  }

  @Test func hookCommandSendsTheParentsTTY() throws {
    let command = HookInstaller.command(
      socketPath: "/tmp/x.sock", token: String(repeating: "a", count: 64), timeout: 5)
    #expect(command.contains("\(ClaudeHookRoute.ttyHeader): $(/bin/ps -o tty= -p $PPID"))
    // The substitution itself runs in /bin/sh and gives a tty name or "??".
    let process = Process()
    process.executableURL = URL(filePath: "/bin/sh")
    process.arguments = ["-c", "printf %s \"$(/bin/ps -o tty= -p $PPID 2>/dev/null)\""]
    let output = Pipe()
    process.standardOutput = output
    try process.run()
    process.waitUntilExit()
    let text = String(decoding: output.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
    #expect(!text.isEmpty)
  }

  @MainActor
  @Test func routeKeepsTheSessionsTTY() async throws {
    let token = String(repeating: "c", count: 64)
    let service = ClaudeCodeService(liveActivities: LiveActivityCenter())
    let route = ClaudeHookRoute(token: token, service: service)
    let headers: HTTPHeaders = [
      .host: "localhost", HTTPHeader(RequestGuard.tokenHeader): token,
      HTTPHeader(ClaudeHookRoute.ttyHeader): "ttys007",
    ]
    let body = Data(
      #"{"session_id":"t1","hook_event_name":"UserPromptSubmit","cwd":"/r/demo"}"#.utf8)
    let request = HTTPRequest(
      method: .POST, version: .http11, path: "/claude/hook", query: [], headers: headers,
      body: HTTPBodySequence(data: body))
    #expect(try await route.handleRequest(request).statusCode == .ok)
    while service.sessions.isEmpty {
      await Task.yield()
    }
    #expect(service.sessions.first?.tty == "/dev/ttys007")
  }
}
