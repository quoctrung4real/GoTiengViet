import Cocoa
import Carbon

/// A view that records a keyboard shortcut combination
/// Click to start recording, press the desired key combo, it auto-saves
class HotkeyRecorderView: NSView {

    /// The current hotkey configuration
    var keyCode: UInt32 = 49  // Default: Space
    var modifierFlags: UInt32 = UInt32(controlKey)  // Default: Ctrl

    /// Callback when hotkey changes
    var onHotkeyChanged: ((UInt32, UInt32) -> Void)?

    /// Whether we're actively recording
    private var isRecording = false

    /// Display label
    private let label = NSTextField(labelWithString: "")

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
        layer?.cornerRadius = 8
        layer?.borderWidth = 1

        label.frame = bounds.insetBy(dx: 12, dy: 4)
        label.autoresizingMask = [.width, .height]
        label.alignment = .center
        label.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        addSubview(label)

        // Load saved hotkey
        loadSavedHotkey()
        updateDisplay()

        // Add click gesture
        let click = NSClickGestureRecognizer(target: self, action: #selector(startRecording(_:)))
        addGestureRecognizer(click)
    }

    private func loadSavedHotkey() {
        let defaults = UserDefaults.standard
        if let data = defaults.data(forKey: AppConstants.Prefs.switchHotkey),
           let saved = try? JSONDecoder().decode(SavedHotkey.self, from: data) {
            keyCode = saved.keyCode
            modifierFlags = saved.modifierFlags
        }
    }

    private func saveHotkey() {
        let saved = SavedHotkey(keyCode: keyCode, modifierFlags: modifierFlags)
        if let data = try? JSONEncoder().encode(saved) {
            UserDefaults.standard.set(data, forKey: AppConstants.Prefs.switchHotkey)
        }
    }

    struct SavedHotkey: Codable {
        let keyCode: UInt32
        let modifierFlags: UInt32
    }

    // MARK: - Recording

    @objc private func startRecording(_ sender: Any?) {
        isRecording = true
        label.stringValue = "Nhấn phím tắt mới..."
        label.textColor = NSColor.systemRed
        updateAppearance()

        // Become first responder to capture key events
        window?.makeFirstResponder(self)
    }

    override var acceptsFirstResponder: Bool { return true }

    override func keyDown(with event: NSEvent) {
        guard isRecording else {
            super.keyDown(with: event)
            return
        }

        // Capture the key + modifiers
        let newKeyCode = UInt32(event.keyCode)
        var newModifiers: UInt32 = 0

        if event.modifierFlags.contains(.control) {
            newModifiers |= UInt32(controlKey)
        }
        if event.modifierFlags.contains(.option) {
            newModifiers |= UInt32(optionKey)
        }
        if event.modifierFlags.contains(.command) {
            newModifiers |= UInt32(cmdKey)
        }
        if event.modifierFlags.contains(.shift) {
            newModifiers |= UInt32(shiftKey)
        }

        // Must have at least one modifier
        guard newModifiers != 0 else {
            label.stringValue = "Cần ít nhất 1 phím modifier (Ctrl/Opt/Cmd)"
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                self?.updateDisplay()
            }
            return
        }

        // Save and apply
        keyCode = newKeyCode
        modifierFlags = newModifiers
        isRecording = false

        saveHotkey()
        updateDisplay()
        onHotkeyChanged?(keyCode, modifierFlags)
    }

    override func flagsChanged(with event: NSEvent) {
        // Don't process modifier-only presses
        super.flagsChanged(with: event)
    }

    // Escape cancels recording
    override func cancelOperation(_ sender: Any?) {
        if isRecording {
            isRecording = false
            updateDisplay()
        }
    }

    // MARK: - Display

    private func updateDisplay() {
        label.stringValue = hotkeyDisplayString()
        label.textColor = NSColor.labelColor
        updateAppearance()
    }

    private func updateAppearance() {
        let isDark = effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        if isRecording {
            layer?.backgroundColor = isDark
                ? NSColor.systemRed.withAlphaComponent(0.15).cgColor
                : NSColor.systemRed.withAlphaComponent(0.08).cgColor
            layer?.borderColor = NSColor.systemRed.withAlphaComponent(0.5).cgColor
        } else {
            layer?.backgroundColor = isDark
                ? NSColor(white: 1.0, alpha: 0.08).cgColor
                : NSColor(white: 0.0, alpha: 0.04).cgColor
            layer?.borderColor = isDark
                ? NSColor(white: 1.0, alpha: 0.12).cgColor
                : NSColor(white: 0.0, alpha: 0.1).cgColor
        }
    }

    /// Generate a human-readable string for the current hotkey
    func hotkeyDisplayString() -> String {
        var parts: [String] = []

        if modifierFlags & UInt32(controlKey) != 0 { parts.append("⌃") }
        if modifierFlags & UInt32(optionKey) != 0 { parts.append("⌥") }
        if modifierFlags & UInt32(shiftKey) != 0 { parts.append("⇧") }
        if modifierFlags & UInt32(cmdKey) != 0 { parts.append("⌘") }

        parts.append(keyCodeToString(keyCode))

        return parts.joined()
    }

    /// Convert a key code to a display string
    private func keyCodeToString(_ code: UInt32) -> String {
        switch Int(code) {
        case kVK_Space: return "Space"
        case kVK_Return: return "↩"
        case kVK_Tab: return "⇥"
        case kVK_Delete: return "⌫"
        case kVK_Escape: return "⎋"
        case kVK_F1: return "F1"
        case kVK_F2: return "F2"
        case kVK_F3: return "F3"
        case kVK_F4: return "F4"
        case kVK_F5: return "F5"
        case kVK_F6: return "F6"
        case kVK_F7: return "F7"
        case kVK_F8: return "F8"
        case kVK_F9: return "F9"
        case kVK_F10: return "F10"
        case kVK_F11: return "F11"
        case kVK_F12: return "F12"
        case kVK_ANSI_A: return "A"
        case kVK_ANSI_B: return "B"
        case kVK_ANSI_C: return "C"
        case kVK_ANSI_D: return "D"
        case kVK_ANSI_E: return "E"
        case kVK_ANSI_F: return "F"
        case kVK_ANSI_G: return "G"
        case kVK_ANSI_H: return "H"
        case kVK_ANSI_I: return "I"
        case kVK_ANSI_J: return "J"
        case kVK_ANSI_K: return "K"
        case kVK_ANSI_L: return "L"
        case kVK_ANSI_M: return "M"
        case kVK_ANSI_N: return "N"
        case kVK_ANSI_O: return "O"
        case kVK_ANSI_P: return "P"
        case kVK_ANSI_Q: return "Q"
        case kVK_ANSI_R: return "R"
        case kVK_ANSI_S: return "S"
        case kVK_ANSI_T: return "T"
        case kVK_ANSI_U: return "U"
        case kVK_ANSI_V: return "V"
        case kVK_ANSI_W: return "W"
        case kVK_ANSI_X: return "X"
        case kVK_ANSI_Y: return "Y"
        case kVK_ANSI_Z: return "Z"
        case kVK_ANSI_0: return "0"
        case kVK_ANSI_1: return "1"
        case kVK_ANSI_2: return "2"
        case kVK_ANSI_3: return "3"
        case kVK_ANSI_4: return "4"
        case kVK_ANSI_5: return "5"
        case kVK_ANSI_6: return "6"
        case kVK_ANSI_7: return "7"
        case kVK_ANSI_8: return "8"
        case kVK_ANSI_9: return "9"
        default: return "Key\(code)"
        }
    }
}
