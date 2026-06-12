import Foundation

/// Vietnamese tone placement algorithm
/// Supports both old-style (traditional) and new-style (linguistic) placement
///
/// ## Rules:
/// 1. If any vowel already has a quality diacritic (â, ă, ê, ô, ơ, ư), tone MUST go on it
/// 2. Old-style: tone near center of word for visual balance
/// 3. New-style: tone on the main/nucleus vowel (linguistically accurate)
struct TonePlacement {

    /// The style of tone placement to use
    var style: AppConstants.ToneStyle

    init(style: AppConstants.ToneStyle = .new) {
        self.style = style
    }

    // MARK: - Vietnamese Syllable Structure

    /// Valid initial consonants (phụ âm đầu)
    static let initialConsonants: [String] = [
        "ngh", "nh", "ng", "gh", "gi", "ch", "kh", "ph", "th", "tr", "qu",
        "b", "c", "d", "g", "h", "k", "l", "m", "n", "p", "r", "s", "t", "v", "x",
        "đ"
    ].sorted(by: { $0.count > $1.count })  // Match longest first

    /// Valid final consonants (phụ âm cuối)
    static let finalConsonants: Set<String> = [
        "ch", "ng", "nh", "c", "m", "n", "p", "t"
    ]

    // MARK: - Syllable Decomposition

    /// Decomposed Vietnamese syllable
    struct Syllable {
        var initial: String       // phụ âm đầu (e.g., "th", "ngh", "")
        var vowelCluster: String  // nguyên âm (e.g., "oa", "uê", "a")
        var final_: String        // phụ âm cuối (e.g., "ng", "n", "")

        /// Indices of vowel characters in the original string
        var vowelStartIndex: Int
        var vowelEndIndex: Int

        /// The full syllable as a string
        var fullText: String {
            return initial + vowelCluster + final_
        }
    }

    /// Decompose a Vietnamese syllable string into its components
    /// - Parameter text: The syllable text (e.g., "thường", "hoàn")
    /// - Returns: Decomposed syllable, or nil if not a valid Vietnamese syllable
    func decompose(_ text: String) -> Syllable? {
        let lower = text.lowercased()
        guard !lower.isEmpty else { return nil }

        var remaining = lower
        var initial = ""
        var vowelStart = 0

        // 1. Extract initial consonant
        for consonant in TonePlacement.initialConsonants {
            if remaining.hasPrefix(consonant) {
                // Special case: "gi" — the "i" might be the vowel
                if consonant == "gi" && remaining.count == 2 {
                    // "gi" alone — "g" is initial, "i" is vowel
                    initial = "g"
                    remaining = String(remaining.dropFirst(1))
                    vowelStart = 1
                    break
                }
                // Special case: "qu" — "q" is initial with "u" as part of it
                if consonant == "qu" {
                    initial = "qu"
                    remaining = String(remaining.dropFirst(2))
                    vowelStart = 2
                    break
                }
                initial = consonant
                remaining = String(remaining.dropFirst(consonant.count))
                vowelStart = consonant.count
                break
            }
        }

        guard !remaining.isEmpty else { return nil }

        // 2. Extract final consonant (from the end)
        var final_ = ""
        var vowelPart = remaining

        // Try longest final consonant first
        let sortedFinals = TonePlacement.finalConsonants.sorted(by: { $0.count > $1.count })
        for fc in sortedFinals {
            if vowelPart.hasSuffix(fc) && vowelPart.count > fc.count {
                final_ = fc
                vowelPart = String(vowelPart.dropLast(fc.count))
                break
            }
        }

        // 3. What remains is the vowel cluster
        guard !vowelPart.isEmpty else { return nil }

        // Verify all remaining chars are vowels (strip tones first for checking)
        for char in vowelPart {
            let stripped = CharacterMap.stripTone(char)
            let base = CharacterMap.removeModification(stripped)
            if !CharacterMap.baseVowels.contains(base) && !CharacterMap.vowels.contains(stripped) {
                // Not a vowel — this might not be a valid syllable
                // But we'll still try to process it
                break
            }
        }

        let vowelEnd = vowelStart + vowelPart.count - 1

        return Syllable(
            initial: initial,
            vowelCluster: vowelPart,
            final_: final_,
            vowelStartIndex: vowelStart,
            vowelEndIndex: vowelEnd
        )
    }

    // MARK: - Tone Placement

    /// Find the index (within the full syllable string) where the tone mark should be placed
    /// - Parameters:
    ///   - text: The syllable text
    ///   - tone: The tone to apply
    /// - Returns: The character index in `text` where the tone should go, or nil
    func findTonePosition(in text: String) -> Int? {
        guard let syllable = decompose(text) else { return nil }
        return findTonePositionInSyllable(syllable, fullText: text)
    }

