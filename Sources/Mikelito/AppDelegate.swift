import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    // Opening the app again while it runs shows Preferences, for when the menu bar has no room for its icon.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        PreferencesWindow.show()
        return true
    }
}
