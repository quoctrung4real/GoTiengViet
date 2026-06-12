import Cocoa
import Carbon

/// Manages global hotkey registration for switching Vietnamese/English mode
class HotkeyManager {

    /// Shared singleton
    static let shared = HotkeyManager()

    /// The registered hotkey event handler
    private var eventHandler: EventHandlerRef?

    /// Callback for when the hotkey is triggered
    var onHotkeyTriggered: (() -> Void)?

    private init() {}

    // MARK: - Registration

    /// Register the default hotkey (Ctrl+Space)
    func registerDefaultHotkey() {
        // Ctrl + Space
        registerHotkey(keyCode: 49, modifiers: UInt32(controlKey))
    }

    /// Register a custom hotkey
    /// - Parameters:
    ///   - keyCode: The key code
    ///   - modifiers: The modifier flags
    func registerHotkey(keyCode: UInt32, modifiers: UInt32) {
        // Unregister any existing hotkey
        unregisterHotkey()

        var hotKeyRef: EventHotKeyRef?
        let hotKeyID = EventHotKeyID(signature: OSType(0x4754_5656), // "GTVV"
                                       id: 1)

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        // Install event handler
        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, event, _) -> OSStatus in
                HotkeyManager.shared.onHotkeyTriggered?()
                return noErr
            },
            1,
            &eventType,
            nil,
            &eventHandler
        )

        guard status == noErr else {
            Log.error("Failed to install hotkey event handler: \(status)")
            return
        }

        // Register the hotkey
        let registerStatus = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        if registerStatus == noErr {
            Log.info("Hotkey registered: keyCode=\(keyCode), modifiers=\(modifiers)")
        } else {
            Log.error("Failed to register hotkey: \(registerStatus)")
        }
    }

    /// Unregister the current hotkey
    func unregisterHotkey() {
        if let handler = eventHandler {
            RemoveEventHandler(handler)
            eventHandler = nil
        }
    }

    deinit {
        unregisterHotkey()
    }
}
