import Foundation

/// Turns what agents and their hooks send into text people can read at a glance: a session
/// title from a prompt, a preview of an answer that ends on a whole sentence, readable tool
/// names and the short form of a shell command. Everything shown goes through `SafeText`.
enum AgentText {
  /// Markup that Claude Code or the app around it adds to a prompt; dropped with its content.
  static let machineBlocks = [
    "system-reminder", "task-notification", "local-command-stdout", "local-command-stderr",
    "local-command-caveat", "command-message", "user-prompt-submit-hook", "bash-stdout",
    "bash-stderr", "tool-use-result", "ide_opened_file", "ide_selection",
  ]

  // MARK: - Titles

  /// The first real line of a prompt, without markup, as a title of at most 60 characters.
  /// Nil when nothing readable is left.
  static func title(fromPrompt prompt: String) -> String? {
    let lines = shortened(plain(stripMarkup(prompt))).split(whereSeparator: \.isNewline)
    guard let line = lines.map({ collapsed(String($0)) }).first(where: isReadable) else {
      return nil
    }
    return clipped(SafeText(line).text, to: 60)
  }

  /// A title the agent or the user gave a session, on one line and safe to show.
  static func cleanTitle(_ title: String) -> String? {
    let line = collapsed(plain(stripMarkup(title)))
    return isReadable(line) ? clipped(SafeText(line).text, to: 60) : nil
  }

  // MARK: - Answers

  struct Preview: Equatable, Sendable {
    let text: String
    /// True when the answer goes on after `text`.
    let isCut: Bool
  }

  /// The start of an answer, cut at the end of a sentence near `limit` characters.
  /// Paragraphs stay apart; inline Markdown stays, so the view can render it.
  static func preview(_ answer: String, limit: Int) -> Preview {
    let paragraphs = paragraphs(of: shortened(blocksFlattened(stripMarkup(answer))))
    let text = paragraphs.map { collapsed($0) }.joined(separator: "\n")
    guard text.count > limit else { return Preview(text: SafeText(text).text, isCut: false) }
    let head = String(text.prefix(limit))
    let cut: String
    if let end = lastSentenceEnd(in: head),
      head.distance(from: head.startIndex, to: end) > limit / 3
    {
      cut = String(head[..<end])
    } else {
      cut = clipped(text, to: limit)
    }
    return Preview(text: SafeText(balanced(cut)).text, isCut: true)
  }

  /// The whole answer, with code fences and heading marks removed and lists kept.
  static func full(_ answer: String) -> String {
    let lines = blocksFlattened(stripMarkup(answer)).components(separatedBy: "\n")
    var kept: [String] = []
    for line in lines.map({ $0.trimmingCharacters(in: .whitespaces) }) {
      if line.isEmpty && (kept.last?.isEmpty ?? true) { continue }
      kept.append(line)
    }
    while kept.last?.isEmpty == true { kept.removeLast() }
    return SafeText(kept.joined(separator: "\n")).text
  }

  /// One line for a notification: the first sentence, joined by the next ones while it's
  /// very short ("Done."), or the start of it.
  static func sentence(_ text: String, limit: Int = 160) -> String {
    let line = plain(collapsed(preview(text, limit: limit).text))
    guard let end = firstSentenceEnd(in: line, minimum: 24) else { return line }
    return String(line[..<end])
  }

  /// Inline Markdown (code, bold, italics) as styled text. Links lose their address and
  /// images aren't loaded, so nothing an agent writes can lead anywhere.
  static func attributed(_ markdown: String) -> AttributedString {
    var options = AttributedString.MarkdownParsingOptions(
      interpretedSyntax: .inlineOnlyPreservingWhitespace)
    options.failurePolicy = .returnPartiallyParsedIfPossible
    var text =
      (try? AttributedString(markdown: markdown, options: options)) ?? AttributedString(markdown)
    for run in text.runs where run.link != nil || run.imageURL != nil {
      text[run.range].link = nil
      text[run.range].imageURL = nil
    }
    return text
  }

  // MARK: - Tools

  /// An MCP tool as "server: tool" with spaces, e.g. "Claude Browser: navigate"; other
  /// tool names stay as they are.
  static func toolName(_ name: String) -> String {
    guard name.hasPrefix("mcp__") else { return name }
    let parts = name.dropFirst(5).components(separatedBy: "__")
    guard parts.count >= 2, let tool = parts.last, !tool.isEmpty else { return name }
    let readableTool = tool.replacingOccurrences(of: "_", with: " ")
    let server = parts.dropLast().joined(separator: " ")
    // Servers named by an ID say nothing; the tool alone does.
    if server.count >= 16, server.allSatisfy({ $0.isHexDigit || $0 == "-" }) {
      return readableTool
    }
    return "\(server.replacingOccurrences(of: "_", with: " ")): \(readableTool)"
  }

  /// Programs whose first argument says what they do, e.g. "git push".
  static let commandsWithSubcommands: Set<String> = [
    "git", "gh", "npm", "npx", "pnpm", "yarn", "bun", "swift", "cargo", "go", "docker",
    "kubectl", "brew", "pip", "pip3", "uv", "make", "xcrun", "xcodebuild", "dotnet", "terraform",
  ]

