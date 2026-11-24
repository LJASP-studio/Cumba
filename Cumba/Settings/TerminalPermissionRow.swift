import AppKit
import SwiftUI

/// Automation access to Terminal or iTerm2, so a notification's Open brings the agent
/// session's own tab forward. macOS asks only about an app that's running, and Cumba never
/// starts a terminal for it, so the button waits until the app is open.
struct TerminalPermissionRow: View {
  let bundleID: String
  let name: String
  @State private var permission = AppleScriptRunner.Permission.notDetermined
  @State private var isRunning = false

  var body: some View {
    LabeledContent {
      switch permission {
      case .granted:
        PermissionGranted()
      case .notDetermined:
        Button("Allow…") {
          Task {
            NSApp.activate()
            permission = await AppleScriptRunner.shared.permission(for: bundleID, ask: true)
          }
        }
        .disabled(!isRunning)
        .help(isRunning ? Text(verbatim: "") : Text("Open \(name) first"))
      case .denied:
        OpenPrivacySettings(pane: "Privacy_Automation")
      }
    } label: {
      Label {
        Text(verbatim: name)
      } icon: {
        Image(systemName: "terminal")
      }
      Text("AI Agents: Open brings the session's own tab forward")
    }
    .task {
      isRunning = AppleScriptRunner.isRunning(bundleID)
      permission = await AppleScriptRunner.shared.permission(for: bundleID, ask: false)
    }
  }
}
