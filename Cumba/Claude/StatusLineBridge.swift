import Foundation

/// Claude Code gives the exact context use and the account's usage limits only to its status
/// line. The bridge, which the user turns on in Settings, puts a small command in
/// `statusLine` of ~/.claude/settings.json: it posts that input to the app's socket and then
/// runs the user's own status line command, if there was one, with the same input, so the
/// status line looks as before. Removing it puts the old command back.
///
/// Only terminal sessions have a status line, and the limits appear only for Claude
/// subscriptions. Like the hooks, the command fails quietly while the app is closed.
extension HookInstaller {
  static let statusRoute = "/claude/status"
  /// The script's `$0`, which also marks the command as ours.
  static let statusLineMarker = "cumba-status"

  /// The status line command, with the socket, the token header and the user's previous
  /// command as arguments, so none of them needs quoting inside the script.
  static func statusLineCommand(socketPath: String, token: String, previous: String?) -> String {
    let script = [
      "i=$(cat);",
      "printf %s \"$i\" | /usr/bin/curl -sf --max-time 1 --unix-socket \"$1\" -H \"$2\"",
      "-H \"Content-Type: application/json\" --data-binary @-",
      "http://localhost\(statusRoute) >/dev/null 2>&1 &",
      "if [ -n \"$3\" ]; then printf %s \"$i\" | /bin/sh -c \"$3\"; fi; wait",
    ].joined(separator: " ")
    return [
      "/bin/sh -c", shellQuoted(script), statusLineMarker, shellQuoted(socketPath),
      shellQuoted("\(RequestGuard.tokenHeader): \(token)"), shellQuoted(previous ?? ""),
    ].joined(separator: " ")
  }

  /// The user's own command inside ours, or nil when `command` isn't ours.
  static func previousStatusLine(in command: String) -> String?? {
    let words = shellWords(command)
    guard words.count == 7, words[0] == "/bin/sh", words[1] == "-c",
      words[2].contains(statusRoute), words[3] == statusLineMarker
    else { return nil }
    return .some(words[6].isEmpty ? nil : words[6])
  }

  static func statusLineStatus(
    of settings: [String: Any], socketPath: String, token: String
  ) -> Status {
    guard let line = settings["statusLine"] as? [String: Any],
      let command = line["command"] as? String,
      let previous = previousStatusLine(in: command)
    else { return .notInstalled }
    let expected = statusLineCommand(socketPath: socketPath, token: token, previous: previous)
    return command == expected ? .installed : .outdated
  }

  /// Wraps the existing status line command, keeping its other keys (e.g. `padding`).
  static func installingStatusLine(
    socketPath: String, token: String, into settings: [String: Any]
  ) -> [String: Any] {
    var line = settings["statusLine"] as? [String: Any] ?? [:]
    let current = line["command"] as? String
    let previous: String? =
      if let current, let inner = previousStatusLine(in: current) {
        inner
      } else if line["type"] as? String == "command" {
        current
      } else {
        nil
      }
    line["type"] = "command"
    line["command"] = statusLineCommand(socketPath: socketPath, token: token, previous: previous)
    var result = settings
    result["statusLine"] = line
    return result
  }

  /// Puts the user's own command back, or removes the status line when there was none.
  static func removingStatusLine(from settings: [String: Any]) -> [String: Any] {
    guard var line = settings["statusLine"] as? [String: Any],
      let command = line["command"] as? String,
      let previous = previousStatusLine(in: command)
    else { return settings }
    var result = settings
    if let previous {
      line["command"] = previous
      result["statusLine"] = line
    } else {
      result["statusLine"] = nil
    }
    return result
  }

  func statusLineStatus(token: String) throws(Failure) -> Status {
    Self.statusLineStatus(of: try readSettings(), socketPath: socketPath, token: token)
  }

  func planStatusLine(install: Bool, token: String) throws(Failure) -> Plan {
    let (text, settings) = try readFile()
    let new =
      install
      ? Self.installingStatusLine(socketPath: socketPath, token: token, into: settings)
      : Self.removingStatusLine(from: settings)
    return Self.plan(file: text, from: settings, to: new)
  }

  /// Splits a command line as /bin/sh would for plain words, '…', "…" and backslashes.
  static func shellWords(_ text: String) -> [String] {
    var words: [String] = []
    var word = ""
    var inWord = false
    var quote: Character?
    var escaped = false
    for character in text {
      if escaped {
        word.append(character)
        escaped = false
      } else if let open = quote {
        if character == open {
          quote = nil
        } else if open == "\"" && character == "\\" {
          escaped = true
        } else {
          word.append(character)
        }
      } else if character == "'" || character == "\"" {
        quote = character
        inWord = true
      } else if character == "\\" {
        escaped = true
        inWord = true
      } else if character.isWhitespace {
        if inWord { words.append(word) }
        word = ""
        inWord = false
      } else {
        word.append(character)
        inWord = true
      }
    }
    if inWord { words.append(word) }
    return words
  }
}
