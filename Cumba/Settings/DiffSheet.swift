import SwiftUI

extension HookInstaller.Plan: Identifiable {
  var id: String { newText }
}

/// Shows the planned change line by line before anything is written.
struct DiffSheet: View {
  let plan: HookInstaller.Plan
  let confirm: () -> Void
  let cancel: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Review changes to ~/.claude/settings.json")
        .font(.headline)
      Text("A backup of the current file is made before saving.")
        .font(.callout)
        .foregroundStyle(.secondary)
      if plan.reformats {
        Label(
          "Saving also rewrites the file in a standard format (keys sorted, two-space indents). Its contents change only as shown below.",
          systemImage: "info.circle"
        )
        .font(.callout)
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)
      }
      ScrollView {
        VStack(alignment: .leading, spacing: 0) {
          ForEach(plan.diff) { line in
            Text(prefix(line.kind) + line.text)
              .font(.system(.caption, design: .monospaced))
              .foregroundStyle(color(line.kind))
              .frame(maxWidth: .infinity, alignment: .leading)
              .background(background(line.kind))
          }
        }
        .textSelection(.enabled)
        .padding(8)
      }
      .background(.background.secondary, in: RoundedRectangle(cornerRadius: 8))
      HStack {
        Spacer()
        Button("Cancel", role: .cancel, action: cancel)
          .keyboardShortcut(.cancelAction)
        Button("Save", action: confirm)
          .keyboardShortcut(.defaultAction)
          .disabled(!plan.hasChanges)
      }
    }
    .padding(20)
    .frame(width: 600, height: 460)
  }

  private func prefix(_ kind: DiffLine.Kind) -> String {
    switch kind {
    case .added: "+ "
    case .removed: "- "
    case .context: "  "
    }
  }

  private func color(_ kind: DiffLine.Kind) -> Color {
    switch kind {
    case .added: .green
    case .removed: .red
    case .context: .primary
    }
  }

  private func background(_ kind: DiffLine.Kind) -> Color {
    switch kind {
    case .added: .green.opacity(0.08)
    case .removed: .red.opacity(0.08)
    case .context: .clear
    }
  }
}
