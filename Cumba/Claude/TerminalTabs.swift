import Foundation

/// Brings the exact Terminal or iTerm2 tab of an agent session to the front. The hook sends
/// the tty of the agent's process; the tab with that tty is selected by AppleScript. Only
/// apps that are already running and that the user allowed in Settings > Permissions are
/// scripted, so no app is launched and no Automation prompt appears behind the panel.
enum TerminalTabs {
  static let terminal = "com.apple.Terminal"
  static let iTerm = "com.googlecode.iterm2"
  static let supported = [terminal, iTerm]

  /// "/dev/ttys003" for a header value like "ttys003"; nil for anything else (e.g. "??").
  static func device(_ value: String?) -> String? {
    guard let value = value?.trimmingCharacters(in: .whitespaces),
      value.range(of: #"^ttys[0-9]{1,4}$"#, options: .regularExpression) != nil
    else { return nil }
    return "/dev/\(value)"
  }

  /// The script that selects the tab with `tty`; returns true when one was found.
  static func script(for bundleID: String, tty: String) -> String? {
    // `tty` passed `device(_:)`, so it has no quotes or backslashes.
    switch bundleID {
    case terminal:
      return """
        tell application id "\(terminal)"
          repeat with w in windows
            repeat with t in tabs of w
              if tty of t is "\(tty)" then
                set selected of t to true
                set index of w to 1
                return true
              end if
            end repeat
          end repeat
        end tell
        return false
        """
    case iTerm:
      return """
        tell application id "\(iTerm)"
          repeat with w in windows
            repeat with t in tabs of w
              repeat with s in sessions of t
                if tty of s is "\(tty)" then
                  select w
                  tell t to select
                  tell s to select
                  return true
                end if
              end repeat
            end repeat
          end repeat
        end tell
        return false
        """
    default:
      return nil
    }
  }

  /// Selects the tab; false when it isn't allowed, not running or not found.
  static func select(tty: String, in bundleID: String) async -> Bool {
    guard device(String(tty.dropFirst("/dev/".count))) == tty,
      let source = script(for: bundleID, tty: tty)
    else { return false }
    do {
      return try await AppleScriptRunner.shared.run(source, in: bundleID) { $0.booleanValue }
    } catch {
      Log.claude.debug("Couldn't select the terminal tab: \(String(describing: error))")
      return false
    }
  }
}
