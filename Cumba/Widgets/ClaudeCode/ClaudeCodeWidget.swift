import Observation
import SwiftUI

/// Claude Code and Codex sessions and pending permission requests. The kind keeps its
/// first name so saved layouts still find it.
@MainActor
@Observable
final class ClaudeCodeWidget: NotchWidget {
  static let kind = "claude-code"
  static var title: String { String(localized: "AI Agents", comment: "Widget name") }
  static let symbol = "terminal"
  static let size = WidgetSize.regular
  static var summary: String {
    String(
      localized: "What Claude Code and Codex are doing, and their permission requests",
      comment: "Widget description")
  }

  let service: ClaudeCodeService
  /// Which session and page the widget shows; kept here so the height can follow it.
  let panel = AgentPanelState()
  private let openSettings: @MainActor (SettingsPage) -> Void

  required init(context: WidgetContext) {
    service = context.claude
    openSettings = context.openSettings
  }

  func makeView() -> AnyView {
    AnyView(
      ClaudeCodeWidgetView(service: service, panel: panel) { [openSettings] in
        openSettings(.agents)
      })
  }

  /// Tall enough for what the panel shows: the list of sessions, or one session with its
  /// answer in the bubble, so a long answer makes the tab taller instead of being cut off.
  func preferredContentHeight(width: CGFloat, textScale: CGFloat, isDetailed: Bool) -> CGFloat? {
    if let request = service.permissions.pending.first {
      return AgentLayout.permissionHeight(request, width: width, textScale: textScale)
    }
    // The card's padding, the page row and the gap under it.
    let frame: CGFloat = 20 + 24 + 8
    if panel.isListShown(in: service) {
      let rows = CGFloat(min(service.sessions.count, AgentLayout.visibleRows))
      return frame + rows * AgentLayout.rowHeight(textScale: textScale) + (rows - 1) * 2
    }
    guard let session = panel.session(in: service), let detail = session.detail,
      !detail.isEmpty
    else { return nil }
    // Name, status and project.
    let column = 62 * textScale
    let bubbleWidth = (isDetailed ? min(AgentLayout.bubbleWidth, width * 0.5) : width - 20) - 20
    let bubble = AgentLayout.bubbleHeight(
      detail: detail, isExpanded: panel.isExpanded(session), width: bubbleWidth,
      textScale: textScale, isDetailed: isDetailed)
    return frame + (isDetailed ? max(column, bubble) : column + 6 + bubble)
  }
}

private struct ClaudeCodeWidgetView: View {
  let service: ClaudeCodeService
  let panel: AgentPanelState
  let setUp: () -> Void

  var body: some View {
    WidgetCard {
      if let request = service.permissions.pending.first {
        PermissionCard(
          request: request, waiting: service.permissions.pending.count - 1, compact: true
        ) { decision in
          service.answer(request, with: decision)
        }
        .id(request.id)
      } else {
        VStack(alignment: .leading, spacing: 6) {
          if service.sessions.isEmpty {
            WidgetHeader("AI Agents", symbol: "sparkle", color: .purple)
            Text(
              "No sessions yet. Claude Code and Codex show up here once their hooks are installed."
            )
            .panelFont(.caption)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
            Button("Set Up…", action: setUp)
              .controlSize(.small)
          } else {
            AgentPanel(service: service, state: panel)
          }
        }
      }
    }
  }
}

/// A permission request with Allow, Deny and "answer in the terminal". Used in the widget
/// and as a banner in the panel when the widget isn't in the visible tab. It says which
/// session asks, what it wants in plain words and, when the agent gave one, its own note on
/// why; the full request always stays under them, since a note can mislead.
///
/// Safety: the full request is shown, escaped (`SafeText`). Buttons stay disabled for a
/// moment whenever a new request appears, so a click aimed at something else or a double
/// click can't approve it unseen. When the request is longer than its box, Allow waits until
/// the end has been scrolled into view. Suspicious requests, and tools Settings exclude, get
/// no Allow button at all.
struct PermissionCard: View {
  let request: PermissionBroker.Request
  /// Requests waiting behind this one.
  let waiting: Int
  var compact = false
  let answer: (PermissionBroker.Decision) -> Void

  static let armingDelay = Duration.milliseconds(750)
  @State private var isArmed = false
  @State private var box = DetailBox()

  /// What the detail box showed of a request.
  private struct DetailBox: Equatable {
    var request: UUID?
    var overflows = false
    var hasSeenEnd = false
  }

