import SwiftUI

/// A theme's faint silhouettes in the bottom corners of the open panel, behind the widgets.
/// Against a lighter bottom they're drawn in the top color, like trees against a sunset; on
/// a flat or glass fill they're a faint shape in the text color instead.
struct PanelScenery: View {
  let theme: Theme
  /// Increase Contrast leaves only what carries information.
  @Environment(\.colorSchemeContrast) private var contrast

  var body: some View {
    if theme.scenery == .palms, contrast != .increased {
      ZStack {
        silhouette("PalmsLeading", alignment: .bottomLeading)
        silhouette("PalmsTrailing", alignment: .bottomTrailing)
      }
      .foregroundStyle(ink.color)
      .opacity(ink.opacity)
      .allowsHitTesting(false)
      .accessibilityHidden(true)
    }
  }

  private func silhouette(_ name: String, alignment: Alignment) -> some View {
    Image(name)
      .renderingMode(.template)
      .resizable()
      .scaledToFit()
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
  }

  private var ink: (color: Color, opacity: Double) {
    if theme.material == .solid, let bottom = theme.gradient,
      bottom.contrast(with: theme.background) > 1.25
    {
      return (theme.background.color, 0.7)
    }
    return (theme.foreground.color, 0.08)
  }
}

extension HexColor {
  /// WCAG relative luminance, 0 for black and 1 for white.
  var luminance: Double {
    func linear(_ byte: UInt8) -> Double {
      let value = Double(byte) / 255
      return value <= 0.04045 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
    }
    return 0.2126 * linear(red) + 0.7152 * linear(green) + 0.0722 * linear(blue)
  }

  /// WCAG contrast ratio, from 1 (the same) to 21 (black and white).
  func contrast(with other: HexColor) -> Double {
    let (lighter, darker) = (max(luminance, other.luminance), min(luminance, other.luminance))
    return (lighter + 0.05) / (darker + 0.05)
  }
}
