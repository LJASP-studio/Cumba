import Foundation
import Testing

@testable import Cumba

struct AgentTextTests {
  @Test func titlesDropMarkupAndKeepPastedText() {
    #expect(
      AgentText.title(fromPrompt: #"<pasted_content id="32e5">Fix the notch</pasted_content>"#)
        == "Fix the notch")
    #expect(
      AgentText.title(fromPrompt: "<system-reminder>hidden</system-reminder>\nFix the notch")
        == "Fix the notch")
    #expect(
      AgentText.title(
        fromPrompt:
          "<command-name>/model</command-name>\n<command-message>model</command-message>\n<command-args>opus</command-args>"
      ) == "/model opus")
    #expect(AgentText.title(fromPrompt: "## **Fix** the `notch`") == "Fix the notch")
    #expect(
      AgentText.title(fromPrompt: "Look at /Users/x/Desktop/app/Notch.swift please")
        == "Look at Notch.swift please")
    #expect(
      AgentText.title(fromPrompt: "Read https://github.com/LJASP-studio/Cumba/issues/1")
        == "Read github.com")
    #expect(AgentText.title(fromPrompt: "<system-reminder>only</system-reminder>") == nil)
    #expect(AgentText.title(fromPrompt: "  \n ok \n") == nil)
  }

  @Test func longTitlesEndAfterAWord() throws {
    let title = try #require(
      AgentText.title(fromPrompt: String(repeating: "notch panel ", count: 20)))
    #expect(title.count <= 60)
    #expect(title.hasSuffix("…"))
    #expect(!title.contains("  "))
  }

  @Test func titlesShowHiddenCharacters() {
    #expect(AgentText.cleanTitle("Fix\u{202E}txt.exe")?.contains("U+202E") == true)
  }

  @Test func previewsEndOnASentence() {
    let answer = "I deleted the fork. GitHub now answers not found for it. Before that I checked."
    let preview = AgentText.preview(answer, limit: 40)
    #expect(preview.text == "I deleted the fork.")
    #expect(preview.isCut)
    #expect(AgentText.preview("Short one.", limit: 40) == .init(text: "Short one.", isCut: false))
  }

  @Test func previewsKeepParagraphsAndCloseCodeTicks() {
    let preview = AgentText.preview("First part.\n\n\nSecond   part.", limit: 100)
    #expect(preview.text == "First part.\nSecond part.")
    let cut = AgentText.preview("Run `swift test --filter AgentText now please", limit: 24)
    #expect(cut.text.filter { $0 == "`" }.count % 2 == 0)
  }

  @Test func previewsFlattenBlocks() {
    let preview = AgentText.preview(
      "## Done\n\n- one\n- two\n\n```swift\nlet x = 1\n```", limit: 200)
    #expect(preview.text == "Done\n• one • two\nlet x = 1")
  }

  @Test func fullAnswersKeepLines() {
    #expect(
      AgentText.full("## Done\n\n\n- one\n- two\n```\ncode\n```\n") == "Done\n\n• one\n• two\ncode")
  }

  @Test func notificationsGetTheFirstSentence() {
    #expect(
      AgentText.sentence("I deleted the **fork** and checked the PR. Next I'll update the vault.")
        == "I deleted the fork and checked the PR.")
    #expect(AgentText.sentence("Done. All tests pass.") == "Done. All tests pass.")
  }

  @Test func renderedMarkdownLeadsNowhere() {
    let text = AgentText.attributed("See [the site](https://example.com) and `code`.")
    #expect(String(text.characters) == "See the site and code.")
    #expect(text.runs.allSatisfy { $0.link == nil })
  }

  @Test func readableToolNames() {
    #expect(AgentText.toolName("mcp__Claude_Browser__navigate") == "Claude Browser: navigate")
    #expect(AgentText.toolName("mcp__github__create_pull_request") == "github: create pull request")
    #expect(AgentText.toolName("mcp__1a59c906-04da-521d-bda7-7f71b9f9e01c__batch") == "batch")
    #expect(AgentText.toolName("Bash") == "Bash")
  }

  @Test func commandsBecomeTheirProgram() {
    #expect(AgentText.command("cd app && git push -u origin x") == "git push")
    #expect(AgentText.command("FOO=1 sudo npm run build") == "npm run")
    #expect(AgentText.command("/usr/bin/curl -sf https://x") == "curl")
    #expect(AgentText.command("ls -la | head") == "ls")
    #expect(AgentText.command("xcodebuild test") == "xcodebuild test")
  }
}

struct TranscriptTitleTests {
  @Test func theUsersNameBeatsClaudeCodesTitle() {
    let lines = [
      #"{"type":"ai-title","aiTitle":"Old title","sessionId":"s"}"#,
      #"{"type":"custom-title","customTitle":"Sidebar name","sessionId":"s"}"#,
      #"{"type":"ai-title","aiTitle":"Newer title","sessionId":"s"}"#,
      #"{"type":"assistant","message":{"usage":{"input_tokens":10}}}"#,
    ]
    let summary = TranscriptReader.parse(lines.joined(separator: "\n"))
    #expect(summary.customTitle == "Sidebar name")
    #expect(summary.generatedTitle == "Newer title")
    #expect(summary.title == "Sidebar name")
  }
}

