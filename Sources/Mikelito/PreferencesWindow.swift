import SwiftUI

@MainActor
enum PreferencesWindow {
    private static var window: NSWindow?

    static func show() {
        if window == nil {
            // Size the window once from the content. Letting SwiftUI keep resizing it loops forever
            // because the wrapping captions change height with the width, and AppKit throws.
            let host = NSHostingController(rootView: PreferencesView())
            host.sizingOptions = []
            let new = NSWindow(contentViewController: host)
            new.setContentSize(host.sizeThatFits(in: CGSize(width: 460, height: 10_000)))
            new.title = "Mikelito Preferences"
            new.styleMask = [.titled, .closable]
            new.isReleasedWhenClosed = false
            new.center()
            window = new
        }
        NSApplication.shared.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }
}
