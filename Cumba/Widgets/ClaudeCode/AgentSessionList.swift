import SwiftUI

/// Every session on a row of its own: a dot for its state, its title, what it's doing and
/// its project. Sessions waiting for you come first; a click opens one.
struct AgentSessionList: View {
  let sessions: [ClaudeCodeService.Session]
  let open: (ClaudeCodeService.Session) -> Void

  var body: some View {
    ScrollView {
      VStack(spacing: 2) {
        // The agent's mark only tells rows apart when both agents are in the list.
        let showsAgent = Set(sessions.map(\.agent)).count > 1
        ForEach(AgentPanelState.listed(sessions)) { session in
          AgentSessionRow(session: session, showsAgent: showsAgent) { open(session) }
        }
      }
    }
    .scrollIndicators(.automatic)
  }
}

private struct AgentSessionRow: View {
  let session: ClaudeCodeService.Session
  let showsAgent: Bool
  let open: () -> Void
  @State private var isHovered = false

  var body: some View {
    Button(action: open) {
      HStack(spacing: 8) {
        Circle()
          .fill(dotColor)
          .frame(width: 7, height: 7)
        VStack(alignment: .leading, spacing: 1) {
          Text(session.displayTitle)
            .panelFont(.callout, weight: .medium)
            .lineLimit(1)
          Text(verbatim: "\(AgentPanel.status(of: session)) · \(session.project)")
            .panelFont(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
        Spacer(minLength: 0)
        if showsAgent {
          AgentGlyph(agent: session.agent, size: 12)
            .opacity(0.8)
        }
      }
      .padding(.horizontal, 8)
      .padding(.vertical, 4)
      .background(
        .white.opacity(isHovered ? 0.08 : 0),
        in: RoundedRectangle(cornerRadius: 8, style: .continuous)
      )
      .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
    .buttonStyle(.plain)
    .onHover { isHovered = $0 }
    .animation(.easeOut(duration: 0.15), value: isHovered)
  }

  private var dotColor: Color {
    switch session.state {
    case .waitingPermission, .waitingInput: .yellow
    case .working: session.agent.color
    case .done: .green
    case .failed: .red
    case .stopped, .ended: .secondary
    }
  }
}
