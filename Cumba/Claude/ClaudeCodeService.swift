import Foundation
import Observation
import SwiftUI

/// Claude Code sessions as reported by hooks, plus the live activities they cause.
/// Nothing is written to disk.
@MainActor
@Observable
final class ClaudeCodeService {
  /// Most recently updated first.
  private(set) var sessions: [Session] = []
  let permissions: PermissionBroker
  /// From Settings > Claude Code; applies to requests that arrive afterwards.
  var notchApprovals = NotchApprovals.all
  /// With several sessions, the widget lists them instead of showing "+N".
  var showsSessionList = true
  /// Questions and plans can be answered in the notch; otherwise only in Claude Code.
  var answersInNotch = true

  @ObservationIgnored let liveActivities: LiveActivityCenter
  @ObservationIgnored private var removalTasks: [String: Task<Void, Never>] = [:]
  @ObservationIgnored private var transcriptReads: [String: Date] = [:]
  @ObservationIgnored var codexReads: [String: Date] = [:]
  /// For a turn that ends without a hook (QuietTurns.swift).
  @ObservationIgnored var transcripts: [String: URL] = [:]
  @ObservationIgnored var watchers: [String: TranscriptWatcher] = [:]
  @ObservationIgnored var silenceTasks: [String: Task<Void, Never>] = [:]
  /// The session and notice the status activity shows.
  @ObservationIgnored var shownNotice: (session: String, notice: AgentNotice)?

  static let permissionActivityID = "claude.permission"
  static let statusActivityID = "claude.status"
  private static let workingActivityID = "claude.working"

  init(liveActivities: LiveActivityCenter, permissions: PermissionBroker = PermissionBroker()) {
    self.liveActivities = liveActivities
    self.permissions = permissions
    permissions.onPendingChange = { [weak self] in
      self?.updatePermissionActivity()
    }
  }

  /// Handles every event except permission requests, which `requestPermission` handles.
  /// - Parameter app: Bundle identifier of the app the agent runs in, when the hook sent it.
  func handle(_ payload: HookPayload, agent: Agent = .claude, app: String? = nil) {
    guard let event = payload.event else { return }
    let id = payload.sessionID
    switch event {
    case .userPromptSubmit:
      permissions.resolveAll(in: id)
      update(id, payload, state: .working, step: AgentStep.thinking)
      setTitle(payload.sessionTitle.flatMap(AgentText.cleanTitle), source: .custom, of: id)
      setTitle(payload.prompt.flatMap(AgentText.title(fromPrompt:)), source: .prompt, of: id)
      refreshTranscript(of: id, path: payload.transcriptPath, force: true)
    case .preToolUse:
      update(
        id, payload, state: .working,
        step: AgentStep.describe(
          toolName: payload.toolName, input: payload.toolInput, cwd: payload.cwd))
    case .postToolUse:
      permissions.resolveQuestions(in: id, toolName: payload.toolName)
      update(id, payload, state: .working, step: AgentStep.thinking)
      refreshTranscript(of: id, path: payload.transcriptPath, force: false)
    case .notification:
      // A pending request or a question already shows; skip the duplicate notice.
      if payload.notificationType == "permission_prompt",
        permissions.hasPending(in: id)
          || sessions.first(where: { $0.id == id })?.state == .waitingInput
      {
        return
      }
      // Claude Code's own line ("waiting for your input") would hide the answer it's about.
      update(id, payload, state: .waitingInput)
      notify(.waiting, session: id, agent: agent, message: payload.message)
    case .stop:
      permissions.resolveAll(in: id)
      update(id, payload, state: .done, detail: payload.lastAssistantMessage, kind: .reply)
      refreshTranscript(of: id, path: payload.transcriptPath, force: true)
      notify(.done, session: id, agent: agent, message: payload.lastAssistantMessage)
    case .stopFailure:
      permissions.resolveAll(in: id)
      let error = payload.error ?? "unknown"
      update(
        id, payload, state: .failed(error), detail: payload.lastAssistantMessage, kind: .reply)
      notify(.failed, session: id, agent: agent, message: error)
    case .sessionEnd:
      permissions.resolveAll(in: id)
      update(id, payload, state: .ended)
      scheduleRemoval(of: id)
    case .permissionRequest:
      break
    }
    tag(id, with: agent, app: app)
    if agent == .codex, event != .sessionEnd {
      refreshCodex(of: id, path: payload.transcriptPath)
    }
    updateWorkingActivity()
  }

