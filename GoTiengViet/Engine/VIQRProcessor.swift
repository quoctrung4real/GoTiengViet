import Foundation

/// VIQR (Vietnamese Quoted-Readable) input method processor
/// Uses special characters after vowels to indicate diacritics:
///
/// ## Tone marks:
///   - `'` (apostrophe) → sắc (á)
///   - `` ` `` (backtick) → huyền (à)
///   - `?` → hỏi (ả)
///   - `~` → ngã (ã)
///   - `.` → nặng (ạ)
///
/// ## Vowel modifications:
///   - `^` → circumflex: a^ → â, e^ → ê, o^ → ô
///   - `+` → horn: o+ → ơ, u+ → ư
///   - `(` → breve: a( → ă
///   - `dd` → đ
///
/// ## Escape:
///   - `\` before a VIQR key to insert it literally
struct VIQRProcessor: InputMethodProcessor {

    // MARK: - VIQR Key Mappings

    /// VIQR tone keys
    private static let toneKeys: [Character: CharacterMap.Tone] = [
        "'": .sac,
        "`": .huyen,
        "?": .hoi,
        "~": .nga,
        ".": .nang,
    ]

    /// VIQR modification keys
    private static let modificationKeys: [Character: CharacterMap.VowelModification] = [
        "^": .circumflex,   // â, ê, ô
        "+": .horn,          // ơ, ư
        "(": .breve,         // ă
    ]

    /// All special VIQR keys that can be escaped with backslash
    private static let specialKeys: Set<Character> = ["'", "`", "?", "~", ".", "^", "+", "(", "\\"]

    // MARK: - Processing

    func processKey(
        _ key: Character,
        buffer: inout [Character],
        composed: inout String,
        tonePlacement: TonePlacement
    ) -> ProcessResult {

        // 1. Check escape: if last char is backslash, insert key literally
        if !buffer.isEmpty && buffer.last == "\\" {
            if VIQRProcessor.specialKeys.contains(key) {
                // Remove the backslash and insert the key literally
                buffer.removeLast()
                buffer.append(key)
                composed = String(buffer)
                return .consumed
            }
        }

        // 2. Backslash — buffer it for potential escape
        if key == "\\" {
            buffer.append(key)
            composed = String(buffer)
            return .consumed
        }

        // 3. Check if it's a tone key
        if let tone = VIQRProcessor.toneKeys[key] {
            return handleToneKey(key, tone: tone, buffer: &buffer, composed: &composed, tonePlacement: tonePlacement)
        }

        // 4. Check if it's a modification key (^, +, ()
        if let mod = VIQRProcessor.modificationKeys[key] {
            return handleModificationKey(key, modification: mod, buffer: &buffer, composed: &composed)
        }

        // 5. 'dd' or 'DD' → đ
        if key.lowercased() == "d" && !buffer.isEmpty && buffer.last?.lowercased() == "d" {
            return handleDKey(key, buffer: &buffer, composed: &composed)
        }

        // 6. Regular character
        if key.isLetter {
            buffer.append(key)
            composed = String(buffer)
            return .consumed
        }

        // 7. Non-letter, non-VIQR key → passthrough
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
            return .passthrough
        }

        // Check if there are vowels in the buffer
        let hasVowel = buffer.contains(where: { CharacterMap.isVowel($0) })
        guard hasVowel else {
            // No vowels — passthrough (let the system handle '.', '?', etc.)
            return .passthrough
        }

        let currentComposed = String(buffer)

        // Check for undo: if same tone already applied, pressing again undoes it
        let existingTone = findExistingTone(in: currentComposed)
        if existingTone == tone && tone != .none {
            // Undo: remove tone and append the key literally
            let untoned = tonePlacement.removeTone(from: currentComposed)
            buffer = Array(untoned)
            buffer.append(key)
            composed = String(buffer)
            return .undone
        }

        // Apply or replace tone
        let withTone: String
        if existingTone != .none {
            let untoned = tonePlacement.removeTone(from: currentComposed)
            withTone = tonePlacement.applyTone(to: untoned, tone: tone)
        } else {
            withTone = tonePlacement.applyTone(to: currentComposed, tone: tone)
        }

        if withTone != currentComposed || tone == .none {
            buffer = Array(withTone)
            composed = withTone
            return .consumed
        }

        return .passthrough
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

    // MARK: - Modification Key Handling (^, +, ()

    private func handleModificationKey(
        _ key: Character,
        modification: CharacterMap.VowelModification,
        buffer: inout [Character],
        composed: inout String
    ) -> ProcessResult {
        guard !buffer.isEmpty else {
            return .passthrough
        }

        // Find the last vowel that can accept this modification
        var bufferCopy = buffer
        var modified = false

        for i in stride(from: bufferCopy.count - 1, through: 0, by: -1) {
            let char = bufferCopy[i]
            let stripped = CharacterMap.stripTone(char)
            let tone = CharacterMap.getTone(char)
            let base = CharacterMap.removeModification(stripped)
            let lower = base.lowercased().first!

            // Check if this vowel can take the modification
            var canModify = false
            switch (lower, modification) {
            case ("a", .circumflex), ("e", .circumflex), ("o", .circumflex):
                canModify = true
            case ("a", .breve):
                canModify = true
            case ("o", .horn), ("u", .horn):
                canModify = true
            default:
                break
            }

            // Check if already modified with this — undo
            let currentLower = stripped.lowercased().first!
            let alreadyModified: Bool
            switch (currentLower, modification) {
            case ("â", .circumflex), ("ê", .circumflex), ("ô", .circumflex):
                alreadyModified = true
            case ("ă", .breve):
                alreadyModified = true
            case ("ơ", .horn), ("ư", .horn):
                alreadyModified = true
            default:
                alreadyModified = false
            }

            if alreadyModified {
                // Undo modification
                var baseChar = base
                if tone != .none {
                    if let toned = CharacterMap.applyTone(baseChar, tone: tone) {
                        baseChar = toned
                    }
                }
                bufferCopy[i] = char.isUppercase ? Character(baseChar.uppercased()) : baseChar
                bufferCopy.append(key) // Append key as literal
                buffer = bufferCopy
                composed = String(buffer)
                return .undone
            }

            if canModify {
                if let newChar = CharacterMap.applyModification(base, modification: modification) {
                    var finalChar = newChar
                    if tone != .none {
                        if let toned = CharacterMap.applyTone(newChar, tone: tone) {
                            finalChar = toned
                        }
                    }
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

        // No modifiable vowel found — passthrough
        return .passthrough
    }

    // MARK: - 'dd' → 'đ' Handling

    private func handleDKey(
        _ key: Character,
        buffer: inout [Character],
        composed: inout String
    ) -> ProcessResult {
        guard !buffer.isEmpty else {
            return .passthrough
        }

        let lastIndex = buffer.count - 1
        let lastChar = buffer[lastIndex]

        // Check if last char is 'd' (not already đ)
        if lastChar.lowercased() == "d" && lastChar.lowercased().first != Character("đ") {
            buffer[lastIndex] = lastChar.isUppercase ? Character("Đ") : Character("đ")
            composed = String(buffer)
            return .consumed
        }

        // Already đ — undo
        if lastChar.lowercased().first == Character("đ") {
            buffer[lastIndex] = lastChar.isUppercase ? Character("D") : Character("d")
            buffer.append(key)
            composed = String(buffer)
            return .undone
        }

        return .passthrough
    }
}
