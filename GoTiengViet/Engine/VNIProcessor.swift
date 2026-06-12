import Foundation

/// VNI input method processor
/// Uses number keys (0-9) to indicate diacritics and character modifications
struct VNIProcessor: InputMethodProcessor {

    // MARK: - VNI Key Mappings

    /// VNI tone keys (1-5, 0 to remove)
    private static let toneKeys: [Character: CharacterMap.Tone] = [
        "1": .sac,
        "2": .huyen,
        "3": .hoi,
        "4": .nga,
        "5": .nang,
        "0": .none   // Remove tone
    ]

    /// VNI modification keys
    /// 6: circumflex (â, ê, ô)
    /// 7: horn (ơ, ư)
    /// 8: breve (ă)
    /// 9: đ
    private static let modificationKeys: [Character: CharacterMap.VowelModification] = [
        "6": .circumflex,
        "7": .horn,
        "8": .breve,
    ]

    // MARK: - Processing

    func processKey(
        _ key: Character,
        buffer: inout [Character],
        composed: inout String,
        tonePlacement: TonePlacement
    ) -> ProcessResult {

        // 1. Check if it's a tone key (1-5, 0)
        if let tone = VNIProcessor.toneKeys[key] {
            return handleToneKey(key, tone: tone, buffer: &buffer, composed: &composed, tonePlacement: tonePlacement)
        }

        // 2. Check if it's a modification key (6, 7, 8)
        if let mod = VNIProcessor.modificationKeys[key] {
            return handleModificationKey(key, modification: mod, buffer: &buffer, composed: &composed)
        }

        // 3. Check if it's '9' (đ)
        if key == "9" {
            return handleDKey(buffer: &buffer, composed: &composed)
        }

        // 4. Regular character
        if key.isLetter {
            buffer.append(key)
            composed = String(buffer)
            return .consumed
        }

        // 5. Non-letter, non-VNI key → passthrough
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
            // No vowels — treat number as regular character (passthrough)
            return .passthrough
        }

        let currentComposed = String(buffer)

        // Check for undo: if same tone already applied, pressing again undoes it
        let existingTone = findExistingTone(in: currentComposed)
        if existingTone == tone && tone != .none {
            // Undo: remove tone
            let untoned = tonePlacement.removeTone(from: currentComposed)
            buffer = Array(untoned)
            // Append the number key as literal
            buffer.append(key)
            composed = String(buffer)
            return .undone
        }

        // Apply or replace tone
        let withTone: String
        if existingTone != .none {
            // First remove existing tone
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

        // Fallback: passthrough
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

    // MARK: - Modification Key Handling (6, 7, 8)

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
                bufferCopy.append(key) // Append number as literal
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

    // MARK: - 'd9' → 'đ' Handling

    private func handleDKey(
        buffer: inout [Character],
        composed: inout String
    ) -> ProcessResult {
        guard !buffer.isEmpty else {
            return .passthrough
        }

        // Find the last 'd' in the buffer
        for i in stride(from: buffer.count - 1, through: 0, by: -1) {
            let char = buffer[i]
            if char.lowercased() == "d" {
                // Check it's not already đ
                buffer[i] = char.isUppercase ? Character("Đ") : Character("đ")
                composed = String(buffer)
                return .consumed
            }
            if char.lowercased().first == Character("đ") {
                // Already đ — undo
                buffer[i] = char.isUppercase ? Character("D") : Character("d")
                buffer.append("9")
                composed = String(buffer)
                return .undone
            }
        }

        // No 'd' found — passthrough
        return .passthrough
    }
}
