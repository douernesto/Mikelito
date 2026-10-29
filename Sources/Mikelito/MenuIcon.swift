import AppKit

enum MenuIcon {
    // A template "M": plain letter when off, knocked out of a solid badge when on.
    static func image(on: Bool) -> NSImage {
        let image = NSImage(size: NSSize(width: 18, height: 18), flipped: false) { rect in
            let letter = NSAttributedString(string: "M", attributes: [
                .font: NSFont.systemFont(ofSize: 13, weight: .heavy),
                .foregroundColor: NSColor.black,
            ])
            let size = letter.size()
            let origin = NSPoint(x: rect.midX - size.width / 2, y: rect.midY - size.height / 2)
            if on {
                NSColor.black.setFill()
                NSBezierPath(roundedRect: rect.insetBy(dx: 0.5, dy: 0.5), xRadius: 4, yRadius: 4).fill()
                NSGraphicsContext.current?.compositingOperation = .destinationOut
            }
            letter.draw(at: origin)
            return true
        }
        image.isTemplate = true
        return image
    }
}
