import Foundation
import Observation

/// Holds Claude Code permission requests until the user answers in the notch.
/// Each request keeps its HTTP response waiting; it is answered with the
/// user's decision, or with "ask in the terminal" before the hook times out.
@MainActor
@Observable
final class PermissionBroker {
  struct Request: Identifiable, Equatable, Sendable {
    let id: UUID
    let sessionID: String
    let project: String
    let toolName: String
    /// Everything the request would do, escaped (see `SafeText`).
    let detail: String
    /// Hidden characters or truncation found; Allow isn't offered then.
    let isSuspicious: Bool
    /// False when the request is suspicious or Settings turn off Allow for this tool.
    let canAllow: Bool
    let receivedAt: Date
    var agent = Agent.claude
    /// The session's title, or its project when it has none.
    var sessionTitle = ""
    /// What it asks for in a few words, e.g. "Wants to run a command".
    var headline = ""
    /// The agent's own words on what the command does, when it gave them.
    var note: String?
    /// A permission, or something Claude Code asks the user (Faz 15).
    var kind = Kind.permission
  }

  enum Kind: Equatable, Sendable {
    case permission
    /// AskUserQuestion: answered with the chosen options.
    case questions([AgentQuestion])
    /// ExitPlanMode: Allow approves the plan, Deny sends it back for more planning.
    case plan
  }

  enum Decision: Equatable, Sendable {
    case allow
    case deny
    /// Empty response: Claude Code continues with its own permission dialog.
    case askInTerminal
    /// AskUserQuestion's answers: question text → chosen label(s).
    case answers([String: String])
  }

  /// Oldest first; the notch shows the first one and the count.
  private(set) var pending: [Request] = [] {
    didSet { onPendingChange?() }
  }
  /// Called whenever a request arrives or is answered, also by timeout.
  @ObservationIgnored var onPendingChange: (() -> Void)?
  @ObservationIgnored private var continuations: [UUID: CheckedContinuation<Decision, Never>] = [:]
  @ObservationIgnored private let timeout: Duration

  /// The hook timeout is 300 s; answer 10 s earlier so Claude Code gets an answer.
  init(timeout: Duration = .seconds(290)) {
    self.timeout = timeout
  }

  /// Waits for the user's decision. Returns `.askInTerminal` on timeout or when the
  /// waiting task is cancelled, e.g. because Claude Code closed the connection.
  func decide(_ request: Request) async -> Decision {
    pending.append(request)
    let timeoutTask = Task { [weak self, timeout] in
      try? await Task.sleep(for: timeout)
      self?.resolve(request.id, with: .askInTerminal)
    }
    let decision = await withTaskCancellationHandler {
      await withCheckedContinuation { continuation in
        continuations[request.id] = continuation
      }
    } onCancel: {
      Task { @MainActor [weak self] in self?.resolve(request.id, with: .askInTerminal) }
    }
    timeoutTask.cancel()
    return decision
  }

  func resolve(_ id: UUID, with decision: Decision) {
    // Allow and answers reach Claude Code only for a request that offered them.
    let request = pending.first { $0.id == id }
    let canAllow = request?.canAllow == true
    let decision: Decision =
      switch decision {
      case .allow where !canAllow: .askInTerminal
      case .answers(let answers):
        canAllow && Self.answersFit(answers, request?.kind) ? decision : .askInTerminal
      default: decision
      }
    pending.removeAll { $0.id == id }
    continuations.removeValue(forKey: id)?.resume(returning: decision)
  }

  /// A later event of the same session means its open requests were answered elsewhere.
  func resolveAll(in sessionID: String) {
    for request in pending where request.sessionID == sessionID {
      resolve(request.id, with: .askInTerminal)
    }
  }

  /// The session moved past a question or a plan: it was answered in Claude Code.
  func resolveQuestions(in sessionID: String, toolName: String?) {
    for request in pending
    where request.sessionID == sessionID && request.kind != .permission
      && request.toolName == toolName
    {
      resolve(request.id, with: .askInTerminal)
    }
  }

  func hasPending(in sessionID: String) -> Bool {
    pending.contains { $0.sessionID == sessionID }
  }

  /// One answer per question, each made of that question's own labels.
  private static func answersFit(_ answers: [String: String], _ kind: Kind?) -> Bool {
    guard case .questions(let questions)? = kind, answers.count == questions.count else {
      return false
    }
    return questions.allSatisfy { question in
      guard let answer = answers[question.question] else { return false }
      let labels = question.options.map(\.label)
      return labels.contains(answer)
        || (question.multiSelect
          && answer.components(separatedBy: ", ").allSatisfy(labels.contains))
    }
  }

  /// Body of the HTTP response for a decision. Claude Code's question tools need their
  /// input back with an allow: the plan as it was, or the questions plus the answers.
  nonisolated static func responseBody(
    for decision: Decision, toolName: String? = nil, input: [String: JSONValue]? = nil
  ) -> Data {
    let isQuestionTool = toolName.map(HookPayload.questionTools.contains) ?? false
    var decisionObject: [String: Any]
    switch decision {
    case .allow:
      decisionObject = ["behavior": "allow"]
      if isQuestionTool {
        decisionObject["updatedInput"] = JSONValue.object(input ?? [:]).foundationValue
      }
    case .answers(let answers):
      guard toolName == "AskUserQuestion" else { return Data() }
      var fields = JSONValue.object(input ?? [:]).foundationValue as? [String: Any] ?? [:]
      fields["answers"] = answers
      decisionObject = ["behavior": "allow", "updatedInput": fields]
    case .deny:
      decisionObject = [
        "behavior": "deny",
        "message": toolName == "ExitPlanMode"
          ? "The user wants changes to the plan. Keep planning and ask again."
          : "Denied in Cumba.",
      ]
    case .askInTerminal:
      return Data()
    }
    let object: [String: Any] = [
      "hookSpecificOutput": [
        "hookEventName": "PermissionRequest",
        "decision": decisionObject,
      ]
    ]
    return (try? JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])) ?? Data()
  }
}
