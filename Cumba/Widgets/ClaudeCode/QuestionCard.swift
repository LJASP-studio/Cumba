import SwiftUI

/// The card for whatever an agent waits on: a question gets its options, a plan or a
/// permission the Allow / Deny card.
struct AgentRequestCard: View {
  let request: PermissionBroker.Request
  let waiting: Int
  var compact = false
  let answer: (PermissionBroker.Decision) -> Void

  var body: some View {
    if case .questions(let questions) = request.kind {
      QuestionCard(
        request: request, questions: questions, waiting: waiting, compact: compact,
        answer: answer)
    } else {
      PermissionCard(request: request, waiting: waiting, compact: compact, answer: answer)
    }
  }
}

/// Claude Code's AskUserQuestion in the notch: one question at a time with its options as
/// buttons. A single choice moves on with a click; several choices take a Next or Send.
/// Answers go back only once every question has one, and In Terminal is always there.
///
/// Safety: options stay disabled for a moment after each question appears, so a click
/// aimed elsewhere can't answer it. A question with hidden characters gets no options.
struct QuestionCard: View {
  let request: PermissionBroker.Request
  let questions: [AgentQuestion]
  let waiting: Int
  var compact = false
  let answer: (PermissionBroker.Decision) -> Void

  @State private var index = 0
  @State private var picked: [Int: Set<Int>] = [:]
  @State private var isArmed = false

  private var question: AgentQuestion { questions[min(index, questions.count - 1)] }
  private var canAnswer: Bool { request.canAllow && !question.isSuspicious }

  var body: some View {
    VStack(alignment: .leading, spacing: compact ? 4 : 6) {
      HStack(spacing: 5) {
        AgentGlyph(agent: request.agent, size: 12)
        Text(verbatim: PermissionCard.asker(of: request))
          .panelFont(.caption2)
          .foregroundStyle(.secondary)
          .lineLimit(1)
        Spacer(minLength: 0)
        if questions.count > 1 {
          Text("\(index + 1) of \(questions.count)", comment: "Which question of how many")
            .panelFont(.caption2, weight: .semibold)
            .foregroundStyle(.secondary)
        }
        if waiting > 0 {
          Text("+\(waiting)")
            .panelFont(.caption2, weight: .bold)
            .padding(.horizontal, 5)
            .background(.orange.opacity(0.3), in: Capsule())
            .accessibilityLabel(Text("\(waiting) more requests waiting"))
        }
      }
      Label {
        Text(verbatim: question.shownQuestion)
          .panelFont(.caption, weight: .semibold)
          .lineLimit(3)
      } icon: {
        Image(systemName: "questionmark.bubble.fill")
          .foregroundStyle(.purple)
      }
      if canAnswer {
        ScrollView {
          VStack(alignment: .leading, spacing: 3) {
            ForEach(question.options.indices, id: \.self) { option in
              optionButton(option)
            }
          }
        }
        .scrollIndicators(.visible)
        .frame(maxHeight: compact ? 66 : 110)
        .disabled(!isArmed)
      } else {
        Label(
          "This question has hidden characters or is too long to show safely. Answer it in the terminal.",
          systemImage: "exclamationmark.triangle.fill"
        )
        .panelFont(.caption2)
        .foregroundStyle(.orange)
        .fixedSize(horizontal: false, vertical: true)
      }
      HStack(spacing: 6) {
        if canAnswer, question.multiSelect {
          Button {
            next()
          } label: {
            Group {
              if isLast {
                Text("Send", comment: "Button: sends the answers to an AI agent's questions")
              } else {
                Text("Next", comment: "Button: moves to the AI agent's next question")
              }
            }
            .prominentLabelInk(on: .purple)
          }
          .buttonStyle(.borderedProminent)
          .tint(.purple)
          .disabled(!isArmed || (picked[index] ?? []).isEmpty)
        }
        if index > 0 {
          Button("Back") { index -= 1 }
            .buttonStyle(.bordered)
        }
        Button("In Terminal") { answer(.askInTerminal) }
          .buttonStyle(.bordered)
          .help(Text("Answer in Claude Code instead"))
      }
      .controlSize(.small)
    }
    .task(id: index) {
      isArmed = false
      try? await Task.sleep(for: PermissionCard.armingDelay)
      isArmed = true
    }
  }

  private var isLast: Bool { index == questions.count - 1 }

  private func optionButton(_ option: Int) -> some View {
    let item = question.options[option]
    let isPicked = picked[index]?.contains(option) == true
    return Button {
      if question.multiSelect {
        picked[index, default: []].formSymmetricDifference([option])
      } else {
        picked[index] = [option]
        next()
      }
    } label: {
      HStack(alignment: .firstTextBaseline, spacing: 6) {
        Image(
          systemName: question.multiSelect
            ? (isPicked ? "checkmark.square.fill" : "square")
            : (isPicked ? "largecircle.fill.circle" : "circle")
        )
        .foregroundStyle(isPicked ? .purple : .secondary)
        VStack(alignment: .leading, spacing: 1) {
          Text(verbatim: item.shownLabel)
            .panelFont(.caption, weight: .medium)
            .lineLimit(2)
          if let detail = item.shownDetail {
            Text(verbatim: detail)
              .panelFont(.caption2)
              .foregroundStyle(.secondary)
              .lineLimit(2)
          }
        }
        Spacer(minLength: 0)
      }
      .padding(.horizontal, 6)
      .padding(.vertical, 3)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(
        (isPicked ? Color.purple.opacity(0.22) : Color.white.opacity(0.06)),
        in: RoundedRectangle(cornerRadius: 6)
      )
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
  }

  /// To the next question, or every answer back to Claude Code after the last one.
  private func next() {
    guard isLast else {
      index += 1
      return
    }
    var answers: [String: String] = [:]
    for (number, question) in questions.enumerated() {
      guard let text = question.answer(picking: picked[number] ?? []) else {
        index = number
        return
      }
      answers[question.question] = text
    }
    answer(.answers(answers))
  }
}
