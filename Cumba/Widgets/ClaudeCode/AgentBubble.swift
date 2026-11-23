import SwiftUI

/// The agent's last answer or question under a small label. Its start is cut at the end of a
/// sentence; a click opens all of it and a second click closes it again. Inline Markdown is
/// drawn, and links lead nowhere.
struct AgentBubble: View {
  let session: ClaudeCodeService.Session
  let detail: String
  let state: AgentPanelState
  @Environment(\.showsDetailedWidget) private var isDetailed
  /// Heights of the preview as shown and as it would be without a line limit.
  @State private var heights = (shown: CGFloat.zero, whole: CGFloat.zero)

  var body: some View {
    let preview = AgentText.preview(
      detail, limit: AgentLayout.previewLimit(isDetailed: isDetailed))
    let isExpanded = state.isExpanded(session)
    // Cut at a sentence, or by the line limit when the lines run short.
    let isCut = preview.isCut || heights.whole > heights.shown + 1
    let canOpen = isCut || isExpanded
    VStack(alignment: .leading, spacing: 3) {
      label
        .panelFont(.caption2, weight: .semibold)
        .foregroundStyle(.secondary)
        .textCase(.uppercase)
      if isExpanded {
        let full = Text(AgentText.attributed(AgentText.full(detail)))
        // The whole answer when the tab has room for it, else in a box that scrolls.
        ViewThatFits(in: .vertical) {
          full
            .panelFont(.callout)
            .fixedSize(horizontal: false, vertical: true)
          ScrollView {
            full
              .panelFont(.callout)
              .frame(maxWidth: .infinity, alignment: .leading)
          }
          .scrollIndicators(.visible)
        }
      } else {
        let text = Text(AgentText.attributed(preview.text))
        text
          .panelFont(.callout)
          .lineLimit(AgentLayout.lineLimit(isDetailed: isDetailed))
          .onGeometryChange(for: CGFloat.self, of: \.size.height) { heights.shown = $0 }
          .background(alignment: .topLeading) {
            text
              .panelFont(.callout)
              .fixedSize(horizontal: false, vertical: true)
              .hidden()
              .onGeometryChange(for: CGFloat.self, of: \.size.height) { heights.whole = $0 }
          }
      }
      if isCut && !isExpanded {
        Text("More…", comment: "Opens the rest of an AI agent's answer")
          .panelFont(.caption, weight: .medium)
          .foregroundStyle(session.agent.color)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.horizontal, 10)
    .padding(.vertical, 6)
    .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(.white.opacity(0.1))
    )
    .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    .onTapGesture {
      guard canOpen else { return }
      withAnimation(.easeOut(duration: 0.2)) { state.toggleExpanded(session) }
    }
    .pointerStyle(canOpen ? .link : nil)
    .accessibilityElement(children: .combine)
    .accessibilityAddTraits(canOpen ? .isButton : [])
    .accessibilityAction {
      guard canOpen else { return }
      state.toggleExpanded(session)
    }
  }

  private var label: Text {
    switch session.detailKind {
    case .reply: Text("Last reply", comment: "Label over an AI agent's last answer")
    case .question: Text("Question", comment: "Label over a question an AI agent asks you")
    }
  }
}
