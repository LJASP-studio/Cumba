import Foundation
import Testing

@testable import Cumba

private func payload(_ name: String) throws -> HookPayload {
  let url = URL(filePath: #filePath).deletingLastPathComponent()
    .appending(path: "Fixtures/claude/\(name).json")
  return try #require(HookPayload.decode(try Data(contentsOf: url)))
}

private func body(_ data: Data) throws -> [String: Any] {
  let object = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
  let output = try #require(object["hookSpecificOutput"] as? [String: Any])
  return try #require(output["decision"] as? [String: Any])
}

struct AgentQuestionTests {
  @Test func parsesQuestionsAndKeepsTheirExactText() throws {
    let questions = try #require(
      AgentQuestion.parse(try payload("permission-request-question").toolInput))
    #expect(questions.count == 1)
    #expect(questions[0].question == "Which theme should be the default?")
    #expect(questions[0].options.map(\.label) == ["Classic", "Neon Tokyo"])
    #expect(questions[0].options[1].shownDetail == "Pink and cyan neon")
    #expect(!questions[0].isSuspicious)
    #expect(questions[0].answer(picking: [1]) == "Neon Tokyo")
    // A single choice takes exactly one option.
    #expect(questions[0].answer(picking: [0, 1]) == nil)
    #expect(questions[0].answer(picking: []) == nil)
  }

  @Test func multipleChoicesJoinInOptionOrder() throws {
    let input = try #require(
      HookPayload.decode(
        Data(
          #"{"session_id":"s","hook_event_name":"PermissionRequest","tool_name":"AskUserQuestion","tool_input":{"questions":[{"question":"Which?","multiSelect":true,"options":[{"label":"A"},{"label":"B"},{"label":"C"}]}]}}"#
            .utf8)))
    let question = try #require(AgentQuestion.parse(input.toolInput)?.first)
    #expect(question.answer(picking: [2, 0]) == "A, C")
  }

  @Test func rejectsQuestionsTheAnswerCouldConfuse() throws {
    func parse(_ questions: String) throws -> [AgentQuestion]? {
      let payload = try #require(
        HookPayload.decode(
          Data(
            #"{"session_id":"s","hook_event_name":"PermissionRequest","tool_name":"AskUserQuestion","tool_input":{"questions":\#(questions)}}"#
              .utf8)))
      return AgentQuestion.parse(payload.toolInput)
    }
    #expect(try parse("[]") == nil)
    #expect(try parse(#"[{"question":"Q","options":[]}]"#) == nil)
    #expect(try parse(#"[{"question":"Q","options":[{"label":"A"},{"label":"A"}]}]"#) == nil)
    #expect(
      try parse(
        #"[{"question":"Q","options":[{"label":"A"}]},{"question":"Q","options":[{"label":"B"}]}]"#)
        == nil)
    let hidden = try #require(try parse(#"[{"question":"Q‮","options":[{"label":"A"}]}]"#))
    #expect(hidden[0].isSuspicious)
  }

  @Test func answersGoBackWithTheQuestions() throws {
    let question = try payload("permission-request-question")
    let data = PermissionBroker.responseBody(
      for: .answers(["Which theme should be the default?": "Classic"]),
      toolName: question.toolName, input: question.toolInput)
    let decision = try body(data)
    #expect(decision["behavior"] as? String == "allow")
    let input = try #require(decision["updatedInput"] as? [String: Any])
    #expect(
      (input["answers"] as? [String: String]) == ["Which theme should be the default?": "Classic"])
    #expect((input["questions"] as? [Any])?.count == 1)
  }

  @Test func planApprovalEchoesThePlanAndDenialAsksForChanges() throws {
    let plan = try payload("permission-request-plan")
    let allow = try body(
      PermissionBroker.responseBody(for: .allow, toolName: plan.toolName, input: plan.toolInput))
    let input = try #require(allow["updatedInput"] as? [String: Any])
    #expect((input["plan"] as? String)?.hasPrefix("## Plan") == true)
    let deny = try body(
      PermissionBroker.responseBody(for: .deny, toolName: plan.toolName, input: plan.toolInput))
    #expect((deny["message"] as? String)?.contains("Keep planning") == true)
    // Ordinary permissions don't get their input back.
    let bash = try body(PermissionBroker.responseBody(for: .allow, toolName: "Bash", input: [:]))
    #expect(bash["updatedInput"] == nil)
  }
}

