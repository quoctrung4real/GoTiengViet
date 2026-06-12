import Cocoa

// MARK: - Glass Card View

/// A custom view with Liquid Glass aesthetic
/// Features: multi-layer blur, subtle border gradient, inner shadow, rounded corners
class GlassCardView: NSView {

    var cornerRadius: CGFloat = 12.0
    var borderWidth: CGFloat = 1.0
    var borderAlpha: CGFloat = 0.15

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        wantsLayer = true
        layer?.cornerRadius = cornerRadius
        layer?.masksToBounds = true
    }

    override func updateLayer() {
        super.updateLayer()

        guard let layer = self.layer else { return }

        // Glass background
        let isDark = effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua

        if isDark {
            layer.backgroundColor = NSColor(white: 1.0, alpha: 0.06).cgColor
        } else {
            layer.backgroundColor = NSColor(white: 1.0, alpha: 0.45).cgColor
        }

        // Subtle border
        layer.borderWidth = borderWidth
        if isDark {
            layer.borderColor = NSColor(white: 1.0, alpha: borderAlpha).cgColor
        } else {
            layer.borderColor = NSColor(white: 0.0, alpha: 0.08).cgColor
        }

        // Shadow
        layer.shadowColor = NSColor.black.withAlphaComponent(0.1).cgColor
        layer.shadowOffset = CGSize(width: 0, height: -1)
        layer.shadowRadius = 4
        layer.shadowOpacity = 1.0
    }

    override var allowsVibrancy: Bool { return true }
}

// MARK: - Glass Toggle

/// A toggle switch with Liquid Glass styling
/// Capsule shape, frosted track, solid accent thumb
class GlassToggle: NSButton {

    var isOn: Bool = false {
        didSet {
            needsDisplay = true
            onToggle?(isOn)
        }
    }

    /// Callback when toggled
    var onToggle: ((Bool) -> Void)?

    private let trackWidth: CGFloat = 44
    private let trackHeight: CGFloat = 24
    private let thumbSize: CGFloat = 20

    override init(frame frameRect: NSRect) {
        super.init(frame: NSRect(x: frameRect.origin.x, y: frameRect.origin.y,
                                  width: trackWidth, height: trackHeight))
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        isBordered = false
        title = ""
        bezelStyle = .inline
        setButtonType(.toggle)
        wantsLayer = true
        target = self
        action = #selector(toggled(_:))
    }

    @objc private func toggled(_ sender: Any?) {
        isOn.toggle()
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }

        let isDark = effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua

        // Track
        let trackRect = NSRect(
            x: (bounds.width - trackWidth) / 2,
            y: (bounds.height - trackHeight) / 2,
            width: trackWidth,
            height: trackHeight
        )
        let trackPath = CGPath(roundedRect: trackRect, cornerWidth: trackHeight / 2,
                                cornerHeight: trackHeight / 2, transform: nil)

        if isOn {
            // Active track — system accent color with glass
            context.setFillColor(NSColor.controlAccentColor.withAlphaComponent(0.85).cgColor)
        } else {
            // Inactive track — frosted glass
            if isDark {
                context.setFillColor(NSColor(white: 1.0, alpha: 0.12).cgColor)
            } else {
                context.setFillColor(NSColor(white: 0.0, alpha: 0.08).cgColor)
            }
        }
        context.addPath(trackPath)
        context.fillPath()

        // Track border
        context.setStrokeColor(NSColor(white: isDark ? 1.0 : 0.0, alpha: 0.1).cgColor)
        context.setLineWidth(0.5)
        context.addPath(trackPath)
        context.strokePath()

        // Thumb
        let thumbX: CGFloat = isOn
            ? trackRect.maxX - thumbSize - 2
            : trackRect.minX + 2
        let thumbY = trackRect.minY + (trackHeight - thumbSize) / 2
        let thumbRect = NSRect(x: thumbX, y: thumbY, width: thumbSize, height: thumbSize)
        let thumbPath = CGPath(ellipseIn: thumbRect, transform: nil)

        // Thumb fill — solid white with subtle shadow
        context.setShadow(offset: CGSize(width: 0, height: -1), blur: 2,
                          color: NSColor.black.withAlphaComponent(0.15).cgColor)
        context.setFillColor(NSColor.white.cgColor)
        context.addPath(thumbPath)
        context.fillPath()

        context.setShadow(offset: .zero, blur: 0) // Reset shadow
    }

    override var intrinsicContentSize: NSSize {
        return NSSize(width: trackWidth, height: trackHeight)
    }
}

// MARK: - Glass Dropdown

/// A dropdown/popup button with Liquid Glass styling
class GlassDropdown: NSPopUpButton {

    override init(frame buttonFrame: NSRect, pullsDown flag: Bool) {
        super.init(frame: buttonFrame, pullsDown: flag)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        bezelStyle = .texturedRounded
        isBordered = true
        wantsLayer = true
        layer?.cornerRadius = 8

        // Use system font
        font = NSFont.systemFont(ofSize: 13, weight: .regular)
    }

    override func updateLayer() {
        super.updateLayer()

        let isDark = effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua

        if isDark {
            layer?.backgroundColor = NSColor(white: 1.0, alpha: 0.08).cgColor
            layer?.borderColor = NSColor(white: 1.0, alpha: 0.12).cgColor
        } else {
            layer?.backgroundColor = NSColor(white: 1.0, alpha: 0.6).cgColor
            layer?.borderColor = NSColor(white: 0.0, alpha: 0.08).cgColor
        }
        layer?.borderWidth = 0.5
    }
}

// MARK: - Glass Section Header

/// A section header label with Liquid Glass styling
class GlassSectionHeader: NSTextField {

    convenience init(title: String) {
        self.init(labelWithString: title)
        setup()
    }

    private func setup() {
        font = NSFont.systemFont(ofSize: 11, weight: .semibold)
        textColor = NSColor.secondaryLabelColor
        isEditable = false
        isBordered = false
        drawsBackground = false
    }
}

// MARK: - Glass Separator

/// A subtle separator line
class GlassSeparator: NSView {

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        wantsLayer = true
    }

    override func updateLayer() {
        let isDark = effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        layer?.backgroundColor = isDark
            ? NSColor(white: 1.0, alpha: 0.08).cgColor
            : NSColor(white: 0.0, alpha: 0.06).cgColor
    }

    override var intrinsicContentSize: NSSize {
        return NSSize(width: NSView.noIntrinsicMetric, height: 1)
    }
}