  /// Until the box has measured this request, Allow waits too.
  private var mustScrollToEnd: Bool {
    guard box.request == request.id else { return true }
    return box.overflows && !box.hasSeenEnd
  }

  var body: some View {
    VStack(alignment: .leading, spacing: compact ? 4 : 6) {
      HStack(spacing: 5) {
        AgentGlyph(agent: request.agent, size: 12)
        Text(verbatim: asker)
          .panelFont(.caption2)
          .foregroundStyle(.secondary)
          .lineLimit(1)
        Spacer(minLength: 0)
        if waiting > 0 {
          Text("+\(waiting)")
            .panelFont(.caption2, weight: .bold)
            .padding(.horizontal, 5)
            .background(.orange.opacity(0.3), in: Capsule())
            .accessibilityLabel(Text("\(waiting) more requests waiting"))
        }
      }
      Label {
        Text(verbatim: request.headline.isEmpty ? request.toolName : request.headline)
          .panelFont(.caption, weight: .semibold)
          .lineLimit(3)
      } icon: {
        Image(systemName: "hand.raised.fill")
          .foregroundStyle(.orange)
      }
      if let note = request.note {
        Text(verbatim: note)
          .panelFont(.caption)
          .foregroundStyle(.secondary)
          .lineLimit(2)
      }
      ScrollView {
        Text(request.detail)
          .panelFont(.caption, design: .monospaced)
          .textSelection(.enabled)
          .frame(maxWidth: .infinity, alignment: .leading)
      }
      .scrollIndicators(.visible)
      .onScrollGeometryChange(for: [Bool].self) { geometry in
        [
          geometry.contentSize.height > geometry.containerSize.height + 1,
          geometry.visibleRect.maxY >= geometry.contentSize.height - 1,
        ]
      } action: { _, new in
        let seen = box.request == request.id && box.hasSeenEnd
        box = DetailBox(request: request.id, overflows: new[0], hasSeenEnd: seen || new[1])
      }
      // A new request starts at the top, measured afresh.
      .id(request.id)
      .frame(maxHeight: compact ? 44 : 64)
      .padding(6)
      .background(.black.opacity(0.25), in: RoundedRectangle(cornerRadius: 6))
      if request.isSuspicious {
        Label(
          "This request has hidden characters or is too long to show safely. Answer it in the terminal.",
          systemImage: "exclamationmark.triangle.fill"
        )
        .panelFont(.caption2)
        .foregroundStyle(.orange)
        .fixedSize(horizontal: false, vertical: true)
      } else if !request.canAllow {
        Text("Allowing this from the notch is turned off in Settings.")
          .panelFont(.caption2)
          .foregroundStyle(.secondary)
          .fixedSize(horizontal: false, vertical: true)
      } else if mustScrollToEnd && box.request == request.id {
        Label("Scroll to the end to allow it.", systemImage: "arrow.down")
          .panelFont(.caption2)
          .foregroundStyle(.secondary)
          .fixedSize(horizontal: false, vertical: true)
      }
      // In a narrow widget, In Terminal moves to a second row instead of being cut off.
      ViewThatFits(in: .horizontal) {
        HStack(spacing: 6) {
          allowAndDeny
          inTerminal
        }
        VStack(alignment: .leading, spacing: 4) {
          HStack(spacing: 6) { allowAndDeny }
          inTerminal
        }
      }
      .controlSize(.small)
      .disabled(!isArmed)
    }
    .task(id: request.id) {
      isArmed = false
      try? await Task.sleep(for: Self.armingDelay)
      isArmed = true
    }
  }

  /// "Claude • Notch texts · LJASP-studio › brain", without the project twice.
  private var asker: String {
    var parts = [request.agent.name]
    let title = request.sessionTitle
    if !title.isEmpty, !request.project.hasPrefix(title) {
      parts.append(title)
    }
    let place = request.project.isEmpty ? [] : [request.project]
    return parts.joined(separator: " • ") + place.map { " · \($0)" }.joined()
  }

  @ViewBuilder private var allowAndDeny: some View {
    if request.canAllow {
      Button {
        answer(.allow)
      } label: {
        Text("Allow").prominentLabelInk(on: .green)
      }
      .buttonStyle(.borderedProminent)
      .tint(.green)
      .disabled(mustScrollToEnd)
    }
    Button("Deny") { answer(.deny) }
      .buttonStyle(.bordered)
  }

  private var inTerminal: some View {
    Button("In Terminal") { answer(.askInTerminal) }
      .buttonStyle(.bordered)
      .help(Text("Answer in Claude Code instead"))
  }
}
