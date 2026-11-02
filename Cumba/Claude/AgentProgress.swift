import Foundation

/// The coding agents whose sessions the notch shows. Both report through command hooks
/// that post to the app's private socket, each on its own route.
enum Agent: String, Sendable {
  case claude
  case codex

  var name: String {
    switch self {
    case .claude: "Claude"
    case .codex: "Codex"
    }
  }

  var hookRoute: String {
    switch self {
    case .claude: "/claude/hook"
    case .codex: "/codex/hook"
    }
  }
}

/// What an agent is doing right now, in a few words, from the tool it's about to use.
enum AgentStep {
  static var thinking: String {
    String(localized: "Thinking…", comment: "An AI agent is working on its answer")
  }

  static func describe(toolName: String?, input: [String: JSONValue]?, cwd: String?) -> String {
    let file = (input?["file_path"]?.string ?? input?["notebook_path"]?.string)
      .map { URL(filePath: $0).lastPathComponent }
    switch toolName {
    case "Bash":
      let command = input?["description"]?.string ?? input?["command"]?.string ?? ""
      return String(
        localized: "Running \(HookPayload.truncate(command, to: 48))",
        comment: "An AI agent runs a shell command")
    case "Edit", "MultiEdit", "Write", "NotebookEdit":
      return String(localized: "Editing \(file ?? "")", comment: "An AI agent edits a file")
    case "Read":
      return String(localized: "Reading \(file ?? "")", comment: "An AI agent reads a file")
    case "Glob", "Grep":
      return String(localized: "Searching the code", comment: "An AI agent searches files")
    case "WebFetch", "WebSearch":
      return String(localized: "Searching the web", comment: "An AI agent uses the web")
    case "Task", "Agent":
      return String(localized: "Running a subagent", comment: "An AI agent starts a helper")
    case "TodoWrite":
      return String(localized: "Planning", comment: "An AI agent updates its plan")
    case let tool?:
      return String(localized: "Using \(tool)", comment: "An AI agent uses a tool")
    case nil:
      return thinking
    }
  }
}

/// Reads what the notch needs from a Claude Code transcript: how full the context window was
/// at the last answer, the session's summary title, and whether the last turn was
/// interrupted. It reads only the end of the file, only files under ~/.claude/projects, and
/// never on the main thread.
enum TranscriptReader {
  struct Summary: Equatable, Sendable {
    /// Tokens in the context at the last answer.
    var contextTokens: Int?
    var contextLimit = 200_000
    var title: String?

    var contextFraction: Double? {
      contextTokens.map { min(1, Double($0) / Double(contextLimit)) }
    }
  }

  private static let tailSize = 256 * 1024

  /// The file, if the path is a transcript inside ~/.claude/projects.
  static func allowedURL(_ path: String?, home: URL = .homeDirectory) -> URL? {
    guard let path, path.hasSuffix(".jsonl") else { return nil }
    let root = home.appending(path: ".claude/projects").standardizedFileURL
      .resolvingSymlinksInPath()
    let file = URL(filePath: path).standardizedFileURL.resolvingSymlinksInPath()
    return file.path(percentEncoded: false).hasPrefix(root.path(percentEncoded: false) + "/")
      ? file : nil
  }

  static func read(_ url: URL) -> Summary? {
    tail(of: url, bytes: tailSize).map(parse)
  }

  /// True when the transcript ends with Claude Code's line for a turn you interrupted, which
  /// comes without a Stop hook. Reads only the last 64 KB.
  static func endsInInterrupt(_ url: URL) -> Bool {
    tail(of: url, bytes: 64 * 1024).map(endsInInterrupt) ?? false
  }

  /// The last message, yours or the agent's, is the interrupt line.
  static func endsInInterrupt(_ text: String) -> Bool {
    for line in text.split(separator: "\n").reversed() {
      guard let data = line.data(using: .utf8),
        let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
        let type = object["type"] as? String, type == "user" || type == "assistant",
        object["isMeta"] as? Bool != true
      else { continue }
      guard type == "user", let message = object["message"] as? [String: Any] else {
        return false
      }
      let texts =
        (message["content"] as? String).map { [$0] }
        ?? (message["content"] as? [[String: Any]] ?? []).compactMap { $0["text"] as? String }
      return texts.contains { $0.hasPrefix("[Request interrupted by user") }
    }
    return false
  }

  private static func tail(of url: URL, bytes: Int) -> String? {
    guard let handle = try? FileHandle(forReadingFrom: url) else { return nil }
    defer { try? handle.close() }
    let size = (try? handle.seekToEnd()) ?? 0
    try? handle.seek(toOffset: size > UInt64(bytes) ? size - UInt64(bytes) : 0)
    guard let data = try? handle.readToEnd() else { return nil }
    return String(decoding: data, as: UTF8.self)
  }

  static func parse(_ text: String) -> Summary {
    var summary = Summary()
    for line in text.split(separator: "\n").reversed() {
      guard let data = line.data(using: .utf8),
        let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
      else { continue }
      if summary.title == nil, object["type"] as? String == "summary",
        let title = object["summary"] as? String
      {
        summary.title = title
      }
      if summary.contextTokens == nil, object["type"] as? String == "assistant",
        let usage = (object["message"] as? [String: Any])?["usage"] as? [String: Any]
      {
        let keys = ["input_tokens", "cache_creation_input_tokens", "cache_read_input_tokens"]
        let tokens = keys.compactMap { usage[$0] as? Int }.reduce(0, +)
        if tokens > 0 {
          summary.contextTokens = tokens
        }
      }
      if summary.contextTokens != nil && summary.title != nil {
        break
      }
    }
    // Sessions with the 1M context window go past the usual 200K.
    if let tokens = summary.contextTokens, tokens > 200_000 {
      summary.contextLimit = 1_000_000
    }
    return summary
  }
}
