import Foundation

/// Questions and plans Claude Code asks, answered in the notch (Faz 15).
extension ClaudeCodeService {
  /// A question or a plan as a request the notch can answer, or nil when it can't be shown.
  func questionRequest(_ payload: HookPayload, agent: Agent) -> PermissionBroker.Request? {
    let session = sessions.first { $0.id == payload.sessionID }
    let project = SafeText(session?.place ?? payload.project)
    let title = SafeText(session?.displayTitle ?? payload.project)
    let kind: PermissionBroker.Kind
    let detail: SafeText
    var suspicious = project.isSuspicious || title.isSuspicious
    if payload.toolName == "AskUserQuestion" {
      guard let questions = AgentQuestion.parse(payload.toolInput) else { return nil }
      kind = .questions(questions)
      detail = SafeText(questions.map(\.question).joined(separator: "\n"))
      suspicious = suspicious || questions.contains(where: \.isSuspicious)
    } else {
      guard let plan = payload.toolInput?["plan"]?.string, !plan.isEmpty else { return nil }
      kind = .plan
      detail = SafeText(plan)
    }
    suspicious = suspicious || detail.isSuspicious
    return PermissionBroker.Request(
      id: UUID(), sessionID: payload.sessionID, project: project.text,
      toolName: payload.toolName ?? "?", detail: detail.text, isSuspicious: suspicious,
      canAllow: !suspicious && (kind == .plan ? notchApprovals != .never : true),
      receivedAt: Date(), agent: agent, sessionTitle: title.text,
      headline: payload.questionText.map { SafeText($0).text } ?? "", kind: kind)
  }
}
