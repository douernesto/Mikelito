import ApplicationServices
import Combine
import IOKit.pwr_mgt
import SwiftUI

@MainActor
final class MouseMover: ObservableObject {
    @Published private(set) var isOn = false
    private var timer: Timer?
    private var assertion: IOPMAssertionID = 0
    private var interval = Prefs.interval
    private var defaultsObserver: AnyCancellable?

    private var lockObservers: [AnyCancellable] = []

    private static var isScreenLocked: Bool {
        (CGSessionCopyCurrentDictionary() as? [String: Any])?["CGSSessionScreenIsLocked"] as? Bool ?? false
    }

    // Paused while the screen is locked, unless the user opted in to keep moving.
    private var isPaused: Bool { Self.isScreenLocked && !Prefs.moveWhenLocked }

    init() {
        defaultsObserver = NotificationCenter.default
            .publisher(for: UserDefaults.didChangeNotification)
            .sink { [weak self] _ in
                MainActor.assumeIsolated {
                    guard let self, self.isOn else { return }
                    self.updateAssertion()
                    guard Prefs.interval != self.interval else { return }
                    self.interval = Prefs.interval
                    self.schedule(after: self.interval)
                }
            }
        lockObservers = ["com.apple.screenIsLocked", "com.apple.screenIsUnlocked"].map {
            DistributedNotificationCenter.default()
                .publisher(for: Notification.Name($0))
                .sink { [weak self] _ in
                    MainActor.assumeIsolated { self?.updateAssertion() }
                }
        }
        start()
    }

    // Posting synthetic mouse events needs Accessibility access. The first call shows the system prompt;
    // until access is granted, check again every couple of seconds.
    private func start(prompt: Bool = true) {
        let options = ["AXTrustedCheckOptionPrompt": prompt] as CFDictionary
        guard AXIsProcessTrustedWithOptions(options) else {
            timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { [weak self] _ in
                MainActor.assumeIsolated { self?.start(prompt: false) }
            }
            return
        }

        interval = Prefs.interval
        schedule(after: interval)
        isOn = true
        updateAssertion()
    }

    // Holds the power assertion only while the app should be keeping the Mac active.
    private func updateAssertion() {
        let shouldHold = isOn && !isPaused
        if shouldHold, assertion == 0 {
            IOPMAssertionCreateWithName(
                kIOPMAssertPreventUserIdleDisplaySleep as CFString,
                IOPMAssertionLevel(kIOPMAssertionLevelOn),
                "Mikelito is active" as CFString,
                &assertion)
        } else if !shouldHold, assertion != 0 {
            IOPMAssertionRelease(assertion)
            assertion = 0
        }
    }

    private func schedule(after delay: TimeInterval) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            MainActor.assumeIsolated { self?.nudge() }
        }
    }

    // Moves the pointer one pixel and back, but only if the user has been idle for a full interval
    // and the screen is not locked (unless the user opted in).
    private func nudge() {
        if isPaused {
            schedule(after: interval)
            return
        }
        let idle = CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: .mouseMoved)
        guard idle >= interval, let here = CGEvent(source: nil)?.location else {
            schedule(after: max(interval - idle, 1))
            return
        }
        defer { schedule(after: interval) }
        for dx in [1.0, 0.0] {
            let to = CGPoint(x: here.x + dx, y: here.y)
            CGEvent(mouseEventSource: nil, mouseType: .mouseMoved, mouseCursorPosition: to, mouseButton: .left)?
                .post(tap: .cghidEventTap)
        }
    }
}
