import Foundation

/// A permission request in words: a headline for what it asks ("Wants to edit Notch.swift")
/// and the agent's own description of a command. The request itself is still shown in full
/// under them (`permissionDetail`).
extension HookPayload {
  var permissionHeadline: SafeText {
    let tool = toolName ?? "?"
    let file =
      (toolInput?["file_path"]?.string ?? toolInput?["notebook_path"]?.string)
      .map { URL(filePath: $0).lastPathComponent } ?? ""
    if NotchApprovals.shellTools.contains(tool) {
      return SafeText(
        String(localized: "Wants to run a command", comment: "Permission request headline"))
    }
    let text =
      switch tool {
      case "Edit", "MultiEdit", "NotebookEdit":
        String(
          localized: "Wants to edit \(file)", comment: "Permission request headline; a file name")
      case "Write":
        String(
          localized: "Wants to write \(file)", comment: "Permission request headline; a file name")
      case "Read":
        String(
          localized: "Wants to read \(file)", comment: "Permission request headline; a file name")
      case "WebFetch":
        String(
          localized: "Wants to open \(Self.host(of: toolInput?["url"]?.string))",
          comment: "Permission request headline; a web address")
      case "WebSearch":
        String(localized: "Wants to search the web", comment: "Permission request headline")
      default:
        String(
          localized: "Wants to use \(AgentText.toolName(tool))",
          comment: "Permission request headline; a tool name")
      }
    return SafeText(text)
  }

  /// What the agent said the command does (Claude Code's Bash `description`). It's the
  /// agent's claim, so the command itself always shows below it.
  var permissionNote: SafeText? {
    guard let description = toolInput?["description"]?.string else { return nil }
    let line = AgentText.collapsed(description)
    return line.isEmpty ? nil : SafeText(AgentText.clipped(line, to: 140))
  }

  private static func host(of address: String?) -> String {
    guard let address else { return "" }
    return URL(string: address)?.host() ?? address
  }
}
