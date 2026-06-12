import Foundation

/// Protocol for input method processors (Telex, VNI)
protocol InputMethodProcessor {
    /// Process a single keystroke and return the result
    /// - Parameters:
    ///   - key: The character typed
    ///   - buffer: Current composition buffer contents
    ///   - tonePlacement: Tone placement engine to use
    /// - Returns: Processing result
    func processKey(_ key: Character, buffer: inout [Character], composed: inout String, tonePlacement: TonePlacement) -> ProcessResult
}

/// Result of processing a keystroke
enum ProcessResult {
    /// Key was consumed and buffer was updated. `composed` contains the new display string.
    case consumed
    /// Key was consumed and the buffer should be committed (e.g., space, punctuation)
    case commit
    /// Key should be passed through to the system (not a Vietnamese key)
    case passthrough
    /// Key was an escape/undo (e.g., double-press of modifier key like ss → s)
    case undone
}

/// Telex input method processor
/// Handles conversion of Telex key sequences to Vietnamese characters
struct TelexProcessor: InputMethodProcessor {

    // MARK: - Telex Key Mappings

    /// Telex modifier keys for vowel quality changes
    /// (handled inline in handleWKey and handleDoubleVowel methods)

    /// Telex tone keys
    private static let toneKeys: [Character: CharacterMap.Tone] = [
        "s": .sac,
        "f": .huyen,
        "r": .hoi,
        "x": .nga,
        "j": .nang,
        "z": .none  // z removes tone
    ]

    /// Characters that trigger vowel modification via doubling (aa→â, ee→ê, oo→ô)
    private static let doubleVowelKeys: Set<Character> = ["a", "e", "o"]

    // MARK: - Processing

    func processKey(
        _ key: Character,
        buffer: inout [Character],
        composed: inout String,
        tonePlacement: TonePlacement
    ) -> ProcessResult {

        let lowerKey = Character(key.lowercased())

        // 1. Check if it's a tone key (s, f, r, x, j, z)
        if let tone = TelexProcessor.toneKeys[lowerKey] {
            return handleToneKey(key, tone: tone, buffer: &buffer, composed: &composed, tonePlacement: tonePlacement)
        }

        // 2. Check if it's 'w' (breve/horn modifier)
        if lowerKey == "w" {
            return handleWKey(key, buffer: &buffer, composed: &composed, tonePlacement: tonePlacement)
        }

        // 3. Check if it's 'd' (for đ via dd)
        if lowerKey == "d" {
            return handleDKey(key, buffer: &buffer, composed: &composed)
        }

        // 4. Check for double vowel (aa→â, ee→ê, oo→ô)
        if TelexProcessor.doubleVowelKeys.contains(lowerKey) {
            let result = handleDoubleVowel(key, buffer: &buffer, composed: &composed)
            if case .consumed = result {
                return result
            }
            // Fall through to regular character handling if double vowel didn't apply
        }

        // 5. Regular alphabetic character — add to buffer
        if key.isLetter {
            buffer.append(key)
            composed = String(buffer)
            return .consumed
        }

        // 6. Non-alphabetic character — commit buffer
        return .passthrough
    }

    // MARK: - Tone Key Handling

    private func handleToneKey(
        _ key: Character,
        tone: CharacterMap.Tone,
        buffer: inout [Character],
        composed: inout String,
        tonePlacement: TonePlacement
    ) -> ProcessResult {
        guard !buffer.isEmpty else {
            // No buffer content — this is just a regular letter
            buffer.append(key)
            composed = String(buffer)
            return .consumed
        }

        // Check if the composed text forms a valid Vietnamese syllable
        let currentComposed = String(buffer)

        // Try to apply tone mark
        let withTone = tonePlacement.applyTone(to: currentComposed, tone: tone)

        if withTone != currentComposed {
            // Tone was applied successfully
            composed = withTone
            // Update buffer to reflect the new composed text
            buffer = Array(withTone)
            return .consumed
        }

        // Check for escape: double-press (e.g., ss → literal s, ff → literal f)
        if let lastChar = buffer.last,
           lastChar.lowercased() == key.lowercased() {
            // This might be an escape sequence — but only for tone keys
            // Actually, if tone wasn't applied, treat as regular character
        }

        // If there are no vowels to put the tone on, check if this is an escape
        let hasVowel = buffer.contains(where: { CharacterMap.isVowel($0) })
        if !hasVowel {
            // No vowels — treat tone key as regular letter
            buffer.append(key)
            composed = String(buffer)
            return .consumed
        }

        // Tone was already present and same key pressed again → undo (escape)
        // Check if the existing composed text already has this tone
        let existingTone = findExistingTone(in: currentComposed)
        if existingTone == tone {
            // Same tone pressed twice → remove tone and append the literal key
            let untoned = tonePlacement.removeTone(from: currentComposed)
            buffer = Array(untoned)
            buffer.append(key)
            composed = String(buffer)
            return .undone
        }

        // Different tone → replace
        if existingTone != .none {
            // First remove existing tone, then apply new one
            let untoned = tonePlacement.removeTone(from: currentComposed)
            let retoned = tonePlacement.applyTone(to: untoned, tone: tone)
            buffer = Array(retoned)
            composed = retoned
            return .consumed
        }

        // Fallback: treat as regular letter
        buffer.append(key)
        composed = String(buffer)
        return .consumed
    }

