import Cocoa

/// Candidate window for autocomplete suggestions
/// Displays a floating panel near the cursor with selectable word suggestions
class CandidateWindow {

    /// Shared singleton
    static let shared = CandidateWindow()

    /// The floating window
    private var window: NSWindow?

    /// Currently displayed candidates
    private var candidates: [String] = []

    /// Currently selected index
    private var selectedIndex: Int = 0

    /// Callback when a candidate is selected
    var onSelect: ((String) -> Void)?

    private init() {}

    // MARK: - Show / Hide

    /// Show candidates at the given screen position
    /// - Parameters:
    ///   - suggestions: Array of word suggestions
    ///   - position: Screen position (near the cursor)
    func show(suggestions: [String], at position: NSPoint) {
        guard !suggestions.isEmpty else {
            hide()
            return
        }

        candidates = suggestions
        selectedIndex = 0

        let rowHeight: CGFloat = 28
        let windowWidth: CGFloat = 220
        let windowHeight = CGFloat(min(suggestions.count, 8)) * rowHeight + 8

        let windowOrigin = NSPoint(
            x: position.x,
            y: position.y - windowHeight - 4
        )

        // Create or reuse window
        if window == nil {
            let w = NSWindow(
                contentRect: NSRect(origin: windowOrigin, size: NSSize(width: windowWidth, height: windowHeight)),
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )
            w.level = .floating
            w.isOpaque = false
            w.backgroundColor = .clear
            w.hasShadow = true
            w.ignoresMouseEvents = false
            w.collectionBehavior = [.canJoinAllSpaces, .stationary]
            window = w
        }

        window?.setFrame(NSRect(origin: windowOrigin, size: NSSize(width: windowWidth, height: windowHeight)), display: true)

        // Build content
        let contentView = CandidateContentView(frame: NSRect(origin: .zero, size: NSSize(width: windowWidth, height: windowHeight)))
        contentView.candidates = candidates
        contentView.selectedIndex = selectedIndex
        contentView.onSelect = { [weak self] index in
            self?.selectCandidate(at: index)
        }
        window?.contentView = contentView

        window?.orderFront(nil)
    }

    /// Hide the candidate window
    func hide() {
        window?.orderOut(nil)
        candidates = []
        selectedIndex = 0
    }

    /// Whether the window is currently visible
    var isVisible: Bool {
        return window?.isVisible ?? false
    }

    // MARK: - Navigation

    /// Move selection up
    func moveUp() {
        guard !candidates.isEmpty else { return }
        selectedIndex = (selectedIndex - 1 + candidates.count) % candidates.count
        updateSelection()
    }

    /// Move selection down
    func moveDown() {
        guard !candidates.isEmpty else { return }
        selectedIndex = (selectedIndex + 1) % candidates.count
        updateSelection()
    }

    /// Select the current candidate
    /// - Returns: The selected word, or nil if no selection
    func selectCurrent() -> String? {
        guard !candidates.isEmpty, selectedIndex < candidates.count else { return nil }
        let word = candidates[selectedIndex]
        hide()
        return word
    }

    /// Select candidate at index
    func selectCandidate(at index: Int) {
        guard index < candidates.count else { return }
        let word = candidates[index]
        hide()
        onSelect?(word)
    }

    private func updateSelection() {
        guard let contentView = window?.contentView as? CandidateContentView else { return }
        contentView.selectedIndex = selectedIndex
        contentView.needsDisplay = true
    }
}

// MARK: - Candidate Content View

/// The visual content of the candidate window
private class CandidateContentView: NSView {

    var candidates: [String] = []
    var selectedIndex: Int = 0
    var onSelect: ((Int) -> Void)?

    private let rowHeight: CGFloat = 28

    override func draw(_ dirtyRect: NSRect) {
        guard NSGraphicsContext.current != nil else { return }

        let isDark = effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua

        // Background
        let bgPath = NSBezierPath(roundedRect: bounds.insetBy(dx: 1, dy: 1), xRadius: 10, yRadius: 10)
        if isDark {
            NSColor(white: 0.12, alpha: 0.95).setFill()
        } else {
            NSColor(white: 0.98, alpha: 0.98).setFill()
        }
        bgPath.fill()

        // Border
        if isDark {
            NSColor(white: 1.0, alpha: 0.12).setStroke()
        } else {
            NSColor(white: 0.0, alpha: 0.08).setStroke()
        }
        bgPath.lineWidth = 0.5
        bgPath.stroke()

        // Draw each candidate row
        let font = NSFont.systemFont(ofSize: 13)
        let indexFont = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .regular)

        for (i, candidate) in candidates.enumerated() {
            let y = bounds.height - CGFloat(i + 1) * rowHeight
            let rowRect = NSRect(x: 4, y: y, width: bounds.width - 8, height: rowHeight)

            // Highlight selected row
            if i == selectedIndex {
                let highlightPath = NSBezierPath(roundedRect: rowRect.insetBy(dx: 2, dy: 1), xRadius: 6, yRadius: 6)
                NSColor.controlAccentColor.withAlphaComponent(isDark ? 0.35 : 0.2).setFill()
                highlightPath.fill()
            }

            // Index number (1-9)
            let indexStr = NSAttributedString(string: "\(i + 1)", attributes: [
                .font: indexFont,
                .foregroundColor: isDark ? NSColor(white: 1.0, alpha: 0.4) : NSColor(white: 0.0, alpha: 0.35)
            ])
            indexStr.draw(at: NSPoint(x: rowRect.minX + 8, y: y + 6))

            // Candidate text
            let textColor = i == selectedIndex
                ? (isDark ? NSColor.white : NSColor.black)
                : (isDark ? NSColor(white: 1.0, alpha: 0.85) : NSColor(white: 0.0, alpha: 0.8))
            let textAttrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: textColor
            ]
            let textStr = NSAttributedString(string: candidate, attributes: textAttrs)
            textStr.draw(at: NSPoint(x: rowRect.minX + 28, y: y + 5))
        }
    }

    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        let index = Int((bounds.height - point.y) / rowHeight)
        if index >= 0 && index < candidates.count {
            onSelect?(index)
        }
    }
}
