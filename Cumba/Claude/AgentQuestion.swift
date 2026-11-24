import Foundation

/// One question of Claude Code's AskUserQuestion tool, as the notch offers it. `question`
/// and the option labels stay exactly as received, since the answer is keyed by them; the
/// `shown` fields are escaped (`SafeText`) for the screen.
struct AgentQuestion: Equatable, Sendable {
  struct Option: Equatable, Sendable {
    let label: String
    let shownLabel: String
    let shownDetail: String?
  }

  let question: String
  let shownQuestion: String
  let shownHeader: String?
  let options: [Option]
  let multiSelect: Bool
  /// Hidden characters or truncation in anything shown; the notch won't answer it then.
  let isSuspicious: Bool

  /// The questions in an AskUserQuestion input, or nil when one has no question or options.
  static func parse(_ input: [String: JSONValue]?) -> [AgentQuestion]? {
    guard case .array(let items)? = input?["questions"], !items.isEmpty, items.count <= 8 else {
      return nil
    }
    var questions: [AgentQuestion] = []
    for item in items {
      guard case .object(let fields) = item, let question = fields["question"]?.string,
        !question.isEmpty, case .array(let rawOptions)? = fields["options"],
        (1...12).contains(rawOptions.count)
      else { return nil }
      var suspicious = false
      func safe(_ text: String) -> String {
        let checked = SafeText(text)
        suspicious = suspicious || checked.isSuspicious
        return checked.text
      }
      var options: [Option] = []
      for raw in rawOptions {
        guard case .object(let option) = raw, let label = option["label"]?.string,
          !label.isEmpty
        else { return nil }
        let detail = option["description"]?.string.flatMap { $0.isEmpty ? nil : $0 }
        options.append(
          Option(label: label, shownLabel: safe(label), shownDetail: detail.map(safe)))
      }
      // Two options with one label couldn't be told apart in the answer.
      guard Set(options.map(\.label)).count == options.count else { return nil }
      let header = fields["header"]?.string.flatMap { $0.isEmpty ? nil : $0 }
      let multi = if case .bool(true)? = fields["multiSelect"] { true } else { false }
      questions.append(
        AgentQuestion(
          question: question, shownQuestion: safe(question), shownHeader: header.map(safe),
          options: options, multiSelect: multi, isSuspicious: suspicious))
    }
    // Answers are keyed by the question's text, so each must be unique.
    guard Set(questions.map(\.question)).count == questions.count else { return nil }
    return questions
  }

  /// Claude Code's answer format: chosen labels, several joined with ", ", in option order.
  func answer(picking indices: Set<Int>) -> String? {
    let labels = options.indices.filter(indices.contains).map { options[$0].label }
    guard !labels.isEmpty, multiSelect || labels.count == 1 else { return nil }
    return labels.joined(separator: ", ")
  }
}

extension JSONValue {
  /// The value as `JSONSerialization` takes it.
  var foundationValue: Any {
    switch self {
    case .string(let value): value
    case .number(let value): value
    case .bool(let value): value
    case .array(let values): values.map(\.foundationValue)
    case .object(let fields): fields.mapValues(\.foundationValue)
    case .null: NSNull()
    }
  }
}
