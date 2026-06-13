import Foundation

/// Main Vietnamese engine coordinator
/// Routes input to the appropriate processor (Telex or VNI)
/// and manages composition state
class VietnameseEngine {

    // MARK: - Properties

    /// Current input method
    var inputMethod: AppConstants.InputMethod {
        didSet {
            updateProcessor()
        }
    }

    /// Tone placement engine
    var tonePlacement: TonePlacement

    /// Spell checker
    let spellChecker = SpellChecker()

    /// Macro engine
    let macroEngine = MacroEngine()

    /// Current processor (Telex or VNI)
    private var processor: InputMethodProcessor

    /// Whether Vietnamese mode is active
    var isVietnameseEnabled: Bool = true

    /// Whether spell checking is active
    var spellCheckEnabled: Bool = false

    /// Whether auto-restore is active (undo Vietnamese on invalid words)
    var autoRestoreEnabled: Bool = false

    /// Current composition buffer (raw keystrokes)
    private(set) var buffer: [Character] = []

    /// Current composed text (after Vietnamese processing)
    private(set) var composedText: String = ""

    /// Raw input for the current composition (for auto-restore)
    private(set) var rawInput: String = ""

    // MARK: - Initialization

    init(inputMethod: AppConstants.InputMethod = .telex,
         toneStyle: AppConstants.ToneStyle = .new) {
        self.inputMethod = inputMethod
        self.tonePlacement = TonePlacement(style: toneStyle)

        switch inputMethod {
        case .telex:
            self.processor = TelexProcessor()
        case .vni:
            self.processor = VNIProcessor()
        case .viqr:
            self.processor = VIQRProcessor()
        }
    }

    // MARK: - Engine Control

    /// Reset the composition buffer
    func resetBuffer() {
        buffer.removeAll()
        composedText = ""
        rawInput = ""
        Log.engine("Buffer reset")
    }

    /// Update the processor when input method changes
    private func updateProcessor() {
        switch inputMethod {
        case .telex:
            processor = TelexProcessor()
        case .vni:
            processor = VNIProcessor()
        case .viqr:
            processor = VIQRProcessor()
        }
        Log.engine("Switched to \(inputMethod.displayName)")
    }

    // MARK: - Key Processing

    /// Process a single keystroke
    /// - Parameter key: The character typed
    /// - Returns: The result of processing
    func processKey(_ key: Character) -> EngineResult {
        // If Vietnamese is disabled, pass through everything
        guard isVietnameseEnabled else {
            return .passthrough
        }

        // Track raw input
        rawInput.append(key)

        // Check for commit triggers (space, punctuation, enter)
        if isCommitTrigger(key) {
            return handleCommitTrigger(key)
        }

        // Check for backspace (handled separately)
        // Note: backspace is handled at the InputController level

        // Process through the active input method
        let result = processor.processKey(key, buffer: &buffer, composed: &composedText, tonePlacement: tonePlacement)

        switch result {
        case .consumed:
            return .compositionUpdated(composedText)
        case .commit:
            return commitBuffer(appendChar: key)
        case .passthrough:
            if buffer.isEmpty {
                return .passthrough
            }
            // Buffer has content but key is not consumed
            // Commit buffer first, then pass through the key
            let committed = composedText
            resetBuffer()
            return .commitAndPassthrough(committed)
        case .undone:
            return .compositionUpdated(composedText)
        }
    }

    /// Handle backspace key — **Smart Backspace**
    /// Instead of deleting the last Unicode character, this "undoes" the last keystroke
    /// by replaying the buffer without the last key. For example:
    /// - Typed "aws" → ắ → Backspace → ă (undoes the 's' tone key)
    /// - Typed "aw" → ă → Backspace → a (undoes the 'w' modifier)
    func processBackspace() -> EngineResult {
        guard !rawInput.isEmpty else {
            return .passthrough
        }

        // Remove the last keystroke from raw input
        rawInput.removeLast()

        if rawInput.isEmpty {
            buffer.removeAll()
            composedText = ""
            return .compositionCleared
        }

        // Replay the buffer from raw input
        replayBuffer()

        return .compositionUpdated(composedText)
    }

    /// Replay the entire buffer from rawInput
    /// This reprocesses each keystroke through the engine to reconstruct the composed text
    private func replayBuffer() {
        let savedRaw = rawInput
        buffer.removeAll()
        composedText = ""

        // Replay each character through the processor
        for key in savedRaw {
            _ = processor.processKey(key, buffer: &buffer, composed: &composedText, tonePlacement: tonePlacement)
        }
    }

    // MARK: - Commit Handling

    /// Check if a character should trigger a buffer commit
    private func isCommitTrigger(_ char: Character) -> Bool {
        // Space, punctuation, digits (for Telex), special characters
        if char == " " || char == "\n" || char == "\r" || char == "\t" {
            return true
        }

        // Common punctuation
        let punctuation: Set<Character> = [
            ".", ",", ";", ":", "!", "?", "'", "\"",
            "(", ")", "[", "]", "{", "}", "/",
            "@", "#", "$", "%", "^", "&", "*",
            "-", "_", "+", "=", "<", ">", "~", "`",
            "|", "\\"
        ]

        if punctuation.contains(char) {
            return true
        }

        // For Telex: digits are regular characters (not modifiers)
        // For VNI: digits 1-9 are modifiers, 0 removes tone
        if inputMethod == .telex && char.isNumber {
            return true
        }

        return false
    }

    /// Handle a commit trigger character
    private func handleCommitTrigger(_ char: Character) -> EngineResult {
        if buffer.isEmpty {
            return .passthrough
        }

        // Check macro expansion
        let bufferText = composedText.isEmpty ? String(buffer) : composedText
        if let expansion = macroEngine.expand(bufferText) {
            let result = expansion + String(char)
            resetBuffer()
            return .commitText(result)
        }

        // Spell check and auto-restore
        if spellCheckEnabled && autoRestoreEnabled {
            if !spellChecker.isValidSyllable(bufferText) && !spellChecker.looksVietnamese(bufferText) {
                // Not a valid Vietnamese syllable — restore raw input
                let restored = rawInput
                resetBuffer()
                return .commitText(restored)
            }
        }

        // Normal commit
        return commitBuffer(appendChar: char)
    }

    /// Commit the current buffer
    private func commitBuffer(appendChar: Character? = nil) -> EngineResult {
        let textToCommit: String
        if composedText.isEmpty {
            textToCommit = String(buffer)
        } else {
            textToCommit = composedText
        }

        resetBuffer()

        if let char = appendChar {
            return .commitText(textToCommit + String(char))
        }
        return .commitText(textToCommit)
    }

    /// Force commit the current buffer without any trigger character
    func forceCommit() -> EngineResult {
        if buffer.isEmpty {
            return .nothing
        }
        return commitBuffer()
    }

    // MARK: - State Queries

    /// Whether there is an active composition
    var hasComposition: Bool {
        return !buffer.isEmpty
    }

    /// The current composition text for display
    var currentComposition: String {
        return composedText.isEmpty ? String(buffer) : composedText
    }
}

// MARK: - Engine Result

/// Result of engine processing
enum EngineResult {
    /// No action needed
    case nothing

    /// Composition buffer was updated — update marked text
    case compositionUpdated(String)

    /// Composition was cleared — clear marked text
    case compositionCleared

    /// Text should be committed (inserted into the document)
    case commitText(String)

    /// Commit current buffer, then pass through the key
    case commitAndPassthrough(String)

    /// Key should be passed through to the system unchanged
    case passthrough
}
