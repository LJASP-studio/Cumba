import SwiftUI
import Testing

@testable import Cumba

struct ProminentLabelTests {
  /// The blue accents keep macOS's white label on purpose: it's the system look and clears
  /// 3:1, WCAG's minimum for controls, though not 4.5:1.
  private static let whiteOnPurpose: Set = ["classic", "glass", "midnight"]

  @Test(arguments: Theme.builtIns)
  func labelOnTheAccentIsReadable(theme: Theme) {
    let accent = theme.accent
    let ink: HexColor = accent.needsDarkInk ? .black : .white
    let contrast = ink.contrast(with: accent)
    if Self.whiteOnPurpose.contains(theme.id) {
      #expect(!accent.needsDarkInk)
      #expect(contrast >= HexColor.whiteLabelMinimumContrast)
    } else {
      #expect(contrast >= 4.5, "\(theme.id): \(contrast)")
    }
  }

  @Test func lightAccentsTakeDarkInk() {
    for id in ["neon-tokyo", "sakura", "synthwave", "violet-night", "citrus", "neon-palms"] {
      let theme = Theme.builtIns.first { $0.id == id }
      #expect(theme?.accent.needsDarkInk == true, "\(id)")
    }
  }

  /// Allow is green in every theme; white on it is about 2:1.
  @Test func allowGreenTakesDarkInk() {
    let green = HexColor(Color.green)
    #expect(green.needsDarkInk)
    #expect(HexColor.black.contrast(with: green) >= 4.5)
  }
}
