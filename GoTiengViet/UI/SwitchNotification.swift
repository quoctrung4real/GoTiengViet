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
        let windowSize = NSSize(width: 160, height: 48)

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

        // Create content view using Visual Effect
        let effectView = NSVisualEffectView(frame: NSRect(origin: .zero, size: windowSize))
        effectView.blendingMode = .behindWindow
        effectView.material = .hudWindow
        effectView.state = .active
        effectView.wantsLayer = true
        effectView.layer?.cornerRadius = 16
        effectView.layer?.masksToBounds = true
        effectView.layer?.borderWidth = 1
        effectView.layer?.borderColor = NSColor(white: 1.0, alpha: 0.1).cgColor

        // Stack view for contents
        let stack = NSStackView()
        stack.orientation = .horizontal
        stack.alignment = .centerY
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false

        // Flag
        let flagLabel = NSTextField(labelWithString: isVietnamese ? "🇻🇳" : "🇬🇧")
        flagLabel.font = NSFont.systemFont(ofSize: 24)
        stack.addArrangedSubview(flagLabel)

        // Text
        let textLabel = NSTextField(labelWithString: isVietnamese ? "Tiếng Việt" : "English")
        textLabel.font = NSFont.systemFont(ofSize: 15, weight: .semibold)
        textLabel.textColor = .white // HUD material is always dark
        stack.addArrangedSubview(textLabel)

        effectView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: effectView.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: effectView.centerYAnchor)
        ])

        window.contentView = effectView

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
