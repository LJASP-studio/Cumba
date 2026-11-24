import Foundation

/// How much of an agent's usage limit is used: Codex's 5-hour and weekly windows, or
/// Claude Code's from its status line (`StatusLineBridge`).
struct UsageLimit: Equatable, Sendable {
  /// 0...1.
  var usedFraction: Double
  /// The window's length, e.g. 300 for five hours; nil when not known.
  var windowMinutes: Int?
  var resetsAt: Date?
}

/// Codex writes each session to `~/.codex/sessions/YYYY/MM/DD/rollout-…-<id>.jsonl`. After
/// every answer it adds a `token_count` event with the context's size and the account's
/// limits. Only the end of the file is read, off the main thread, and nothing is written.
enum CodexRollout {
  struct Summary: Equatable, Sendable {
    var contextFraction: Double?
    var limits: [UsageLimit] = []
  }

  private static let tailSize = 256 * 1024

  static func root(home: URL = .homeDirectory) -> URL {
    home.appending(path: ".codex/sessions").standardizedFileURL.resolvingSymlinksInPath()
  }

  /// The session's file: the hook's `transcript_path` when it's under ~/.codex/sessions,
  /// otherwise a file named after the session in the last three days' folders.
  static func url(
    for id: String, path: String?, home: URL = .homeDirectory, now: Date = .now
  ) -> URL? {
    let root = root(home: home)
    let rootPath = root.path(percentEncoded: false) + "/"
    if let path, path.hasSuffix(".jsonl") {
      let file = URL(filePath: path).standardizedFileURL.resolvingSymlinksInPath()
      if file.path(percentEncoded: false).hasPrefix(rootPath) { return file }
    }
    guard id.count >= 8, id.allSatisfy({ $0.isASCII && ($0.isHexDigit || $0 == "-") }) else {
      return nil
    }
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = .current
    for days in 0..<3 {
      guard let day = calendar.date(byAdding: .day, value: -days, to: now) else { continue }
      let parts = calendar.dateComponents([.year, .month, .day], from: day)
      guard let year = parts.year, let month = parts.month, let date = parts.day else { continue }
      let folder = root.appending(
        path: String(format: "%04d/%02d/%02d", year, month, date), directoryHint: .isDirectory)
      let names = (try? FileManager.default.contentsOfDirectory(atPath: folder.path())) ?? []
      if let name = names.first(where: { $0.hasSuffix("\(id).jsonl") }) {
        return folder.appending(path: name)
      }
    }
    return nil
  }

  static func read(_ url: URL) -> Summary? {
    TranscriptReader.tail(of: url, bytes: tailSize).map(parse)
  }

  /// The last `token_count` event: context as the last turn's tokens over the window, and
  /// each limit window Codex reported.
  static func parse(_ text: String) -> Summary {
    var summary = Summary()
    for line in text.split(separator: "\n").reversed() where line.contains("token_count") {
      guard let data = line.data(using: .utf8),
        let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
        let payload = object["payload"] as? [String: Any],
        payload["type"] as? String == "token_count"
      else { continue }
      if let info = payload["info"] as? [String: Any],
        let window = number(info["model_context_window"]), window > 0,
        let last = info["last_token_usage"] as? [String: Any],
        let tokens = number(last["total_tokens"]) ?? number(last["input_tokens"])
      {
        summary.contextFraction = min(1, max(0, tokens / window))
      }
      if let limits = payload["rate_limits"] as? [String: Any] {
        let timestamp = (object["timestamp"] as? String).flatMap(Self.date)
        summary.limits = ["primary", "secondary"].compactMap { key in
          (limits[key] as? [String: Any]).flatMap { limit(from: $0, at: timestamp) }
        }
      }
      return summary
    }
    return summary
  }

  private static func limit(from object: [String: Any], at timestamp: Date?) -> UsageLimit? {
    guard let percent = number(object["used_percent"]) else { return nil }
    let resetsAt: Date? =
      if let at = number(object["resets_at"]) {
        Date(timeIntervalSince1970: at)
      } else if let seconds = number(object["resets_in_seconds"]), let timestamp {
        timestamp.addingTimeInterval(seconds)
      } else {
        nil
      }
    return UsageLimit(
      usedFraction: min(1, max(0, percent / 100)),
      windowMinutes: number(object["window_minutes"]).map { Int($0) }, resetsAt: resetsAt)
  }

  private static func number(_ value: Any?) -> Double? {
    (value as? NSNumber).map(\.doubleValue)
  }

  private static func date(_ text: String) -> Date? {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter.date(from: text) ?? ISO8601DateFormatter().date(from: text)
  }
}
