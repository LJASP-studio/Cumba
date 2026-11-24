import Foundation

/// "5 h 34% · Week 12%": each usage window with how much of it is used.
enum AgentLimitText {
  static func line(_ limits: [UsageLimit]) -> String {
    limits.map { limit in
      let percent = limit.usedFraction.formatted(.percent.precision(.fractionLength(0)))
      return "\(window(limit.windowMinutes)) \(percent)"
    }.joined(separator: " · ")
  }

  static func window(_ minutes: Int?) -> String {
    guard let minutes, minutes > 0 else {
      return String(localized: "Limit", comment: "A usage limit of unknown length")
    }
    if minutes == 7 * 24 * 60 {
      return String(localized: "Week", comment: "Short name of a weekly usage limit")
    }
    if minutes % (24 * 60) == 0 {
      return String(
        localized: "\(minutes / (24 * 60)) d", comment: "Short length of a usage limit in days")
    }
    if minutes >= 60, minutes % 60 == 0 {
      return String(
        localized: "\(minutes / 60) h", comment: "Short length of a usage limit in hours")
    }
    return String(localized: "\(minutes) min", comment: "Short length of a usage limit in minutes")
  }
}
