import Foundation
import Testing

@testable import Cumba

struct CodexRolloutTests {
  private func fixture() throws -> String {
    let url = URL(filePath: #filePath).deletingLastPathComponent()
      .appending(path: "Fixtures/codex/rollout-tail.jsonl")
    return try String(contentsOf: url, encoding: .utf8)
  }

  @Test func readsTheLastTokenCount() throws {
    let summary = CodexRollout.parse(try fixture())
    let context = try #require(summary.contextFraction)
    #expect(abs(context - 68_000.0 / 272_000.0) < 0.0001)
    #expect(summary.limits.count == 2)
    #expect(summary.limits[0].usedFraction == 0.34)
    #expect(summary.limits[0].windowMinutes == 300)
    // Seconds until reset count from the event's time.
    let reset = try #require(summary.limits[0].resetsAt)
    #expect(reset == ISO8601DateFormatter().date(from: "2026-11-25T10:35:01Z"))
    #expect(summary.limits[1].resetsAt == Date(timeIntervalSince1970: 1_764_633_600))
  }

  @Test func ignoresFilesWithoutTokenCounts() {
    #expect(CodexRollout.parse("{\"type\":\"session_meta\"}\nnot json") == CodexRollout.Summary())
  }

  @Test func findsTheSessionFileOnlyUnderCodexSessions() throws {
    let home = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: home) }
    let id = "0199a1b2-c3d4-7e5f-8a9b-0c1d2e3f4a5b"
    let now = try #require(ISO8601DateFormatter().date(from: "2026-11-25T12:00:00Z"))
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = .current
    let day = calendar.dateComponents([.year, .month, .day], from: now)
    let folder = home.appending(
      path: String(
        format: ".codex/sessions/%04d/%02d/%02d", day.year ?? 0, day.month ?? 0, day.day ?? 0))
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    let file = folder.appending(path: "rollout-2026-11-25T11-00-00-\(id).jsonl")
    try Data().write(to: file)
    let found = CodexRollout.url(for: id, path: nil, home: home, now: now)
    #expect(found?.lastPathComponent == file.lastPathComponent)
    // A path outside ~/.codex/sessions isn't read, and odd IDs aren't searched for.
    #expect(CodexRollout.url(for: "../x", path: "/etc/passwd.jsonl", home: home, now: now) == nil)
  }

  @Test func limitWindowsHaveShortNames() {
    #expect(AgentLimitText.window(300) == String(localized: "\(5) h"))
    #expect(AgentLimitText.window(10080) == String(localized: "Week"))
    #expect(AgentLimitText.window(nil) == String(localized: "Limit"))
  }
}