    /// Find the existing tone in a string
    private func findExistingTone(in text: String) -> CharacterMap.Tone {
        for char in text {
            let tone = CharacterMap.getTone(char)
            if tone != .none {
                return tone
            }
        }
        return .none
    }

    // MARK: - 'w' Key Handling (breve/horn)

    private func handleWKey(
        _ key: Character,
        buffer: inout [Character],
        composed: inout String,
        tonePlacement: TonePlacement
    ) -> ProcessResult {
        guard !buffer.isEmpty else {
            // 'w' alone → 'ư' (shorthand)
            let char = key.isUppercase ? Character("Ư") : Character("ư")
            buffer.append(char)
            composed = String(buffer)
            return .consumed
        }

        // Special case: "uo" → "ươ" pattern
        // When 'w' is pressed after "uo", both vowels should be modified
        let wResult = tryModifyUOPattern(key, buffer: &buffer, composed: &composed)
        if let result = wResult {
            return result
        }

        // Try to find the last modifiable vowel and apply horn/breve
        var modified = false
        var bufferCopy = buffer

        // Scan from end to find the right vowel to modify
        for i in stride(from: bufferCopy.count - 1, through: 0, by: -1) {
            let char = bufferCopy[i]
            let stripped = CharacterMap.stripTone(char)
            let tone = CharacterMap.getTone(char)
            let lower = stripped.lowercased().first!

            var modification: CharacterMap.VowelModification? = nil

            switch lower {
            case "a":
                modification = .breve     // a → ă
            case "o":
                modification = .horn      // o → ơ
            case "u":
                modification = .horn      // u → ư
            case "ă":
                // Already ă — undo: ă + w → aw
                bufferCopy[i] = char.isUppercase ? Character("A") : Character("a")
                if tone != .none {
                    if let toned = CharacterMap.applyTone(bufferCopy[i], tone: tone) {
                        bufferCopy[i] = toned
                    }
                }
                bufferCopy.append(key)
                buffer = bufferCopy
                composed = String(buffer)
                return .undone
            case "ơ":
                // Already ơ — undo: ơ + w → ow
                bufferCopy[i] = char.isUppercase ? Character("O") : Character("o")
                if tone != .none {
                    if let toned = CharacterMap.applyTone(bufferCopy[i], tone: tone) {
                        bufferCopy[i] = toned
                    }
                }
                bufferCopy.append(key)
                buffer = bufferCopy
                composed = String(buffer)
                return .undone
            case "ư":
                // Already ư — undo: ư + w → uw
                bufferCopy[i] = char.isUppercase ? Character("U") : Character("u")
                if tone != .none {
                    if let toned = CharacterMap.applyTone(bufferCopy[i], tone: tone) {
                        bufferCopy[i] = toned
                    }
                }
                bufferCopy.append(key)
                buffer = bufferCopy
                composed = String(buffer)
                return .undone
            default:
                continue
            }

            if let mod = modification {
                if let newChar = CharacterMap.applyModification(stripped, modification: mod) {
                    var finalChar = newChar
                    // Re-apply tone if it had one
                    if tone != .none {
                        if let toned = CharacterMap.applyTone(newChar, tone: tone) {
                            finalChar = toned
                        }
                    }
                    // Preserve case
                    bufferCopy[i] = char.isUppercase ? Character(finalChar.uppercased()) : finalChar
                    modified = true
                    break
                }
            }
        }

        if modified {
            buffer = bufferCopy
            composed = String(buffer)
            return .consumed
        }

        // No modifiable vowel found — treat 'w' as 'ư'
        let char = key.isUppercase ? Character("Ư") : Character("ư")
        buffer.append(char)
        composed = String(buffer)
        return .consumed
    }

