import SwiftUI

@main
struct MikelitoApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @StateObject private var mover = MouseMover()

    init() {
        AutoQuit.shared.start()
    }

    var body: some Scene {
        MenuBarExtra {
            Button { PreferencesWindow.show() } label: { Label("Preferences…", systemImage: "gearshape") }.keyboardShortcut(",")
            Divider()
            Button("About Mikelito") { showAbout() }
            Button("Quit Mikelito") { NSApplication.shared.terminate(nil) }
                .keyboardShortcut("q")
        } label: {
            Image(nsImage: MenuIcon.image(on: mover.isOn))
        }
    }

    private func showAbout() {
        let credits = NSMutableAttributedString(
            string: "A tiny menu bar app that gently moves your mouse pointer while you are away from the keyboard.\n\n",
            attributes: [.font: NSFont.systemFont(ofSize: 11), .foregroundColor: NSColor.labelColor])
        credits.append(NSAttributedString(
            string: "github.com/douernesto/Mikelito",
            attributes: [.font: NSFont.systemFont(ofSize: 11),
                         .link: URL(string: "https://github.com/douernesto/Mikelito")!]))
        credits.addAttribute(.paragraphStyle, value: {
            let style = NSMutableParagraphStyle(); style.alignment = .center; return style
        }(), range: NSRange(location: 0, length: credits.length))
        NSApplication.shared.activate(ignoringOtherApps: true)
        NSApplication.shared.orderFrontStandardAboutPanel(options: [.credits: credits])
    }
}
