import SwiftUI

/// Settings > Agents > Claude Code: turns the status line bridge on or off. Like the hooks,
/// every change is shown as a diff first and the old file is backed up.
struct StatusLineSection: View {
  let server: LocalServer

  @State private var status: HookInstaller.Status?
  @State private var plan: HookInstaller.Plan?
  @State private var message: String?

  private let installer = HookInstaller.standard

  var body: some View {
    Section("Context and Limits") {
      LabeledContent("Status line") { statusLabel }
      HStack {
        Button(status == .outdated ? "Update…" : "Install…") { review(install: true) }
          .disabled(server.hookToken.isEmpty || status == .installed || status == nil)
        Button("Remove…", role: .destructive) { review(install: false) }
          .disabled(status == .notInstalled || status == nil)
      }
      Text(
        "Claude Code tells only its status line how full the context is and how much of your plan's limits you've used. Installing adds a small command to the status line that passes these to Cumba and then runs your own status line command, so it looks as before. Terminal sessions only; limits show for Claude subscriptions."
      )
      .font(.callout)
      .foregroundStyle(.secondary)
      .fixedSize(horizontal: false, vertical: true)
      if let message {
        Text(message)
          .font(.callout)
          .foregroundStyle(.secondary)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
    .task { await refresh() }
    .sheet(item: $plan) { plan in
      DiffSheet(plan: plan) {
        self.plan = nil
        apply(plan)
      } cancel: {
        self.plan = nil
      }
    }
  }

  @ViewBuilder private var statusLabel: some View {
    switch status {
    case .installed:
      Label("Installed", systemImage: "checkmark.circle.fill").foregroundStyle(.green)
    case .outdated:
      Label("Out of date (token or format changed)", systemImage: "arrow.triangle.2.circlepath")
        .foregroundStyle(.orange)
    case .notInstalled:
      Text("Not installed").foregroundStyle(.secondary)
    case nil:
      Text(verbatim: "—").foregroundStyle(.secondary)
    }
  }

  private func refresh() async {
    let installer = installer
    let token = server.hookToken
    status = await Task.detached { try? installer.statusLineStatus(token: token) }.value
  }

  private func review(install: Bool) {
    let installer = installer
    let token = server.hookToken
    Task {
      let result = await Task.detached { () -> Result<HookInstaller.Plan, HookInstaller.Failure> in
        do throws(HookInstaller.Failure) {
          return .success(try installer.planStatusLine(install: install, token: token))
        } catch {
          return .failure(error)
        }
      }.value
      switch result {
      case .success(let reviewed): plan = reviewed
      case .failure(let failure): message = ClaudeCodeSettingsView.describe(failure)
      }
    }
  }

  private func apply(_ plan: HookInstaller.Plan) {
    let installer = installer
    Task {
      let result = await Task.detached { () -> Result<URL?, HookInstaller.Failure> in
        do throws(HookInstaller.Failure) {
          return .success(try installer.apply(plan))
        } catch {
          return .failure(error)
        }
      }.value
      switch result {
      case .success(let backup):
        message =
          backup.map {
            String(localized: "Saved. The previous file was backed up to \($0.lastPathComponent).")
          } ?? String(localized: "Saved.")
      case .failure(let failure):
        message = ClaudeCodeSettingsView.describe(failure)
      }
      await refresh()
    }
  }
}