  /// Shows the request in the notch and waits for the user's decision.
  func requestPermission(_ payload: HookPayload, agent: Agent = .claude, app: String? = nil)
    async -> PermissionBroker.Decision
  {
    if payload.isQuestion {
      showQuestion(payload, agent: agent, app: app)
      guard answersInNotch, let request = questionRequest(payload, agent: agent) else {
        return .askInTerminal
      }
      let decision = await permissions.decide(request)
      if !permissions.hasPending(in: payload.sessionID),
        sessions.first(where: { $0.id == payload.sessionID })?.state == .waitingInput,
        decision != .askInTerminal
      {
        update(payload.sessionID, payload, state: .working, step: AgentStep.thinking)
        updateWorkingActivity()
      }
      return decision
    }
    update(payload.sessionID, payload, state: .waitingPermission)
    tag(payload.sessionID, with: agent, app: app)
    let session = sessions.first { $0.id == payload.sessionID }
    let detail = payload.permissionDetail
    // Everything shown above the Allow button is checked the same way.
    let project = SafeText(session?.place ?? payload.project)
    let title = SafeText(session?.displayTitle ?? payload.project)
    let tool = SafeText(payload.toolName ?? "?")
    let headline = payload.permissionHeadline
    let note = payload.permissionNote
    let isSuspicious =
      [detail, project, title, tool, headline].contains(where: \.isSuspicious)
      || note?.isSuspicious == true
    let request = PermissionBroker.Request(
      id: UUID(), sessionID: payload.sessionID, project: project.text, toolName: tool.text,
      detail: detail.text, isSuspicious: isSuspicious,
      canAllow: !isSuspicious && notchApprovals.allows(toolName: tool.text),
      receivedAt: Date(), agent: agent, sessionTitle: title.text, headline: headline.text,
      note: note?.text)
    updateWorkingActivity()
    let decision = await permissions.decide(request)
    // A session stopped meanwhile stays stopped.
    if !permissions.hasPending(in: payload.sessionID),
      sessions.first(where: { $0.id == payload.sessionID })?.state == .waitingPermission
    {
      update(payload.sessionID, payload, state: .working, step: AgentStep.thinking)
      updateWorkingActivity()
    }
    return decision
  }

  /// A question or a plan to approve: Claude Code asks it in its own window, and the notch
  /// says so until it's answered.
  private func showQuestion(_ payload: HookPayload, agent: Agent, app: String?) {
    let question = payload.questionText.map { SafeText($0).text }
    update(payload.sessionID, payload, state: .waitingInput, detail: question, kind: .question)
    tag(payload.sessionID, with: agent, app: app)
    notify(
      payload.toolName == "ExitPlanMode" ? .plan : .question, session: payload.sessionID,
      agent: agent, message: question)
    updateWorkingActivity()
  }

  func answer(_ request: PermissionBroker.Request, with decision: PermissionBroker.Decision) {
    permissions.resolve(request.id, with: decision)
  }

  private func update(
    _ id: String, _ payload: HookPayload, state: Session.State, detail: String? = nil,
    kind: Session.DetailKind = .reply, step: String? = nil
  ) {
    removalTasks[id]?.cancel()
    let existing = sessions.first { $0.id == id }
    var session =
      existing ?? Session(id: id, project: payload.project, state: state, updatedAt: Date())
    session.locate(in: payload.cwd, transcriptPath: payload.transcriptPath)
    // A tool runs while a permission request is open only after it's answered.
    session.state = state
    if let detail {
      session.detail = String(detail.prefix(Session.maxDetailLength))
      session.detailKind = kind
    }
    session.step = state == .working ? (step ?? session.step) : nil
    session.updatedAt = Date()
    sessions.removeAll { $0.id == id }
    sessions.insert(session, at: 0)
    if let url = TranscriptReader.allowedURL(payload.transcriptPath) {
      transcripts[id] = url
    }
    followTurn(of: id)
    // A session first seen mid-turn gets its title without waiting for the next prompt.
    if existing == nil {
      refreshTranscript(of: id, path: payload.transcriptPath, force: true)
    }
  }

