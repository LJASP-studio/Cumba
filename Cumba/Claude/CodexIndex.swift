import Foundation

/// Codex keeps the name of each thread in `~/.codex/session_index.jsonl`, one JSON line per
/// rename: `{"id", "thread_name", "updated_at"}`, with the session's ID as `id`. Only the end
/// of the file is read, off the main thread, and nothing is written to it.
enum CodexIndex {
  private static let tailSize = 128 * 1024

  static func fileURL(home: URL = .homeDirectory) -> URL {
    home.appending(path: ".codex/session_index.jsonl")
  }

  /// The latest name Codex gave session `id`.
  static func title(of id: String, in url: URL = fileURL()) -> String? {
    TranscriptReader.tail(of: url, bytes: tailSize).flatMap { title(of: id, inIndex: $0) }
  }

  static func title(of id: String, inIndex text: String) -> String? {
    guard !id.isEmpty else { return nil }
    for line in text.split(separator: "\n").reversed() where line.contains(id) {
      guard let data = line.data(using: .utf8),
        let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
        object["id"] as? String == id,
        let name = object["thread_name"] as? String, !name.isEmpty
      else { continue }
      return name
    }
    return nil
  }
}

extension ClaudeCodeService {
  /// Codex's name for the session, at most every 5 seconds per session.
  func refreshCodexTitle(of id: String) {
    let now = Date()
    if let last = codexReads[id], now.timeIntervalSince(last) < 5 {
      return
    }
    codexReads[id] = now
    Task { [weak self] in
      let name = await Task.detached { CodexIndex.title(of: id) }.value
      self?.setTitle(name.flatMap(AgentText.cleanTitle), source: .generated, of: id)
    }
  }
}
