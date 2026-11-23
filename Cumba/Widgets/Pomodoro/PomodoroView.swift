import AppKit
import SwiftUI

/// The Pomodoro card: the round, its countdown, the controls and today's count.
struct PomodoroView: View {
  let widget: PomodoroWidget

  private static let spacing: CGFloat = 8
  private static let buttonSize: CGFloat = 26
  private static let buttonSpacing: CGFloat = 6
  private static let countdownSize: CGFloat = 30

  var body: some View {
    WidgetCard(tint: widget.round.isBreak ? .green : nil) {
      VStack(alignment: .leading, spacing: Self.spacing) {
        // A long round name drops its symbol before it would break mid-word.
        ViewThatFits(in: .horizontal) {
          header(showsSymbol: true)
          header(showsSymbol: false)
        }
        countdown
          .panelFont(size: Self.countdownSize, weight: .semibold, monospacedDigit: true)
        // When the count doesn't fit beside the buttons (a long translation, large text),
        // it moves under them instead of breaking mid-word.
        ViewThatFits(in: .horizontal) {
          HStack(spacing: Self.buttonSpacing) {
            controls
            Spacer(minLength: 0)
            todayCount
          }
          VStack(alignment: .leading, spacing: Self.buttonSpacing) {
            HStack(spacing: Self.buttonSpacing) { controls }
            todayCount
          }
        }
      }
    }
  }

  private var isRunning: Bool {
    if case .running = widget.state { true } else { false }
  }

  private func header(showsSymbol: Bool) -> some View {
    HStack {
      Group {
        if showsSymbol {
          Label(widget.round.name, systemImage: widget.round.symbol)
        } else {
          Text(widget.round.name)
            .minimumScaleFactor(0.8)
        }
      }
      .panelFont(.caption)
      .foregroundStyle(.secondary)
      .lineLimit(1)
      Spacer()
      HStack(spacing: 4) {
        ForEach(0..<PomodoroWidget.roundsPerSet, id: \.self) { index in
          Circle()
            .fill(
              index < widget.finishedInSet ? AnyShapeStyle(.tint) : AnyShapeStyle(.quaternary)
            )
            .frame(width: 6, height: 6)
        }
      }
      .accessibilityElement()
      .accessibilityLabel(
        Text(
          "\(widget.finishedInSet) of \(PomodoroWidget.roundsPerSet) rounds",
          comment: "Pomodoro progress"))
    }
  }

  @ViewBuilder private var countdown: some View {
    switch widget.state {
    case .running(let endsAt):
      Text(timerInterval: Date()...endsAt, countsDown: true)
    case .paused(let remaining):
      Text(Duration.seconds(remaining), format: .time(pattern: .minuteSecond))
    case .idle:
      Text(Duration.seconds(widget.length), format: .time(pattern: .minuteSecond))
    }
  }

  @ViewBuilder private var controls: some View {
    controlButton(
      isRunning ? "pause.fill" : "play.fill",
      label: isRunning ? Text("Pause") : Text("Start")
    ) {
      isRunning ? widget.pause() : widget.start()
    }
    controlButton("forward.end.fill", label: Text("Skip")) { widget.skip() }
    controlButton("arrow.counterclockwise", label: Text("Reset")) { widget.reset() }
  }

  private var todayCount: some View {
    Text(Self.todayText(widget.finishedToday))
      .panelFont(.caption, monospacedDigit: true)
      .foregroundStyle(.secondary)
      .lineLimit(1)
      .fixedSize()
  }

  private static func todayText(_ count: Int) -> String {
    String(localized: "Today: \(count)", comment: "Finished pomodoro rounds today")
  }

  private func controlButton(_ symbol: String, label: Text, action: @escaping () -> Void)
    -> some View
  {
    Button(action: action) {
      Image(systemName: symbol)
        .contentTransition(.symbolEffect(.replace))
    }
    .buttonStyle(PanelButtonStyle(size: Self.buttonSize, isSelected: true))
    .accessibilityLabel(label)
    .help(label)
  }
}

extension PomodoroView {
  /// Height the card needs when today's count doesn't fit beside the buttons and moves under
  /// them, as laid out above; nil when it fits beside them.
  static func heightWithCountBelow(finishedToday: Int, width: CGFloat, textScale: CGFloat)
    -> CGFloat?
  {
    let caption = NSFont.monospacedDigitSystemFont(
      ofSize: (PanelFont.pointSize(of: .caption) * textScale).rounded(), weight: .regular)
    let count = todayText(finishedToday) as NSString
    let countWidth = ceil(count.size(withAttributes: [.font: caption]).width)
    // The card's padding is 10 on each side.
    let row = 3 * buttonSize + 4 * buttonSpacing + countWidth
    guard row > width - 20 else { return nil }
    let countdown = NSFont.monospacedDigitSystemFont(
      ofSize: (countdownSize * textScale).rounded(), weight: .semibold)
    // Padding, the round's line, the countdown, the buttons and the count under them.
    let lines = 2 * lineHeight(caption) + lineHeight(countdown)
    return ceil(20 + lines + buttonSize * 0.85 + 2 * spacing + buttonSpacing)
  }

  private static func lineHeight(_ font: NSFont) -> CGFloat {
    ceil(font.ascender - font.descender + font.leading)
  }
}
