import Foundation

/// A turn can end without a hook: Claude Code sends no Stop when you interrupt it, and none
/// at all if its process dies. While a session works, its transcript is watched for the
/// interrupt line, and a session that stays silent for half an hour stops spinning.
extension ClaudeCodeService {
  static let silenceLimit = Duration.seconds(30 * 60)

  /// Starts or stops following a session, by its state after an event.
  func followTurn(of id: String) {
    guard sessions.first(where: { $0.id == id })?.isActive == true else {
      stopFollowing(id)
      return
    }
    armSilence(for: id)
    guard watchers[id] == nil, let url = transcripts[id] else { return }
    watchers[id] = TranscriptWatcher(url: url) { [weak self] interrupted in
      guard let self else { return }
      if interrupted {
        self.markStopped(id)
      } else {
        self.armSilence(for: id)
      }
    }
  }

  func stopFollowing(_ id: String) {
    watchers[id]?.stop()
    watchers[id] = nil
    silenceTasks[id]?.cancel()
    silenceTasks[id] = nil
  }

  private func armSilence(for id: String) {
    silenceTasks[id]?.cancel()
    silenceTasks[id] = Task { [weak self] in
      do {
        try await Task.sleep(for: Self.silenceLimit)
      } catch {
        return
      }
      self?.markStopped(id)
    }
  }
}

/// Tells when a transcript grows, and whether it then ends in an interrupt. It reads the
/// file off the main thread, at most once a second, and only while it's kept.
final class TranscriptWatcher: @unchecked Sendable {
  // `lastRead` and `isReadPending` are touched only on `queue`.
  private let queue = DispatchQueue(
    label: "io.github.muazfurkan.ljaspnotch.transcript", qos: .utility)
  private let source: any DispatchSourceFileSystemObject
  private var lastRead = Date.distantPast
  private var isReadPending = false

  init?(url: URL, onWrite: @escaping @Sendable @MainActor (_ interrupted: Bool) -> Void) {
    let descriptor = open(url.path(percentEncoded: false), O_EVTONLY)
    guard descriptor >= 0 else { return nil }
    source = DispatchSource.makeFileSystemObjectSource(
      fileDescriptor: descriptor, eventMask: [.extend, .write], queue: queue)
    source.setEventHandler { [weak self] in self?.scheduleRead(of: url, onWrite: onWrite) }
    source.setCancelHandler { close(descriptor) }
    source.resume()
  }

  deinit {
    source.cancel()
  }

  func stop() {
    source.cancel()
  }

  private func scheduleRead(
    of url: URL, onWrite: @escaping @Sendable @MainActor (Bool) -> Void
  ) {
    guard !isReadPending else { return }
    isReadPending = true
    let wait = max(0, 1 - Date().timeIntervalSince(lastRead))
    queue.asyncAfter(deadline: .now() + wait) { [weak self] in
      guard let self, !self.source.isCancelled else { return }
      self.isReadPending = false
      self.lastRead = Date()
      let interrupted = TranscriptReader.endsInInterrupt(url)
      Task { @MainActor in onWrite(interrupted) }
    }
  }
}