struct ProjectRootTests {
  @Test func findsTheFolderTheSessionStartedIn() {
    let transcript = "/Users/a/.claude/projects/-Users-a-Desktop-LJASP-studio/s.jsonl"
    #expect(ProjectRoot.encoded("/Users/a/Desktop/LJASP-studio") == "-Users-a-Desktop-LJASP-studio")
    #expect(
      ProjectRoot.root(of: "/Users/a/Desktop/LJASP-studio/brain/Daily", transcriptPath: transcript)
        == "/Users/a/Desktop/LJASP-studio")
    #expect(
      ProjectRoot.root(of: "/Users/a/Desktop/LJASP-studio", transcriptPath: transcript)
        == "/Users/a/Desktop/LJASP-studio")
    #expect(ProjectRoot.root(of: "/Users/b/other", transcriptPath: transcript) == nil)
    #expect(ProjectRoot.root(of: "/Users/a/x", transcriptPath: nil) == nil)
  }

  @Test func handlesSpacesAndTurkishLetters() {
    let start = "/Users/a/Masaüstü/Yeni proje"
    let transcript = "/Users/a/.claude/projects/\(ProjectRoot.encoded(start))/s.jsonl"
    #expect(ProjectRoot.root(of: start + "/kaynak", transcriptPath: transcript) == start)
  }
}

@MainActor
struct AgentTitleTests {
  private func payload(_ event: String, cwd: String = "/r/LJASP-studio", _ extra: String = "")
    -> HookPayload?
  {
    HookPayload.decode(
      Data(
        #"{"session_id":"s1","hook_event_name":"\#(event)","cwd":"\#(cwd)","transcript_path":"/h/.claude/projects/-r-LJASP-studio/s1.jsonl"\#(extra)}"#
          .utf8))
  }

  @Test func theProjectStaysWhereTheSessionStarted() throws {
    let service = ClaudeCodeService(liveActivities: LiveActivityCenter())
    service.handle(try #require(payload("UserPromptSubmit", cwd: "/r/LJASP-studio/brain")))
    let session = try #require(service.sessions.first)
    #expect(session.project == "LJASP-studio")
    #expect(session.subfolder == "brain")
    #expect(session.place == "LJASP-studio › brain")
  }

  @Test func aNameTheUserGaveWins() throws {
    let service = ClaudeCodeService(liveActivities: LiveActivityCenter())
    service.handle(
      try #require(
        payload("UserPromptSubmit", #","prompt":"<pasted_content>Fix it</pasted_content>""#)))
    #expect(service.sessions.first?.title == "Fix it")
    service.handle(
      try #require(
        payload("UserPromptSubmit", #","prompt":"Next","session_title":"Notch texts""#)))
    #expect(service.sessions.first?.title == "Notch texts")
    #expect(service.sessions.first?.titleSource == .custom)
  }

  @Test func waitingNoticesKeepTheAnswer() throws {
    let service = ClaudeCodeService(liveActivities: LiveActivityCenter())
    service.handle(try #require(payload("Stop", #","last_assistant_message":"All done.""#)))
    service.handle(
      try #require(
        payload(
          "Notification",
          #","message":"Claude is waiting for your input","notification_type":"idle_prompt""#)))
    #expect(service.sessions.first?.state == .waitingInput)
    #expect(service.sessions.first?.detail == "All done.")
    #expect(service.sessions.first?.detailKind == .reply)
  }
}

struct PermissionTextTests {
  private func payload(_ tool: String, _ input: String) -> HookPayload? {
    HookPayload.decode(
      Data(
        #"{"session_id":"s","hook_event_name":"PermissionRequest","cwd":"/r","tool_name":"\#(tool)","tool_input":\#(input)}"#
          .utf8))
  }

  @Test func headlinesSayWhatIsAsked() throws {
    let bash = try #require(
      payload("Bash", #"{"command":"git push","description":"Push the branch"}"#))
    #expect(bash.permissionHeadline.text == String(localized: "Wants to run a command"))
    #expect(bash.permissionNote?.text == "Push the branch")
    let edit = try #require(payload("Edit", #"{"file_path":"/r/Cumba/Notch.swift"}"#))
    #expect(edit.permissionHeadline.text.contains("Notch.swift"))
    #expect(edit.permissionNote == nil)
    let fetch = try #require(payload("WebFetch", #"{"url":"https://example.com/a?b=c"}"#))
    #expect(fetch.permissionHeadline.text.contains("example.com"))
    #expect(!fetch.permissionHeadline.text.contains("?b=c"))
    let tool = try #require(payload("mcp__github__merge", #"{"pr":1}"#))
    #expect(tool.permissionHeadline.text.contains("github: merge"))
  }

  @Test func oddKeysKeepTheirQuotes() throws {
    let tricky = try #require(payload("mcp__x__run", #"{"a\nb":"c"}"#))
    #expect(tricky.permissionDetail.text.contains("\"a"))
    let multiline = try #require(payload("mcp__x__run", #"{"script":"one\ntwo"}"#))
    #expect(multiline.permissionDetail.text.contains("script: \"one"))
  }
}
