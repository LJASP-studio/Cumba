import AppKit
import Observation

/// What the AI Agents widget shows: which session, which page, and whether the list or a
/// whole answer is open. The widget keeps it, so the tab's height can follow it.
@MainActor
@Observable
final class AgentPanelState {
  enum Page {
    case progress
    case usage
  }

  /// An answer opened in full. Keyed by its text too, so the next answer starts closed.
  struct Expanded: Equatable {
    let sessionID: String
    let detail: String
  }

  var page = Page.progress
  /// A session picked from the list or with "+N"; nil follows the busiest one.
  var pickedSessionID: String?
  /// False while a session picked from the list is open.
  var showsList = true
  var expanded: Expanded?

  func session(in service: ClaudeCodeService) -> ClaudeCodeService.Session? {
    service.sessions.first { $0.id == pickedSessionID }
      ?? service.sessions.first(where: \.isActive) ?? service.sessions.first
  }

  /// True when the list of sessions stands where one session's progress would be.
  func isListShown(in service: ClaudeCodeService) -> Bool {
    service.showsSessionList && service.sessions.count > 1 && showsList && page == .progress
  }

  func isExpanded(_ session: ClaudeCodeService.Session) -> Bool {
    expanded == Expanded(sessionID: session.id, detail: session.detail ?? "")
  }

  func toggleExpanded(_ session: ClaudeCodeService.Session) {
    expanded =
      isExpanded(session) ? nil : Expanded(sessionID: session.id, detail: session.detail ?? "")
  }

  /// Sessions waiting for the user first, then working ones, then the rest; newest first.
  static func listed(_ sessions: [ClaudeCodeService.Session]) -> [ClaudeCodeService.Session] {
    func rank(_ session: ClaudeCodeService.Session) -> Int {
      session.isWaiting ? 0 : session.isActive ? 1 : 2
    }
    return sessions.sorted { lhs, rhs in
      rank(lhs) == rank(rhs) ? lhs.updatedAt > rhs.updatedAt : rank(lhs) < rank(rhs)
    }
  }
}

/// Sizes the agent views and the widget's height share, so the tab grows by what it shows.
enum AgentLayout {
  /// Widest the answer bubble gets beside the status in a tab of its own.
  static let bubbleWidth: CGFloat = 260
  /// Rows the list shows before it scrolls.
  static let visibleRows = 5

  /// About how many characters fill the bubble's lines.
  static func previewLimit(isDetailed: Bool) -> Int { isDetailed ? 280 : 120 }
  static func lineLimit(isDetailed: Bool) -> Int { isDetailed ? 6 : 4 }

  static func lineHeight(_ style: NSFont.TextStyle, textScale: CGFloat) -> CGFloat {
    let size = (NSFont.preferredFont(forTextStyle: style).pointSize * textScale).rounded()
    return ceil(NSLayoutManager().defaultLineHeight(for: NSFont.systemFont(ofSize: size)))
  }

  /// A list row: the title over the status, with its padding.
  static func rowHeight(textScale: CGFloat) -> CGFloat {
    lineHeight(.callout, textScale: textScale) + lineHeight(.caption1, textScale: textScale) + 9
  }

  static func textHeight(
    _ text: String, style: NSFont.TextStyle, weight: NSFont.Weight = .regular, width: CGFloat,
    textScale: CGFloat
  ) -> CGFloat {
    let size = (NSFont.preferredFont(forTextStyle: style).pointSize * textScale).rounded()
    let bounds = (text as NSString).boundingRect(
      with: CGSize(width: max(width, 40), height: .greatestFiniteMagnitude),
      options: [.usesLineFragmentOrigin, .usesFontLeading],
      attributes: [.font: NSFont.systemFont(ofSize: size, weight: weight)])
    return ceil(bounds.height)
  }

  /// The compact card for any request: a question's card, or the permission card.
  static func requestHeight(
    _ request: PermissionBroker.Request, width: CGFloat, textScale: CGFloat
  ) -> CGFloat {
    guard case .questions(let questions) = request.kind else {
      return permissionHeight(request, width: width, textScale: textScale)
    }
    let inner = width - 20
    let question = questions[0]
    var height = 20 + lineHeight(.caption2, textScale: textScale)
    height +=
      4
      + min(
        textHeight(
          question.shownQuestion, style: .caption1, weight: .semibold, width: inner - 22,
          textScale: textScale),
        3 * lineHeight(.caption1, textScale: textScale))
    // The options' box at its largest, then the buttons.
    height += 4 + 66
    height += 4 + 22 * textScale
    return height
  }

  /// The compact permission card in the widget: who asks, what, the agent's note, the
  /// request's box, one line for a hint and the buttons, which take two rows when narrow.
  static func permissionHeight(
    _ request: PermissionBroker.Request, width: CGFloat, textScale: CGFloat
  ) -> CGFloat {
    let inner = width - 20
    func lines(_ text: String, _ style: NSFont.TextStyle, _ weight: NSFont.Weight, _ max: Int)
      -> CGFloat
    {
      min(
        textHeight(text, style: style, weight: weight, width: inner - 22, textScale: textScale),
        CGFloat(max) * lineHeight(style, textScale: textScale))
    }
    let headline = request.headline.isEmpty ? request.toolName : request.headline
    var height = 20 + lineHeight(.caption2, textScale: textScale)
    height += 4 + lines(headline, .caption1, .semibold, 3)
    if let note = request.note {
      height += 4 + lines(note, .caption1, .regular, 2)
    }
    height += 4 + 44 + 12
    height += 4 + 2 * lineHeight(.caption2, textScale: textScale)
    let button = 22 * textScale
    height += 4 + (inner < 260 ? 2 * button + 4 : button)
    return height
  }

  /// The bubble for `detail` at `width` (inside its padding), as `AgentBubble` draws it.
  static func bubbleHeight(
    detail: String, isExpanded: Bool, width: CGFloat, textScale: CGFloat, isDetailed: Bool
  ) -> CGFloat {
    let preview = AgentText.preview(detail, limit: previewLimit(isDetailed: isDetailed))
    let shown = isExpanded ? AgentText.full(detail) : preview.text
    var height = textHeight(
      String(AgentText.attributed(shown).characters), style: .callout, width: width,
      textScale: textScale)
    var isCut = preview.isCut
    if !isExpanded {
      let lines = CGFloat(lineLimit(isDetailed: isDetailed))
      let limit = lines * lineHeight(.callout, textScale: textScale)
      isCut = isCut || height > limit + 1
      height = min(height, limit)
    }
    let label = lineHeight(.caption2, textScale: textScale) + 3
    let more = isCut && !isExpanded ? lineHeight(.caption1, textScale: textScale) + 3 : 0
    return 12 + label + height + more
  }
}
