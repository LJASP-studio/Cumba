import FlyingFox
import Foundation

/// `POST /claude/status`: Claude Code's status line input, sent by the status line bridge
/// (`StatusLineBridge.swift`). Only the session, the context's fill and the usage limits are
/// read; nothing is kept beyond the session in memory.
struct StatusLineRoute: HTTPHandler {
  let token: String
  let service: ClaudeCodeService

  struct Input: Decodable, Sendable {
    struct Context: Decodable, Sendable {
      var usedPercentage: Double?
      enum CodingKeys: String, CodingKey { case usedPercentage = "used_percentage" }
    }
    struct Window: Decodable, Sendable {
      var usedPercentage: Double?
      var resetsAt: Double?
      enum CodingKeys: String, CodingKey {
        case usedPercentage = "used_percentage"
        case resetsAt = "resets_at"
      }
    }
    struct Limits: Decodable, Sendable {
      var fiveHour: Window?
      var sevenDay: Window?
      enum CodingKeys: String, CodingKey {
        case fiveHour = "five_hour"
        case sevenDay = "seven_day"
      }
    }

    var sessionID: String
    var contextWindow: Context?
    var rateLimits: Limits?

    enum CodingKeys: String, CodingKey {
      case sessionID = "session_id"
      case contextWindow = "context_window"
      case rateLimits = "rate_limits"
    }

    static func decode(_ data: Data) -> Input? {
      guard data.count <= HookPayload.maxBodySize else { return nil }
      return try? JSONDecoder().decode(Input.self, from: data)
    }

    var contextFraction: Double? {
      contextWindow?.usedPercentage.map { min(1, max(0, $0 / 100)) }
    }

    var limits: [UsageLimit] {
      [(rateLimits?.fiveHour, 300), (rateLimits?.sevenDay, 7 * 24 * 60)].compactMap {
        window, minutes in
        guard let percent = window?.usedPercentage else { return nil }
        return UsageLimit(
          usedFraction: min(1, max(0, percent / 100)), windowMinutes: minutes,
          resetsAt: window?.resetsAt.map { Date(timeIntervalSince1970: $0) })
      }
    }
  }

  func handleRequest(_ request: HTTPRequest) async throws -> HTTPResponse {
    if request.headers[HTTPHeader("Origin")] != nil {
      return HTTPResponse(statusCode: .forbidden)
    }
    if RequestGuard.checkToken(
      request.headers[HTTPHeader(RequestGuard.tokenHeader)], expected: token) != nil
    {
      return HTTPResponse(statusCode: .unauthorized)
    }
    guard let input = Input.decode(try await request.bodyData) else {
      return HTTPResponse(statusCode: .badRequest)
    }
    Task { @MainActor in
      service.setUsage(
        of: input.sessionID, context: input.contextFraction, limits: input.limits,
        fromStatusLine: true)
    }
    return HTTPResponse(statusCode: .ok)
  }
}