  /// Keeps the best title so far: one the user gave beats Claude Code's, which beats the
  /// prompt's first line.
  func setTitle(_ title: String?, source: Session.TitleSource, of id: String) {
    guard let title, let index = sessions.firstIndex(where: { $0.id == id }) else { return }
    // A later prompt doesn't rename the session; only a better source does.
    if let current = sessions[index].titleSource,
      current > source || (current == .prompt && source == .prompt)
    {
      return
    }
    sessions[index].title = title
    sessions[index].titleSource = source
  }

  /// The turn ended without telling the app (QuietTurns.swift).
  func markStopped(_ id: String) {
    stopFollowing(id)
    guard let index = sessions.firstIndex(where: { $0.id == id }), sessions[index].isActive
    else { return }
    sessions[index].state = .stopped
    sessions[index].step = nil
    permissions.resolveAll(in: id)
    updateWorkingActivity()
  }

  /// Reads the context use and title from the transcript, at most every 5 seconds per
  /// session unless forced.
  private func refreshTranscript(of id: String, path: String?, force: Bool) {
    guard let url = TranscriptReader.allowedURL(path) else { return }
    let now = Date()
    if !force, let last = transcriptReads[id], now.timeIntervalSince(last) < 5 {
      return
    }
    transcriptReads[id] = now
    Task { [weak self] in
      let summary = await Task.detached { TranscriptReader.read(url) }.value
      guard let self, let summary, let index = self.sessions.firstIndex(where: { $0.id == id })
      else { return }
      if let fraction = summary.contextFraction, !self.sessions[index].hasStatusLine {
        self.sessions[index].contextFraction = fraction
      }
      self.setTitle(
        summary.generatedTitle.flatMap(AgentText.cleanTitle), source: .generated, of: id)
      self.setTitle(summary.customTitle.flatMap(AgentText.cleanTitle), source: .custom, of: id)
    }
  }

  /// The context's fill and the limits, when a source reported them.
  /// The status line's numbers are exact, so the transcript's estimate doesn't replace them.
  func setUsage(
    of id: String, context: Double?, limits: [UsageLimit], fromStatusLine: Bool = false
  ) {
    guard let index = sessions.firstIndex(where: { $0.id == id }) else { return }
    if fromStatusLine { sessions[index].hasStatusLine = true }
    if let context { sessions[index].contextFraction = context }
    if !limits.isEmpty { sessions[index].limits = limits }
  }

  private func tag(_ id: String, with agent: Agent, app: String?) {
    if let index = sessions.firstIndex(where: { $0.id == id }) {
      sessions[index].agent = agent
      sessions[index].app = app ?? sessions[index].app
    }
  }

  /// A ring beside the notch while any session works. A question stays beside the notch
  /// until its session moves on.
  func updateWorkingActivity() {
    if let shown = shownNotice, shown.notice.waitsForUser,
      sessions.first(where: { $0.id == shown.session })?.state != .waitingInput
    {
      liveActivities.dismiss(Self.statusActivityID)
      shownNotice = nil
    }
    guard let working = sessions.first(where: { $0.state == .working }) else {
      liveActivities.dismiss(Self.workingActivityID)
      return
    }
    liveActivities.show(
      LiveActivity(
        id: Self.workingActivityID, priority: .claudeWorking,
        leading: AnyView(AgentGlyph(agent: working.agent, size: 18)),
        trailing: AnyView(AgentSpinner(agent: working.agent))))
  }

  /// Ended sessions leave the list after a minute.
  private func scheduleRemoval(of id: String) {
    removalTasks[id] = Task { [weak self] in
      do {
        try await Task.sleep(for: .seconds(60))
      } catch {
        return
      }
      guard let self else { return }
      if self.sessions.contains(where: { $0.id == id && $0.state == .ended }) {
        self.sessions.removeAll { $0.id == id }
        self.transcripts[id] = nil
        self.transcriptReads[id] = nil
        self.codexReads[id] = nil
      }
      self.removalTasks[id] = nil
    }
  }
}