  /// The program a shell command runs, with its subcommand: "cd app && git push -u origin x"
  /// becomes "git push". Falls back to the start of the command.
  static func command(_ command: String) -> String {
    let skipped: Set<String> = ["cd", "pushd", "popd", "export", "source", "set", "."]
    let prefixes: Set<String> = ["sudo", "env", "time", "nohup", "command", "exec"]
    let segments = command.components(separatedBy: CharacterSet(charactersIn: ";&|\n"))
    for segment in segments {
      var words = segment.split(whereSeparator: \.isWhitespace).map(String.init)
      while let first = words.first, prefixes.contains(first) || isAssignment(first) {
        words.removeFirst()
      }
      guard let first = words.first, !skipped.contains(first) else { continue }
      let program = URL(filePath: first).lastPathComponent
      var summary = program
      if commandsWithSubcommands.contains(program), words.count > 1,
        let next = words.dropFirst().first, next.first?.isLetter == true
      {
        summary += " " + next
      }
      return clipped(SafeText(summary).text, to: 40)
    }
    return clipped(SafeText(collapsed(command)).text, to: 40)
  }

  // MARK: - Cleaning

  /// Removes machine blocks with their content and every other tag whose name has `_` or
  /// `-` (pasted text, slash commands), keeping what's inside.
  static func stripMarkup(_ text: String) -> String {
    var text = text
    for name in machineBlocks {
      let escaped = NSRegularExpression.escapedPattern(for: name)
      text = replacing("<\(escaped)\\b[^>]*>[\\s\\S]*?</\(escaped)>", in: text, with: "")
    }
    // A slash command and its arguments on one line: "/model opus".
    text = replacing(
      "<command-name>([^<]*)</command-name>\\s*<command-args>([^<]*)</command-args>", in: text,
      with: "$1 $2")
    return replacing(
      "</?[A-Za-z][A-Za-z0-9]*[_-][A-Za-z0-9_-]*(\\s[^<>]*)?/?>", in: text, with: " ")
  }

  /// Markdown marks removed: emphasis, code ticks, heading, list and quote marks, and link
  /// targets (the link text stays).
  static func plain(_ text: String) -> String {
    var text = replacing("!?\\[([^\\]]*)\\]\\([^)]*\\)", in: text, with: "$1")
    text = replacing("(?m)^[ \\t]*(#{1,6}|>|[-*+]|\\d+[.)])[ \\t]+", in: text, with: "")
    for mark in ["**", "__", "~~", "`"] {
      text = text.replacingOccurrences(of: mark, with: "")
    }
    return text
  }

  /// Addresses down to their host, file paths down to their last part.
  static func shortened(_ text: String) -> String {
    let text = replacing("https?://([^/\\s)`]+)[^\\s)`]*", in: text, with: "$1")
    return replacing("(?<![\\w.:/-])(?:~|/)(?:[^\\s/:`]+/)+([^\\s/:`]+)", in: text, with: "$1")
  }

  private static func blocksFlattened(_ text: String) -> String {
    var text = replacing("(?m)^[ \\t]*```.*\\n?", in: text, with: "")
    text = replacing("(?m)^[ \\t]*#{1,6}[ \\t]+", in: text, with: "")
    text = replacing("(?m)^[ \\t]*>[ \\t]?", in: text, with: "")
    return replacing("(?m)^[ \\t]*[-*+][ \\t]+", in: text, with: "• ")
  }

  private static func paragraphs(of text: String) -> [String] {
    text.components(separatedBy: "\n\n")
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
      .filter { !$0.isEmpty }
  }

  static func collapsed(_ text: String) -> String {
    text.split(whereSeparator: { $0.isWhitespace || $0.isNewline }).joined(separator: " ")
  }

  /// At most `length` characters, cut after a word when one ends late enough.
  static func clipped(_ text: String, to length: Int) -> String {
    guard text.count > length else { return text }
    let head = String(text.prefix(length - 1))
    if let space = head.lastIndex(where: \.isWhitespace),
      head.distance(from: head.startIndex, to: space) > length / 2
    {
      return String(head[..<space]).trimmingCharacters(in: .punctuationCharacters) + "…"
    }
    return head + "…"
  }

  private static func isReadable(_ text: String) -> Bool {
    text.filter { $0.isLetter || $0.isNumber }.count >= 3
  }

  private static func isAssignment(_ word: String) -> Bool {
    guard let equals = word.firstIndex(of: "="), equals != word.startIndex else { return false }
    return word[..<equals].allSatisfy { $0.isLetter || $0.isNumber || $0 == "_" }
  }

  /// The index just after the first sentence end at least `minimum` characters in.
  private static func firstSentenceEnd(in text: String, minimum: Int) -> String.Index? {
    var index = text.startIndex
    var offset = 0
    while index < text.endIndex {
      let next = text.index(after: index)
      offset += 1
      if offset >= minimum, ".!?…。".contains(text[index]),
        next == text.endIndex || text[next].isWhitespace
      {
        return next
      }
      index = next
    }
    return nil
  }

  /// The index just after the last sentence end (". ", "! ", "? " or before a line break).
  private static func lastSentenceEnd(in text: String) -> String.Index? {
    var index = text.endIndex
    while index > text.startIndex {
      let previous = text.index(before: index)
      if ".!?…。".contains(text[previous]),
        index == text.endIndex || text[index].isWhitespace
      {
        return index
      }
      index = previous
    }
    return nil
  }

  /// Drops a code tick or bold mark left open by a cut.
  private static func balanced(_ text: String) -> String {
    var text = text
    if text.filter({ $0 == "`" }).count % 2 == 1, let last = text.lastIndex(of: "`") {
      text.remove(at: last)
    }
    if text.components(separatedBy: "**").count % 2 == 0,
      let range = text.range(of: "**", options: .backwards)
    {
      text.removeSubrange(range)
    }
    return text
  }

  private static func replacing(_ pattern: String, in text: String, with template: String)
    -> String
  {
    guard let regex = try? NSRegularExpression(pattern: pattern) else { return text }
    let range = NSRange(text.startIndex..., in: text)
    return regex.stringByReplacingMatches(in: text, range: range, withTemplate: template)
  }
}
