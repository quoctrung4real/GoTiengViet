import Cocoa
import InputMethodKit

/// Main Input Method Controller
/// Subclass of IMKInputController — handles all keyboard events from the system
///
/// ## Critical Architecture Notes:
/// - All client interactions MUST be synchronous on the main thread
/// - Never hold references to `client` beyond the scope of a method call
/// - Always clear marked text before calling insertText
/// - Return `true` from handle() if the event was consumed, `false` to pass through
class InputController: IMKInputController {

    // MARK: - Properties

    /// The Vietnamese engine instance
    private let engine: VietnameseEngine

    /// Composition buffer for managing marked/committed text
    private let compositionBuffer = CompositionBuffer()

    /// Secure field handler
    private let secureFieldHandler = SecureFieldHandler()

    /// Client app detector
    private let appDetector = ClientAppDetector()

    /// Preferences manager reference
    private let prefs = PreferencesManager.shared

    // MARK: - Initialization

    override init!(server: IMKServer!, delegate: Any!, client inputClient: Any!) {
        // Initialize engine with saved preferences
        self.engine = VietnameseEngine(
            inputMethod: PreferencesManager.shared.inputMethod,
            toneStyle: PreferencesManager.shared.toneStyle
        )

        super.init(server: server, delegate: delegate, client: inputClient)

        // Apply saved preferences
        applyPreferences()

        Log.input("InputController initialized")
    }

    // MARK: - IMKInputController Lifecycle

    override func activateServer(_ sender: Any!) {
        super.activateServer(sender)

        let client = sender as? IMKTextInput

        // Detect client app
        if let textInput = client {
            let bundleId = textInput.bundleIdentifier()
            appDetector.updateCurrentApp(bundleId: bundleId)
        }

        // Check for secure field
        if secureFieldHandler.isSecureField(client: client) {
            secureFieldHandler.enterSecureField(currentVietnameseState: engine.isVietnameseEnabled)
            engine.isVietnameseEnabled = false
            Log.security("Secure field detected — Vietnamese disabled")
        } else if secureFieldHandler.isInSecureField {
            // We were in a secure field but now we're not
            let restoreState = secureFieldHandler.leaveSecureField()
            engine.isVietnameseEnabled = restoreState
        }

        // Apply per-app settings
        if let perAppMode = appDetector.getVietnameseMode() {
            engine.isVietnameseEnabled = perAppMode
        }

        // Sync engine with current preferences
        applyPreferences()

        Log.input("Server activated. Vietnamese: \(engine.isVietnameseEnabled)")
    }

    override func deactivateServer(_ sender: Any!) {
        // Commit any pending composition
        if engine.hasComposition {
            let result = engine.forceCommit()
            handleEngineResult(result, client: sender as? IMKTextInput)
        }

        compositionBuffer.reset()
        secureFieldHandler.reset()

        super.deactivateServer(sender)
        Log.input("Server deactivated")
    }

    // MARK: - Event Handling

    override func handle(_ event: NSEvent!, client sender: Any!) -> Bool {
        guard let event = event else { return false }
        let client = sender as? IMKTextInput

        // Only handle key down events
        guard event.type == .keyDown else { return false }

        // Re-check secure field on every keystroke (field focus can change)
        if secureFieldHandler.bypassEnabled {
            let isSecure = secureFieldHandler.isSecureField(client: sender)
            if isSecure && !secureFieldHandler.isInSecureField {
                // Entering secure field — commit and disable
                if engine.hasComposition {
                    let result = engine.forceCommit()
                    handleEngineResult(result, client: client)
                }
                secureFieldHandler.enterSecureField(currentVietnameseState: engine.isVietnameseEnabled)
                engine.isVietnameseEnabled = false
                return false  // Pass through all keystrokes
            } else if !isSecure && secureFieldHandler.isInSecureField {
                let restoreState = secureFieldHandler.leaveSecureField()
                engine.isVietnameseEnabled = restoreState
            }
        }

        // If in secure field, pass through everything
        if secureFieldHandler.isInSecureField {
            return false
        }

        // If Vietnamese is disabled, pass through
        if !engine.isVietnameseEnabled {
            return false
        }

        // Check modifier keys — pass through if Cmd, Ctrl, or Option is held
        let modifiers = event.modifierFlags
        if modifiers.contains(.command) || modifiers.contains(.control) ||
           modifiers.contains(.option) {
            // Commit any pending composition first
            if engine.hasComposition {
                let result = engine.forceCommit()
                handleEngineResult(result, client: client)
            }
            return false
        }

        // Handle special keys
        let keyCode = event.keyCode

        // Backspace
        if keyCode == 51 {
            return handleBackspace(client: client)
        }

        // Escape — cancel composition
        if keyCode == 53 {
            return handleEscape(client: client)
        }

        // Return/Enter — commit composition
        if keyCode == 36 || keyCode == 76 {
            if engine.hasComposition {
                let result = engine.forceCommit()
                handleEngineResult(result, client: client)
                // Don't consume the enter key — let it pass through
                return false
            }
            return false
        }

        // Arrow keys — commit and pass through
        if keyCode >= 123 && keyCode <= 126 {
            if engine.hasComposition {
                let result = engine.forceCommit()
                handleEngineResult(result, client: client)
            }
            return false
        }

        // Tab — commit and pass through
        if keyCode == 48 {
            if engine.hasComposition {
                let result = engine.forceCommit()
                handleEngineResult(result, client: client)
            }
            return false
        }

        // Get the typed character
        guard let chars = event.characters, let char = chars.first else {
            return false
        }

        // Process the character through the Vietnamese engine
        let result = engine.processKey(char)
        return handleEngineResult(result, client: client)
    }

