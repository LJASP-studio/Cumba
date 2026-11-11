import AppKit
import SwiftUI

/// A card's top: the app's icon, the kind of item and how long ago. When the kind and the
/// time don't fit on one line, the time goes under the kind; the row decides for all its
/// cards, so they stay the same height.
struct ClipCardHeader: View {
  let item: ClipboardItem
  let width: CGFloat
  var stacksTime = false

  static let titleFont = NSFont.systemFont(ofSize: 10, weight: .semibold)
  static let timeFont = NSFont.systemFont(ofSize: 9)
  static let timeStyle = Date.RelativeFormatStyle(presentation: .named, unitsStyle: .narrow)

  /// Narrow cards leave the kind to the icon and the color, so the time fits.
  static func showsTitle(width: CGFloat) -> Bool { width >= 140 }

  /// Whether the kind and the time fit side by side on a card this wide.
  static func fitsOnOneLine(title: String, time: String, width: CGFloat) -> Bool {
    // The padding, the icon, the gaps around the kind and the least space before the time.
    let room = width - 2 * 8 - 14 - 3 * 5 - 2
    return textWidth(title, titleFont) + textWidth(time, timeFont) <= room
  }

  /// Whether any card of the row needs its time under the kind.
  static func stacksTime(for items: [ClipboardItem], width: CGFloat) -> Bool {
    guard showsTitle(width: width) else { return false }
    return items.contains {
      !fitsOnOneLine(
        title: $0.content.title, time: $0.date.formatted(timeStyle), width: width)
    }
  }

  private static func textWidth(_ text: String, _ font: NSFont) -> CGFloat {
    ceil((text as NSString).size(withAttributes: [.font: font]).width) + 1
  }

  var body: some View {
    let showsTitle = Self.showsTitle(width: width)
    Group {
      if showsTitle && stacksTime {
        VStack(alignment: .leading, spacing: 1) {
          HStack(spacing: 5) {
            icon
            title
          }
          // Under the kind, past the icon.
          time
            .padding(.leading, 19)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
      } else {
        HStack(spacing: 5) {
          icon
          if showsTitle {
            title
          }
          Spacer(minLength: 2)
          time
        }
      }
    }
    .padding(.horizontal, 8)
    .frame(height: showsTitle && stacksTime ? 34 : 24)
    .background(item.content.color.opacity(0.28))
  }

  private var icon: some View {
    AppIcon(bundleID: item.appBundleID, fallback: item.content.symbol)
      .frame(width: 14, height: 14)
  }

  private var title: some View {
    Text(verbatim: item.content.title)
      .font(Font(Self.titleFont))
      .lineLimit(1)
  }

  private var time: some View {
    TimelineView(.everyMinute) { _ in
      Text(item.date, format: Self.timeStyle)
        .font(Font(Self.timeFont))
        .foregroundStyle(.secondary)
        .lineLimit(1)
    }
  }
}

/// The app an item came from, or a symbol for its kind.
private struct AppIcon: View {
  let bundleID: String?
  let fallback: String

  var body: some View {
    if let bundleID, let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID)
    {
      Image(nsImage: NSWorkspace.shared.icon(forFile: url.path(percentEncoded: false)))
        .resizable()
        .accessibilityHidden(true)
    } else {
      Image(systemName: fallback)
        .font(.system(size: 10, weight: .semibold))
        .accessibilityHidden(true)
    }
  }
}