@MainActor
struct NotchAnswerTests {
  private func waitForRequest(_ service: ClaudeCodeService) async {
    while service.permissions.pending.isEmpty {
      await Task.yield()
    }
  }

  @Test func aQuestionIsAnsweredInTheNotch() async throws {
    let center = LiveActivityCenter()
    let service = ClaudeCodeService(liveActivities: center)
    let decisionPayload = try payload("permission-request-question")
    async let decision = service.requestPermission(decisionPayload)
    await waitForRequest(service)
    let request = try #require(service.permissions.pending.first)
    guard case .questions(let questions) = request.kind else {
      Issue.record("Not a question")
      return
    }
    #expect(questions.count == 1)
    #expect(request.canAllow)
    // The question's own notice shows, not the permission badge.
    #expect(center.current?.priority == .claudeStatus)
    #expect(center.current?.notification?.title == AgentNotice.question.title(for: .claude))
    // Opening it from the notice shows the panel, where the question waits.
    #expect(center.current?.notification?.action?.perform() == false)
    service.answer(request, with: .answers(["Which theme should be the default?": "Classic"]))
    #expect(await decision == .answers(["Which theme should be the default?": "Classic"]))
    #expect(service.sessions.first?.state == .working)
  }

  @Test func answersThatDontMatchGoToTheTerminal() async throws {
    let service = ClaudeCodeService(liveActivities: LiveActivityCenter())
    let decisionPayload = try payload("permission-request-question")
    async let decision = service.requestPermission(decisionPayload)
    await waitForRequest(service)
    let request = try #require(service.permissions.pending.first)
    service.answer(request, with: .answers(["Which theme should be the default?": "Rainbow"]))
    #expect(await decision == .askInTerminal)
    #expect(service.sessions.first?.state == .waitingInput)
  }

  @Test func anAnswerInClaudeCodeClearsTheQuestion() async throws {
    let service = ClaudeCodeService(liveActivities: LiveActivityCenter())
    let decisionPayload = try payload("permission-request-question")
    async let decision = service.requestPermission(decisionPayload)
    await waitForRequest(service)
    let done = try #require(
      HookPayload.decode(
        Data(
          #"{"session_id":"session-1","hook_event_name":"PostToolUse","cwd":"/r/demo","tool_name":"AskUserQuestion"}"#
            .utf8)))
    service.handle(done)
    #expect(await decision == .askInTerminal)
    #expect(service.permissions.pending.isEmpty)
  }

  @Test func aPlanIsApprovedUnlessSettingsSayNever() async throws {
    let service = ClaudeCodeService(liveActivities: LiveActivityCenter())
    let decisionPayload = try payload("permission-request-plan")
    async let decision = service.requestPermission(decisionPayload)
    await waitForRequest(service)
    let request = try #require(service.permissions.pending.first)
    #expect(request.kind == .plan)
    #expect(request.detail.contains("Write the tests."))
    #expect(request.canAllow)
    service.answer(request, with: .allow)
    #expect(await decision == .allow)

    service.notchApprovals = .never
    let secondPayload = try payload("permission-request-plan")
    async let second = service.requestPermission(secondPayload)
    await waitForRequest(service)
    let blocked = try #require(service.permissions.pending.first)
    #expect(!blocked.canAllow)
    service.answer(blocked, with: .allow)
    #expect(await second == .askInTerminal)
  }
}