    /// Try to modify "uo" → "ươ" pattern
    /// This handles words like: thương, được, người, etc.
    /// where a single 'w' press should modify both u and o
    /// Also handles cases where one is already modified: ư+o → ươ, u+ơ → ươ
    private func tryModifyUOPattern(
        _ key: Character,
        buffer: inout [Character],
        composed: inout String
    ) -> ProcessResult? {
        let count = buffer.count
        guard count >= 2 else { return nil }

        // Look for "uo" pattern (possibly with tones or already-modified vowels)
        // Scan backwards for the pattern
        for i in stride(from: count - 1, through: 1, by: -1) {
            let current = buffer[i]
            let prev = buffer[i - 1]
            let currentStripped = CharacterMap.stripTone(current)
            let prevStripped = CharacterMap.stripTone(prev)
            let currentBase = CharacterMap.removeModification(currentStripped).lowercased().first!
            let prevBase = CharacterMap.removeModification(prevStripped).lowercased().first!
            let currentLower = currentStripped.lowercased().first!
            let prevLower = prevStripped.lowercased().first!

            // Match patterns: u+o, ư+o, u+ơ (all should become ươ)
            let prevIsU = prevBase == "u" || prevLower == "ư"
            let currentIsO = currentBase == "o" || currentLower == "ơ"

            if prevIsU && currentIsO {
                let prevTone = CharacterMap.getTone(prev)
                let currentTone = CharacterMap.getTone(current)

                // Check if already fully modified (ươ) — don't re-modify
                if prevLower == "ư" && currentLower == "ơ" {
                    return nil // Already ươ pattern, let regular handler deal with undo
                }

                // Modify to ư if not already
                var newPrev: Character
                if prevLower == "ư" {
                    newPrev = prev  // Already ư, keep it (with any tone)
                } else {
                    newPrev = prev.isUppercase ? Character("Ư") : Character("ư")
                    if prevTone != .none {
                        if let toned = CharacterMap.applyTone(newPrev, tone: prevTone) {
                            newPrev = toned
                        }
                    }
                }

                // Modify to ơ if not already
                var newCurrent: Character
                if currentLower == "ơ" {
                    newCurrent = current  // Already ơ, keep it (with any tone)
                } else {
                    newCurrent = current.isUppercase ? Character("Ơ") : Character("ơ")
                    if currentTone != .none {
                        if let toned = CharacterMap.applyTone(newCurrent, tone: currentTone) {
                            newCurrent = toned
                        }
                    }
                }

                buffer[i - 1] = newPrev
                buffer[i] = newCurrent
                composed = String(buffer)
                return .consumed
            }
        }

        return nil
    }

    // MARK: - 'd' Key Handling (dd → đ)

    private func handleDKey(
        _ key: Character,
        buffer: inout [Character],
        composed: inout String
    ) -> ProcessResult {
        // Check if last character in buffer is 'd' or 'D'
        if let last = buffer.last, last.lowercased() == "d" {
            // dd → đ
            let isUpper = last.isUppercase || key.isUppercase
            buffer[buffer.count - 1] = isUpper ? Character("Đ") : Character("đ")
            composed = String(buffer)
            return .consumed
        }

        // Check if last character is đ — triple d: undo
        if let last = buffer.last, last.lowercased().first == Character("đ") {
            // đ + d → dd (undo)
            let isUpper = last.isUppercase
            buffer[buffer.count - 1] = isUpper ? Character("D") : Character("d")
            buffer.append(key)
            composed = String(buffer)
            return .undone
        }

        // Just a regular 'd'
        buffer.append(key)
        composed = String(buffer)
        return .consumed
    }

    // MARK: - Double Vowel Handling (aa→â, ee→ê, oo→ô)

    private func handleDoubleVowel(
        _ key: Character,
        buffer: inout [Character],
        composed: inout String
    ) -> ProcessResult {
        guard let last = buffer.last else {
            buffer.append(key)
            composed = String(buffer)
            return .consumed
        }

        let lastLower = last.lowercased().first!
        let keyLower = key.lowercased().first!

        // Check if same vowel key pressed twice
        if lastLower == keyLower && CharacterMap.baseVowels.contains(lastLower) {
            // Apply circumflex modification
            let stripped = CharacterMap.stripTone(last)
            let tone = CharacterMap.getTone(last)

            if let modified = CharacterMap.applyModification(stripped, modification: .circumflex) {
                var finalChar = modified
                if tone != .none {
                    if let toned = CharacterMap.applyTone(modified, tone: tone) {
                        finalChar = toned
                    }
                }
                // Preserve case from original
                buffer[buffer.count - 1] = last.isUppercase ? Character(finalChar.uppercased()) : finalChar
                composed = String(buffer)
                return .consumed
            }
        }

        // Check if last char is already the circumflex version → undo
        let strippedLast = CharacterMap.stripTone(last)
        let baseLast = CharacterMap.removeModification(strippedLast)
        if baseLast.lowercased().first == keyLower && CharacterMap.hasQualityDiacritic(strippedLast) {
            // undo: â + a → aa
            let tone = CharacterMap.getTone(last)
            var baseChar = last.isUppercase ? Character(keyLower.uppercased()) : keyLower
            if tone != .none {
                if let toned = CharacterMap.applyTone(baseChar, tone: tone) {
                    baseChar = toned
                }
            }
            buffer[buffer.count - 1] = baseChar
            buffer.append(key)
            composed = String(buffer)
            return .undone
        }

        // Not a double vowel situation — regular character
        buffer.append(key)
        composed = String(buffer)
        return .consumed
    }
}