    // MARK: - Engine Result Handling

    /// Process the result from the Vietnamese engine
    /// - Returns: true if the event was consumed, false to pass through
    @discardableResult
    private func handleEngineResult(_ result: EngineResult, client: IMKTextInput?) -> Bool {
        switch result {
        case .nothing:
            return false

        case .compositionUpdated(let text):
            compositionBuffer.updateComposition(text, client: client)
            return true

        case .compositionCleared:
            compositionBuffer.clearComposition(client: client)
            return true

        case .commitText(let text):
            compositionBuffer.commitText(text, client: client)
            return true

        case .commitAndPassthrough(let text):
            compositionBuffer.commitText(text, client: client)
            return false  // Let the triggering key pass through

        case .passthrough:
            return false
        }
    }

    // MARK: - Special Key Handlers

    private func handleBackspace(client: IMKTextInput?) -> Bool {
        if !engine.hasComposition {
            return false  // No composition — let system handle backspace
        }

        let result = engine.processBackspace()
        return handleEngineResult(result, client: client)
    }

    private func handleEscape(client: IMKTextInput?) -> Bool {
        if engine.hasComposition {
            engine.resetBuffer()
            compositionBuffer.clearComposition(client: client)
            return true
        }
        return false
    }

    // MARK: - Candidates (not used currently but required by IMK)

    override func candidates(_ sender: Any!) -> [Any]! {
        return nil  // We don't use candidate windows
    }

    // MARK: - Menu

    override func menu() -> NSMenu! {
        return StatusBarManager.shared?.createInputMenu()
    }

    // MARK: - Preferences Sync

    private func applyPreferences() {
        engine.inputMethod = prefs.inputMethod
        engine.tonePlacement.style = prefs.toneStyle
        engine.spellCheckEnabled = prefs.spellCheckEnabled
        engine.autoRestoreEnabled = prefs.autoRestoreEnabled
        secureFieldHandler.bypassEnabled = prefs.secureFieldBypass
    }

    /// Called when preferences change (via NotificationCenter)
    @objc func preferencesDidChange() {
        applyPreferences()
        Log.input("Preferences reloaded")
    }

    // MARK: - Vietnamese Mode Toggle

    /// Toggle Vietnamese mode on/off
    func toggleVietnamese() {
        // Commit any pending composition first
        if engine.hasComposition {
            let result = engine.forceCommit()
            handleEngineResult(result, client: nil)
        }

        engine.isVietnameseEnabled.toggle()

        // Update per-app setting if enabled
        if appDetector.perAppModeEnabled {
            appDetector.setVietnameseMode(enabled: engine.isVietnameseEnabled)
        }

        // Save global state
        prefs.vietnameseEnabled = engine.isVietnameseEnabled

        // Update status bar
        StatusBarManager.shared?.updateIcon(isVietnamese: engine.isVietnameseEnabled)

        Log.input("Vietnamese mode: \(engine.isVietnameseEnabled ? "ON" : "OFF")")
    }
}