    /// Core algorithm: determine which vowel receives the tone mark
    private func findTonePositionInSyllable(_ syllable: Syllable, fullText: String) -> Int? {
        let vowelCluster = syllable.vowelCluster
        guard !vowelCluster.isEmpty else { return nil }

        let chars = Array(fullText)
        let vowelStart = syllable.vowelStartIndex
        let vowelEnd = syllable.vowelEndIndex

        // Rule 1: If any vowel has a quality diacritic (â, ă, ê, ô, ơ, ư),
        // the tone MUST go on that vowel.
        // Special case: when BOTH vowels have quality diacritics (e.g., ươ),
        // prefer the LAST one with a quality diacritic.
        var qualityPositions: [Int] = []
        for i in vowelStart...vowelEnd {
            guard i < chars.count else { continue }
            let stripped = CharacterMap.stripTone(chars[i])
            if CharacterMap.hasQualityDiacritic(stripped) {
                qualityPositions.append(i)
            }
        }
        if !qualityPositions.isEmpty {
            // If multiple quality diacritics (e.g., ươ), use the last one
            return qualityPositions.last!
        }

        let vowelCount = vowelEnd - vowelStart + 1
        let hasFinalConsonant = !syllable.final_.isEmpty

        // Single vowel — tone goes on it
        if vowelCount == 1 {
            return vowelStart
        }

        // Rule 2: Apply style-specific rules for vowel clusters
        switch style {
        case .old:
            return findTonePositionOldStyle(
                vowelStart: vowelStart,
                vowelEnd: vowelEnd,
                vowelCount: vowelCount,
                hasFinalConsonant: hasFinalConsonant,
                fullText: fullText
            )
        case .new:
            return findTonePositionNewStyle(
                vowelStart: vowelStart,
                vowelEnd: vowelEnd,
                vowelCount: vowelCount,
                hasFinalConsonant: hasFinalConsonant,
                fullText: fullText,
                initial: syllable.initial
            )
        }
    }

    /// Old-style (traditional) placement:
    /// - No final consonant: tone on next-to-last vowel
    /// - With final consonant: tone on last vowel
    private func findTonePositionOldStyle(
        vowelStart: Int,
        vowelEnd: Int,
        vowelCount: Int,
        hasFinalConsonant: Bool,
        fullText: String
    ) -> Int {
        if vowelCount == 2 {
            if hasFinalConsonant {
                return vowelEnd     // Last vowel: hoàn
            } else {
                return vowelStart   // Next-to-last: hòa
            }
        }

        if vowelCount >= 3 {
            // Three vowels: tone on the middle one
            return vowelStart + 1   // uyên → tone on ê (middle)
        }

        return vowelStart
    }

    /// New-style (linguistic) placement:
    /// - Tone always on the main vowel (nucleus)
    /// - In oa, oe, uy clusters: the second vowel is the nucleus
    private func findTonePositionNewStyle(
        vowelStart: Int,
        vowelEnd: Int,
        vowelCount: Int,
        hasFinalConsonant: Bool,
        fullText: String,
        initial: String
    ) -> Int {
        let chars = Array(fullText)

        if vowelCount == 2 {
            let first = CharacterMap.stripTone(chars[vowelStart]).lowercased().first!
            let second = CharacterMap.stripTone(chars[vowelEnd]).lowercased().first!

            // Semi-vowel detection:
            // In oa, oe, uy: first is semi-vowel, second is nucleus
            let semiVowelPairs: Set<String> = ["oa", "oe", "uy"]
            let pair = String(first) + String(second)

            if semiVowelPairs.contains(pair) {
                return vowelEnd  // Tone on nucleus: hoà, huỷ
            }

            // For other pairs (ai, ao, au, ay, eo, eu, ia, ie, iu, oi, oo, ou, ua, ue, ui, uo, uu):
            // Generally tone goes on the first vowel
            if hasFinalConsonant {
                return vowelEnd
            } else {
                return vowelStart
            }
        }

        if vowelCount >= 3 {
            // Three vowels (e.g., uye, uya, oai): tone on the middle vowel
            return vowelStart + 1
        }

        return vowelStart
    }

    // MARK: - Apply Tone to Syllable String

    /// Apply a tone mark to the correct position in a syllable string
    /// - Parameters:
    ///   - text: The syllable text
    ///   - tone: The tone to apply
    /// - Returns: The text with the tone applied at the correct position
    func applyTone(to text: String, tone: CharacterMap.Tone) -> String {
        guard let position = findTonePosition(in: text) else {
            return text
        }

        var chars = Array(text)
        guard position < chars.count else { return text }

        // Apply tone to the character at the determined position
        if let toned = CharacterMap.applyTone(chars[position], tone: tone) {
            chars[position] = toned
        }

        return String(chars)
    }

    /// Remove tone mark from a syllable, keeping quality diacritics
    func removeTone(from text: String) -> String {
        var chars = Array(text)
        for i in 0..<chars.count {
            if CharacterMap.isTonedVowel(chars[i]) {
                chars[i] = CharacterMap.stripTone(chars[i])
            }
        }
        return String(chars)
    }
}
