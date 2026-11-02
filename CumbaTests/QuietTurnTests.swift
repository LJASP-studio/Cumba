import FlyingFox
import Foundation
import Testing

@testable import Cumba

struct TranscriptInterruptTests {
  @Test func findsTheInterruptLineAtTheEnd() {
    let interrupted = [
      #"{"type":"user","message":{"role":"user","content":"Run the tests"}}"#,
      #"{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash"}]}}"#,
      #"{"type":"user","message":{"content":[{"type":"text","text":"[Request interrupted by user for tool use]"}]}}"#,
      #"{"type":"system","subtype":"informational"}"#,
    ]
    #expect(TranscriptReader.endsInInterrupt(interrupted.joined(separator: "\n")))
    let plain = #"{"type":"user","message":{"content":"[Request interrupted by user]"}}"#
    #expect(TranscriptReader.endsInInterrupt(plain))
  }

  @Test func aTurnThatGoesOnIsNotInterrupted() {
    let lines = [
      #"{"type":"user","message":{"content":[{"type":"text","text":"[Request interrupted by user]"}]}}"#,
      #"{"type":"user","message":{"content":"Try again"}}"#,
      #"{"type":"assistant","message":{"content":[{"type":"text","text":"On it."}]}}"#,
      #"{"type":"user","isMeta":true,"message":{"content":"[Request interrupted by user]"}}"#,
    ]
    #expect(!TranscriptReader.endsInInterrupt(lines.joined(separator: "\n")))
    #expect(!TranscriptReader.endsInInterrupt(""))
  }
}

@MainActor
struct QuietTurnTests {
  private func payload(_ event: String, transcript: URL? = nil) throws -> HookPayload {
    let path = transcript.map { #","transcript_path":"\#($0.path(percentEncoded: false))""# } ?? ""
    return try #require(
      HookPayload.decode(
        Data(#"{"session_id":"q1","hook_event_name":"\#(event)","cwd":"/r/Cumba"\#(path)}"#.utf8)))
  }

  @Test func aStoppedTurnStopsSpinning() throws {
    let center = LiveActivityCenter()
    let service = ClaudeCodeService(liveActivities: center)
    service.handle(try payload("UserPromptSubmit"))
    #expect(center.contains("claude.working"))
    #expect(service.silenceTasks["q1"] != nil)
    service.markStopped("q1")
    #expect(service.sessions.first?.state == .stopped)
    #expect(service.sessions.first?.step == nil)
    #expect(!center.contains("claude.working"))
    #expect(service.silenceTasks["q1"] == nil)
    // The next prompt starts a new turn.
    service.handle(try payload("UserPromptSubmit"))
    #expect(service.sessions.first?.state == .working)
  }

  @Test func onlyAWorkingSessionIsStopped() throws {
    let service = ClaudeCodeService(liveActivities: LiveActivityCenter())
    service.handle(try payload("Stop"))
    service.markStopped("q1")
    #expect(service.sessions.first?.state == .done)
    #expect(service.silenceTasks["q1"] == nil)
  }

  @Test func theWatcherSeesAnInterruptWrittenToTheTranscript() async throws {
    let file = FileManager.default.temporaryDirectory
      .appending(path: "QuietTurn-\(UUID().uuidString).jsonl")
    try Data(#"{"type":"user","message":{"content":"Go"}}"#.utf8).write(to: file)
    defer { try? FileManager.default.removeItem(at: file) }
    let seen = Reports()
    let watcher = try #require(TranscriptWatcher(url: file) { seen.values.append($0) })
    defer { watcher.stop() }
    let handle = try FileHandle(forWritingTo: file)
    try handle.seekToEnd()
    try handle.write(
      contentsOf: Data(
        "\n{\"type\":\"user\",\"message\":{\"content\":\"[Request interrupted by user]\"}}".utf8))
    try handle.close()
    let deadline = Date().addingTimeInterval(5)
    while seen.values.isEmpty, Date() < deadline {
      try await Task.sleep(for: .milliseconds(50))
    }
    #expect(seen.values.last == true)
  }
}

@MainActor
private final class Reports {
  var values: [Bool] = []
}

struct HookSocketTakeoverTests {
  @Test func aLiveSocketIsLeftAloneAndAStaleOneIsNot() throws {
    let path = "/tmp/cumba-\(UUID().uuidString.prefix(8)).sock"
    defer { unlink(path) }
    let fd = socket(AF_UNIX, SOCK_STREAM, 0)
    try #require(fd >= 0)
    let address = sockaddr_un.unix(path: path)
    let bound = withUnsafePointer(to: address) {
      $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
        bind(fd, $0, socklen_t(MemoryLayout<sockaddr_un>.size))
      }
    }
    try #require(bound == 0)
    try #require(listen(fd, 1) == 0)
    #expect(LocalServer.isListening(at: path))
    close(fd)
    // The file stays behind, but nothing answers on it.
    #expect(FileManager.default.fileExists(atPath: path))
    #expect(!LocalServer.isListening(at: path))
  }
}
