import Combine
import SwiftUI

@MainActor
final class AutoQuit {
    static let shared = AutoQuit()

    private var timer: Timer?
    private var duration = Prefs.quitAfter
    private var observer: AnyCancellable?

    func start() {
        observer = NotificationCenter.default
            .publisher(for: UserDefaults.didChangeNotification)
            .sink { [weak self] _ in
                MainActor.assumeIsolated {
                    guard let self, Prefs.quitAfter != self.duration else { return }
                    self.schedule()
                }
            }
        schedule()
    }

    private func schedule() {
        duration = Prefs.quitAfter
        timer?.invalidate()
        timer = nil
        guard let duration else { return }
        timer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { _ in
            MainActor.assumeIsolated { NSApplication.shared.terminate(nil) }
        }
    }
}
