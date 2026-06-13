import Foundation

/// Vietnamese spell checker
/// Validates Vietnamese syllable structure
struct SpellChecker {

    /// Valid initial consonants (phụ âm đầu)
    static let validInitials: Set<String> = [
        "", // No initial consonant
        "b", "c", "ch", "d", "đ", "g", "gh", "gi", "h", "k", "kh",
        "l", "m", "n", "ng", "ngh", "nh",
        "p", "ph", "qu", "r", "s", "t", "th", "tr", "v", "x"
    ]

    /// Valid final consonants (phụ âm cuối)
    static let validFinals: Set<String> = [
        "", // No final consonant
        "c", "ch", "m", "n", "ng", "nh", "p", "t"
    ]

    /// Valid vowel nuclei (nguyên âm) — basic and combined
    static let validVowels: Set<String> = [
        // Single vowels
        "a", "ă", "â", "e", "ê", "i", "o", "ô", "ơ", "u", "ư", "y",
        // Double vowel combinations
        "ai", "ao", "au", "ay", "âu", "ây",
        "eo", "êu",
        "ia", "iê", "iu",
        "oa", "oă", "oe", "oi", "oo", "ôi",
        "ơi",
        "ua", "uâ", "uă", "uê", "ui", "uo", "uô", "uơ", "uy", "uya", "uyê",
        "ưa", "ưi", "ưo", "ươ", "ưu",
        "ya", "yê"
    ]

    /// Check if a syllable string (with tones stripped) is a valid Vietnamese syllable
    /// - Parameter text: The syllable text (Unicode, tones included is fine)
    /// - Returns: true if valid Vietnamese syllable
    func isValidSyllable(_ text: String) -> Bool {
        let lower = stripAllTones(text.lowercased())
        guard !lower.isEmpty else { return false }

        // Decompose into initial + vowel + final
        guard let parts = decompose(lower) else { return false }

        // Validate each part
        if !SpellChecker.validInitials.contains(parts.initial) {
            return false
        }
        if !SpellChecker.validVowels.contains(parts.vowel) {
            return false
        }
        if !SpellChecker.validFinals.contains(parts.final_) {
            return false
        }

        // Additional combination rules
        return validateCombination(initial: parts.initial, vowel: parts.vowel, final_: parts.final_)
    }

    // MARK: - Decomposition

    private struct SyllableParts {
        var initial: String
        var vowel: String
        var final_: String
    }

    private func decompose(_ text: String) -> SyllableParts? {
        var remaining = text
        var initial = ""

        // Extract initial consonant (longest match first)
        let sortedInitials = SpellChecker.validInitials
            .filter { !$0.isEmpty }
            .sorted(by: { $0.count > $1.count })

        for init_ in sortedInitials {
            if remaining.hasPrefix(init_) {
                initial = init_
                remaining = String(remaining.dropFirst(init_.count))
                break
            }
        }

        guard !remaining.isEmpty else { return nil }

        // Extract final consonant (from end, longest match first)
        var final_ = ""
        let sortedFinals = SpellChecker.validFinals
            .filter { !$0.isEmpty }
            .sorted(by: { $0.count > $1.count })

        for fin in sortedFinals {
            if remaining.hasSuffix(fin) && remaining.count > fin.count {
                final_ = fin
                remaining = String(remaining.dropLast(fin.count))
                break
            }
        }

        // Remaining must be vowel
        guard !remaining.isEmpty else { return nil }

        return SyllableParts(initial: initial, vowel: remaining, final_: final_)
    }

    // MARK: - Combination Validation

    private func validateCombination(initial: String, vowel: String, final_: String) -> Bool {
        // Rule 1: Short vowels (ă, â) must have a final consonant
        if (vowel == "ă" || vowel == "â") && final_.isEmpty {
            return false
        }

        // Rule 2: Stopped syllables (c, p, t, ch finals) can only take sắc or nặng tones
        // This is enforced at the syllable level — we validate the structure here
        // (Actual tone validation is done in validateToneForSyllable)

        // Rule 3: Invalid initial + vowel combinations
        let invalidCombos: Set<String> = [
            "kh-y",      // "khy" is invalid
            "ng-oe",     // "ngoe" is invalid (should be "ngoẹ" etc.)
            "c-uy",      // "cuy" is invalid
            "p-ơ",       // "pơ" is invalid  
        ]
        let comboKey = "\(initial)-\(vowel)"
        if invalidCombos.contains(comboKey) {
            return false
        }

        // Rule 4: "gi" + vowels starting with "i" is redundant
        // "gi" already contains the "i", so "gii" is invalid
        if initial == "gi" && vowel.hasPrefix("i") {
            return false
        }

        // Rule 5: Finals "nh", "ch" are only valid after certain vowels
        if final_ == "ch" {
            let validVowelsForCh: Set<String> = ["a", "ă", "â", "e", "ê", "i", "oa", "uê"]
            if !validVowelsForCh.contains(vowel) {
                return false
            }
        }

        if final_ == "nh" {
            let validVowelsForNh: Set<String> = ["a", "â", "e", "ê", "i", "oa", "uê", "uy"]
            if !validVowelsForNh.contains(vowel) {
                return false
            }
        }

        return true
    }

    // MARK: - Tone Validation

    /// Validate that a tone is compatible with the syllable's final consonant
    /// Vietnamese phonology: stopped syllables (c, p, t, ch) only allow sắc and nặng
    /// - Parameters:
    ///   - tone: The tone being applied
    ///   - final_: The final consonant of the syllable
    /// - Returns: true if the tone is valid for this syllable structure
    func isValidTone(_ tone: CharacterMap.Tone, for final_: String) -> Bool {
        let stoppedFinals: Set<String> = ["c", "p", "t", "ch"]

        if stoppedFinals.contains(final_) {
            // Only sắc and nặng are valid for stopped syllables
            return tone == .sac || tone == .nang || tone == .none
        }

        // All tones are valid for open syllables and sonorant finals (m, n, ng, nh)
        return true
    }

    // MARK: - Utilities

    /// Strip all tone marks from text, preserving quality diacritics
    private func stripAllTones(_ text: String) -> String {
        var result = ""
        for char in text {
            result.append(CharacterMap.stripTone(char))
        }
        return result
    }

    /// Check if the given text looks like it could be a Vietnamese word
    /// (less strict than isValidSyllable — used for auto-restore decisions)
    func looksVietnamese(_ text: String) -> Bool {
        // Quick check: does it contain any Vietnamese-specific characters?
        let vietnameseSpecific: Set<Character> = [
            "ă", "â", "đ", "ê", "ô", "ơ", "ư",
            "Ă", "Â", "Đ", "Ê", "Ô", "Ơ", "Ư"
        ]

        for char in text {
            if vietnameseSpecific.contains(char) { return true }
            if CharacterMap.isTonedVowel(char) { return true }
        }

        return false
    }
}
