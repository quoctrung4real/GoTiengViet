import Cocoa

/// Visual OSD (On-Screen Display) notification when switching Vietnamese/English mode
/// Shows a floating glass-style overlay near the cursor for 1 second
class SwitchNotification {

    /// Shared singleton
    static let shared = SwitchNotification()

    /// The notification window
    private var overlayWindow: NSWindow?

    /// Dismiss timer
    private var dismissTimer: Timer?

    private init() {}

    // MARK: - Show Notification

    /// Show the mode switch notification
    /// - Parameter isVietnamese: Whether Vietnamese mode is now active
    func show(isVietnamese: Bool) {
        guard PreferencesManager.shared.osdEnabled else { return }

        // Cancel any existing timer
        dismissTimer?.invalidate()
        overlayWindow?.orderOut(nil)

        // Create the notification window
        let windowSize = NSSize(width: 180, height: 56)

        // Position near the mouse cursor
        let mouseLocation = NSEvent.mouseLocation
        let windowOrigin = NSPoint(
            x: mouseLocation.x - windowSize.width / 2,
            y: mouseLocation.y + 20
        )

        let window = NSWindow(
            contentRect: NSRect(origin: windowOrigin, size: windowSize),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        window.level = .floating
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.ignoresMouseEvents = true
        window.collectionBehavior = [.canJoinAllSpaces, .stationary]

        // Create content view
        let contentView = OSDContentView(frame: NSRect(origin: .zero, size: windowSize))
        contentView.isVietnamese = isVietnamese
        window.contentView = contentView

        // Show with fade-in animation
        window.alphaValue = 0.0
        window.orderFront(nil)

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.15
            window.animator().alphaValue = 1.0
        }

        overlayWindow = window

        // Auto-dismiss after 1 second
        dismissTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { [weak self] _ in
            self?.dismiss()
        }
    }

    /// Dismiss the notification with fade-out
    private func dismiss() {
        guard let window = overlayWindow else { return }

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.3
            window.animator().alphaValue = 0.0
        }, completionHandler: { [weak self] in
            window.orderOut(nil)
            self?.overlayWindow = nil
        })
    }
}

// MARK: - OSD Content View

/// The visual content of the OSD notification
/// Liquid Glass design with flag icon and mode text
private class OSDContentView: NSView {

    var isVietnamese: Bool = true

    override func draw(_ dirtyRect: NSRect) {
        guard NSGraphicsContext.current != nil else { return }

        let isDark = effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua

        // Background — rounded rect with glass effect
        let bgRect = bounds.insetBy(dx: 2, dy: 2)
        let bgPath = NSBezierPath(roundedRect: bgRect, xRadius: 14, yRadius: 14)

        if isDark {
            NSColor(white: 0.15, alpha: 0.9).setFill()
        } else {
            NSColor(white: 0.95, alpha: 0.95).setFill()
        }
        bgPath.fill()

        // Border
        if isDark {
            NSColor(white: 1.0, alpha: 0.15).setStroke()
        } else {
            NSColor(white: 0.0, alpha: 0.1).setStroke()
        }
        bgPath.lineWidth = 0.5
        bgPath.stroke()

        // Flag + Text
        let flag = isVietnamese ? "🇻🇳" : "🇬🇧"
        let label = isVietnamese ? "Tiếng Việt" : "English"

        // Draw flag
        let flagFont = NSFont.systemFont(ofSize: 24)
        let flagAttrs: [NSAttributedString.Key: Any] = [.font: flagFont]
        let flagStr = NSAttributedString(string: flag, attributes: flagAttrs)
        let flagSize = flagStr.size()
        let flagRect = NSRect(
            x: 16,
            y: (bounds.height - flagSize.height) / 2,
            width: flagSize.width,
            height: flagSize.height
        )
        flagStr.draw(in: flagRect)

        // Draw label
        let labelFont = NSFont.systemFont(ofSize: 16, weight: .semibold)
        let labelColor = isDark ? NSColor.white : NSColor.black
        let labelAttrs: [NSAttributedString.Key: Any] = [
            .font: labelFont,
            .foregroundColor: labelColor
        ]
        let labelStr = NSAttributedString(string: label, attributes: labelAttrs)
        let labelSize = labelStr.size()
        let labelRect = NSRect(
            x: flagRect.maxX + 10,
            y: (bounds.height - labelSize.height) / 2,
            width: labelSize.width,
            height: labelSize.height
        )
        labelStr.draw(in: labelRect)
    }
}
