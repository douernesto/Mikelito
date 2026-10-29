import ApplicationServices
import ServiceManagement
import SwiftUI

enum Prefs {
    static let intervalKey = "intervalSeconds"
    static let defaultInterval = 240
    static let range = 1...86400

    static var interval: TimeInterval {
        let stored = UserDefaults.standard.object(forKey: intervalKey) as? Int ?? defaultInterval
        return TimeInterval(min(max(stored, range.lowerBound), range.upperBound))
    }

    static let moveWhenLockedKey = "moveWhenLocked"

    static var moveWhenLocked: Bool { UserDefaults.standard.bool(forKey: moveWhenLockedKey) }

    static let quitEnabledKey = "quitEnabled"
    static let quitSecondsKey = "quitSeconds"
    static let defaultQuitSeconds = 3600
    static let quitRange = 60...(99 * 3600 + 59 * 60)

    // nil means never quit automatically.
    static var quitAfter: TimeInterval? {
        guard UserDefaults.standard.bool(forKey: quitEnabledKey) else { return nil }
        let stored = UserDefaults.standard.object(forKey: quitSecondsKey) as? Int ?? defaultQuitSeconds
        return TimeInterval(min(max(stored, quitRange.lowerBound), quitRange.upperBound))
    }
}

private enum Unit: Int, CaseIterable, Identifiable {
    case seconds = 1, minutes = 60, hours = 3600

    var id: Int { rawValue }
    var name: String { self == .seconds ? "seconds" : self == .minutes ? "minutes" : "hours" }

    // The largest unit that divides the interval evenly.
    static func best(for seconds: Int) -> Unit {
        allCases.reversed().first { seconds % $0.rawValue == 0 } ?? .seconds
    }
}

struct PreferencesView: View {
    @AppStorage(Prefs.intervalKey) private var seconds = Prefs.defaultInterval
    @State private var unit = Unit.minutes
    @State private var value = 0
    @AppStorage(Prefs.quitEnabledKey) private var quitEnabled = false
    @AppStorage(Prefs.quitSecondsKey) private var quitSeconds = Prefs.defaultQuitSeconds
    @State private var quitHours = 0
    @State private var quitMinutes = 0
    @State private var launchAtLogin = false
    @AppStorage(Prefs.moveWhenLockedKey) private var moveWhenLocked = false
    @State private var accessibilityGranted = AXIsProcessTrusted()

    var body: some View {
        Form {
            Section {
                LabeledContent("Accessibility access") {
                    if accessibilityGranted {
                        Label("Granted", systemImage: "checkmark.circle.fill").foregroundStyle(.green)
                    } else {
                        HStack(spacing: 8) {
                            Label("Not granted", systemImage: "xmark.circle.fill").foregroundStyle(.red)
                            Button("Open Settings") {
                                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
                            }
                        }
                    }
                }
                Toggle("Launch at login", isOn: $launchAtLogin)
            } header: {
                Text("General")
            } footer: {
                Text("Off by default. Starts Mikelito when you log in to your Mac. If the menu bar icon is hidden because the menu bar is full, open Mikelito again to show this window.")
            }

            Section {
                Toggle("Move when the screen is locked", isOn: $moveWhenLocked)
                LabeledContent("Move the mouse every") {
                    HStack(spacing: 6) {
                        TextField("", value: $value, format: .number)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 56)
                        Stepper("", value: $value, in: 1...Prefs.range.upperBound).labelsHidden()
                        Picker("", selection: $unit) {
                            ForEach(Unit.allCases) { Text($0.name).tag($0) }
                        }
                        .labelsHidden()
                        .frame(width: 96)
                    }
                }
            } header: {
                Text("Mouse Nudge")
            } footer: {
                Text("The interval can be 1 second to 24 hours; the default is 4 minutes. While the screen is locked, Mikelito pauses unless the switch above is on.")
            }

            Section {
                LabeledContent("Quit Mikelito now") {
                    Button("Quit") { NSApplication.shared.terminate(nil) }
                }
                Toggle("Quit automatically", isOn: $quitEnabled)
                LabeledContent("After") {
                    HStack(spacing: 6) {
                        TextField("", value: $quitHours, format: .number)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 44)
                        Text("hr")
                        TextField("", value: $quitMinutes, format: .number)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 44)
                        Text("min")
                    }
                }
                .disabled(!quitEnabled)
            } header: {
                Text("Auto Quit")
            } footer: {
                Text("Automatic quit is off by default. The countdown starts at launch, or when you change it.")
            }
        }
        .formStyle(.grouped)
        .frame(width: 460, height: 560)
        .onAppear {
            launchAtLogin = SMAppService.mainApp.status == .enabled
            seconds = min(max(seconds, Prefs.range.lowerBound), Prefs.range.upperBound)
            unit = .best(for: seconds)
            value = seconds / unit.rawValue
            quitSeconds = min(max(quitSeconds, Prefs.quitRange.lowerBound), Prefs.quitRange.upperBound)
            quitHours = quitSeconds / 3600
            quitMinutes = quitSeconds % 3600 / 60
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            accessibilityGranted = AXIsProcessTrusted()
        }
        .onChange(of: launchAtLogin) { setLaunchAtLogin($0) }
        .onChange(of: value) { _ in commit() }
        .onChange(of: unit) { _ in commit() }
        .onChange(of: quitHours) { _ in commitQuit() }
        .onChange(of: quitMinutes) { _ in commitQuit() }
    }

    // The system owns this setting, so a failed change snaps the switch back to what macOS reports.
    private func setLaunchAtLogin(_ on: Bool) {
        let service = SMAppService.mainApp
        guard (service.status == .enabled) != on else { return }
        do {
            if on { try service.register() } else { try service.unregister() }
        } catch {
            launchAtLogin = service.status == .enabled
        }
    }

    private func commit() {
        let clamped = min(max(value * unit.rawValue, Prefs.range.lowerBound), Prefs.range.upperBound)
        seconds = clamped
        if clamped != value * unit.rawValue { value = clamped / unit.rawValue }
    }

    // Normalises (for example 90 minutes becomes 1 hour 30 minutes) and keeps the time within range.
    private func commitQuit() {
        let total = min(max(quitHours * 3600 + quitMinutes * 60, Prefs.quitRange.lowerBound), Prefs.quitRange.upperBound)
        quitSeconds = total
        if (quitHours, quitMinutes) != (total / 3600, total % 3600 / 60) {
            (quitHours, quitMinutes) = (total / 3600, total % 3600 / 60)
        }
    }
}
