import SwiftUI

extension EnvironmentValues {
  /// Whether a label on the panel's accent color reads better in dark ink than in white.
  @Entry var accentNeedsDarkInk = false
}

extension HexColor {
  /// The lowest contrast at which a filled button keeps its white label: WCAG's 3:1 for
  /// controls and large text. macOS draws white on the blue accents at about 3.7:1, so those
  /// keep the system look.
  static let whiteLabelMinimumContrast = 3.0

  static let white = HexColor(red: 0xFF, green: 0xFF, blue: 0xFF)
  static let black = HexColor(red: 0, green: 0, blue: 0)

  /// True when white on this color falls below `whiteLabelMinimumContrast`.
  var needsDarkInk: Bool {
    contrast(with: .white) < Self.whiteLabelMinimumContrast
  }
}

extension View {
  /// Dark ink for the label of a bordered prominent button whose tint is too light for white.
  /// macOS turns the label dark only on the lightest tints and keeps white on pink, orange,
  /// violet or green. Pass `tint` when the button has its own; otherwise the panel's accent
  /// decides.
  func prominentLabelInk(on tint: Color? = nil) -> some View {
    modifier(ProminentLabelInk(tint: tint))
  }
}

private struct ProminentLabelInk: ViewModifier {
  let tint: Color?
  @Environment(\.accentNeedsDarkInk) private var accentNeedsDarkInk
  /// While the window isn't key the button is gray and macOS's white label is right.
  @Environment(\.appearsActive) private var appearsActive
  /// A disabled button's fill is dimmed; the system's dimmed label suits it better.
  @Environment(\.isEnabled) private var isEnabled

  func body(content: Content) -> some View {
    if appearsActive, isEnabled, tint.map({ HexColor($0).needsDarkInk }) ?? accentNeedsDarkInk {
      content.foregroundStyle(Color.black)
    } else {
      content
    }
  }
}
