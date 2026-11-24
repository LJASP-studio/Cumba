import Foundation

extension ClaudeCodeService {
  /// One Claude Code or Codex session as the notch shows it.
  struct Session: Identifiable, Equatable, Sendable {
    enum State: Equatable, Sendable {
      case working
      case waitingPermission
      case waitingInput
      case done
      case failed(String)
      /// The turn ended without a Stop: interrupted, or silent too long.
      case stopped
      case ended
    }

    /// Where a title came from; a better source replaces a worse one, never the reverse.
    enum TitleSource: Int, Comparable, Sendable {
      /// The first line of the first prompt the app saw.
      case prompt
      /// Claude Code's own title, or Codex's thread name.
      case generated
      /// The name the user gave it.
      case custom

      static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
    }

    /// What the text in `detail` is, so the bubble can say it.
    enum DetailKind: Sendable {
      case reply
      case question
    }

    /// Longest answer kept; the bubble shows the start and opens the rest on request.
    static let maxDetailLength = 8000

    let id: String
    /// The project's folder name: where the session started, not where it `cd`'d to.
    var project: String
    var state: State
    /// The last answer or question, as the agent wrote it.
    var detail: String?
    var detailKind = DetailKind.reply
    var updatedAt: Date
    var title: String?
    var titleSource: TitleSource?
    /// The folder inside the project the session is in now, e.g. "docs/api".
    var subfolder: String?
    /// The project's whole path: the folder the transcript is named after or, for agents
    /// without one, the first folder the app saw the session in.
    var root: String?
    /// What it's doing now, e.g. "Editing Notch.swift"; nil when not working.
    var step: String?
    /// How full the context window was at the last answer, 0...1.
    var contextFraction: Double?
    /// The account's usage limits as last reported, e.g. five hours and a week.
    var limits: [UsageLimit] = []
    var agent = Agent.claude
    /// Bundle identifier of the app the session runs in, from its hooks.
    var app: String?

    var isActive: Bool {
      state == .working || state == .waitingPermission
    }

    /// True while the session needs an answer from the user.
    var isWaiting: Bool {
      state == .waitingPermission || state == .waitingInput
    }

    /// The title, or the project when there's none yet.
    var displayTitle: String { title ?? project }

    /// "project › subfolder", or the project alone.
    var place: String {
      subfolder.map { "\(project) › \($0)" } ?? project
    }

    /// Sets the project from the hook's working folder and the transcript's folder.
    mutating func locate(in cwd: String?, transcriptPath: String?) {
      guard let cwd, !cwd.isEmpty else { return }
      let folder = (cwd as NSString).standardizingPath
      if let found = ProjectRoot.root(of: folder, transcriptPath: transcriptPath) {
        root = found
      } else if root == nil {
        root = folder
      }
      let root = root ?? folder
      let name = (root as NSString).lastPathComponent
      project = name.isEmpty || name == "/" ? (folder as NSString).lastPathComponent : name
      subfolder = folder.hasPrefix(root + "/") ? String(folder.dropFirst(root.count + 1)) : nil
    }
  }
}

/// The folder a Claude Code session belongs to. Claude Code names each transcript folder
/// after the folder the session started in, writing every character other than an ASCII
/// letter or digit as "-". The current folder, or the parent of it whose name matches, is
/// the project, however far the session moved with `cd`.
enum ProjectRoot {
  static func encoded(_ path: String) -> String {
    String(
      path.utf16.map { unit -> Character in
        let isAlphanumeric =
          (48...57).contains(unit) || (65...90).contains(unit) || (97...122).contains(unit)
        return isAlphanumeric ? Character(Unicode.Scalar(UInt8(unit))) : "-"
      })
  }

  static func root(of folder: String, transcriptPath: String?) -> String? {
    guard let transcriptPath else { return nil }
    let name = ((transcriptPath as NSString).deletingLastPathComponent as NSString)
      .lastPathComponent
    var path = folder
    while true {
      if encoded(path) == name {
        return path
      }
      let parent = (path as NSString).deletingLastPathComponent
      guard parent != path, !parent.isEmpty else { return nil }
      path = parent
    }
  }
}
