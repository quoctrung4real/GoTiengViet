import Foundation

/// Complete Unicode character mapping for Vietnamese
/// Covers all 134 precomposed Vietnamese characters
enum CharacterMap {

    // MARK: - Base Vowels (lowercase)

    /// All Vietnamese vowels including modified forms
    static let vowels: Set<Character> = [
        "a", "ă", "â",
        "e", "ê",
        "i",
        "o", "ô", "ơ",
        "u", "ư",
        "y"
    ]

    /// All Vietnamese vowels uppercase
    static let vowelsUpper: Set<Character> = [
        "A", "Ă", "Â",
        "E", "Ê",
        "I",
        "O", "Ô", "Ơ",
        "U", "Ư",
        "Y"
    ]

    /// Check if a character is a Vietnamese vowel (case-insensitive)
    static func isVowel(_ char: Character) -> Bool {
        return vowels.contains(char) || vowelsUpper.contains(char)
            || isTonedVowel(char)
    }

    /// All base vowels (a, e, i, o, u, y) — no diacritics
    static let baseVowels: Set<Character> = ["a", "e", "i", "o", "u", "y"]
    static let baseVowelsUpper: Set<Character> = ["A", "E", "I", "O", "U", "Y"]

    // MARK: - Tone Marks

    /// Vietnamese tone types
    enum Tone: Int, CaseIterable {
        case none = 0    // Thanh ngang (no mark)
        case sac = 1     // Dấu sắc (acute accent) ´
        case huyen = 2   // Dấu huyền (grave accent) `
        case hoi = 3     // Dấu hỏi (hook above)
        case nga = 4     // Dấu ngã (tilde) ~
        case nang = 5    // Dấu nặng (dot below) .
    }

    // MARK: - Character Modification (Vowel Quality)

    /// Maps from base vowel to modified vowel (circumflex, breve, horn)
    enum VowelModification {
        case circumflex  // â, ê, ô
        case breve       // ă
        case horn        // ơ, ư
    }

    /// Apply vowel modification to a base character
    /// Returns nil if the modification is not valid for this character
    static func applyModification(_ char: Character, modification: VowelModification) -> Character? {
        let lower = char.lowercased().first!
        let isUpper = char.isUppercase

        let result: Character?
        switch (lower, modification) {
        case ("a", .circumflex): result = "â"
        case ("a", .breve):     result = "ă"
        case ("e", .circumflex): result = "ê"
        case ("o", .circumflex): result = "ô"
        case ("o", .horn):      result = "ơ"
        case ("u", .horn):      result = "ư"
        case ("d", _):          result = "đ"  // special case for đ
        default: result = nil
        }

        guard let r = result else { return nil }
        return isUpper ? Character(r.uppercased()) : r
    }

    /// Remove vowel modification, returning the base character
    static func removeModification(_ char: Character) -> Character {
        let lower = char.lowercased().first!
        let isUpper = char.isUppercase

        let base: Character
        switch lower {
        case "â", "ă": base = "a"
        case "ê":      base = "e"
        case "ô", "ơ": base = "o"
        case "ư":      base = "u"
        case "đ":      base = "d"
        default:       return char
        }

        return isUpper ? Character(base.uppercased()) : base
    }

    /// Check if a vowel has a quality diacritic (circumflex, breve, horn)
    static func hasQualityDiacritic(_ char: Character) -> Bool {
        let lower = char.lowercased().first!
        return ["â", "ă", "ê", "ô", "ơ", "ư"].contains(lower)
            || isTonedModifiedVowel(char)
    }

    // MARK: - Tone Application

    /// Complete mapping: (base_vowel, tone) → accented_vowel
    /// Includes all modified vowels (â, ă, ê, ô, ơ, ư) as well
    private static let toneMap: [Character: [Tone: Character]] = [
        // a
        "a": [.none: "a", .sac: "á", .huyen: "à", .hoi: "ả", .nga: "ã", .nang: "ạ"],
        "ă": [.none: "ă", .sac: "ắ", .huyen: "ằ", .hoi: "ẳ", .nga: "ẵ", .nang: "ặ"],
        "â": [.none: "â", .sac: "ấ", .huyen: "ầ", .hoi: "ẩ", .nga: "ẫ", .nang: "ậ"],
        // e
        "e": [.none: "e", .sac: "é", .huyen: "è", .hoi: "ẻ", .nga: "ẽ", .nang: "ẹ"],
        "ê": [.none: "ê", .sac: "ế", .huyen: "ề", .hoi: "ể", .nga: "ễ", .nang: "ệ"],
        // i
        "i": [.none: "i", .sac: "í", .huyen: "ì", .hoi: "ỉ", .nga: "ĩ", .nang: "ị"],
        // o
        "o": [.none: "o", .sac: "ó", .huyen: "ò", .hoi: "ỏ", .nga: "õ", .nang: "ọ"],
        "ô": [.none: "ô", .sac: "ố", .huyen: "ồ", .hoi: "ổ", .nga: "ỗ", .nang: "ộ"],
        "ơ": [.none: "ơ", .sac: "ớ", .huyen: "ờ", .hoi: "ở", .nga: "ỡ", .nang: "ợ"],
        // u
        "u": [.none: "u", .sac: "ú", .huyen: "ù", .hoi: "ủ", .nga: "ũ", .nang: "ụ"],
        "ư": [.none: "ư", .sac: "ứ", .huyen: "ừ", .hoi: "ử", .nga: "ữ", .nang: "ự"],
        // y
        "y": [.none: "y", .sac: "ý", .huyen: "ỳ", .hoi: "ỷ", .nga: "ỹ", .nang: "ỵ"],
    ]

    /// Same map but for uppercase
    private static let toneMapUpper: [Character: [Tone: Character]] = {
        var map: [Character: [Tone: Character]] = [:]
        for (key, tones) in toneMap {
            let upperKey = Character(key.uppercased())
            var upperTones: [Tone: Character] = [:]
            for (tone, char) in tones {
                upperTones[tone] = Character(char.uppercased())
            }
            map[upperKey] = upperTones
        }
        return map
    }()

    /// Apply a tone mark to a vowel character
    /// Returns the accented character, or nil if the tone cannot be applied
    static func applyTone(_ char: Character, tone: Tone) -> Character? {
        let isUpper = char.isUppercase

        // First strip any existing tone to get the base+modification vowel
        let stripped = stripTone(char)
        let strippedLower = stripped.lowercased().first!

        if isUpper {
            let upperStripped = Character(strippedLower.uppercased())
            return toneMapUpper[upperStripped]?[tone]
        } else {
            return toneMap[strippedLower]?[tone]
        }
    }

    /// Get the current tone of a character
    static func getTone(_ char: Character) -> Tone {
        let lower = char.lowercased().first!

        for (_, tones) in toneMap {
            for (tone, toneChar) in tones {
                if toneChar == lower {
                    return tone
                }
            }
        }
        return .none
    }

    /// Strip tone mark from a character, keeping the vowel quality diacritic
    /// e.g., 'ấ' → 'â', 'ắ' → 'ă', 'á' → 'a'
    static func stripTone(_ char: Character) -> Character {
        let lower = char.lowercased().first!
        let isUpper = char.isUppercase

        for (baseVowel, tones) in toneMap {
            for (_, toneChar) in tones {
                if toneChar == lower {
                    let result = baseVowel
                    return isUpper ? Character(result.uppercased()) : result
                }
            }
        }
        return char
    }

    /// Check if a character is a toned vowel (has a tone mark)
    static func isTonedVowel(_ char: Character) -> Bool {
        let tone = getTone(char)
        return tone != .none
    }

    /// Check if character is a toned+modified vowel (e.g., ấ, ắ, ế, etc.)
    static func isTonedModifiedVowel(_ char: Character) -> Bool {
        let stripped = stripTone(char)
        let lower = stripped.lowercased().first!
        return ["â", "ă", "ê", "ô", "ơ", "ư"].contains(lower)
    }

    // MARK: - Vietnamese Alphabet Check

    /// All consonant characters in Vietnamese
    static let consonants: Set<Character> = [
        "b", "c", "d", "đ", "g", "h", "k", "l", "m",
        "n", "p", "q", "r", "s", "t", "v", "x"
    ]

    /// Check if a character is a Vietnamese letter (vowel or consonant)
    static func isVietnameseLetter(_ char: Character) -> Bool {
        if char.isLetter {
            let lower = char.lowercased().first!
            if consonants.contains(lower) { return true }
            if isVowel(char) { return true }
            // Also check for đ
            if lower == "đ" { return true }
            // f, w, j, z are used in Telex as modifiers but are not Vietnamese letters
            // They ARE alpha characters though, so we need to handle them
            return false
        }
        return false
    }

    /// Check if a character is an ASCII letter (used for composition)
    static func isAlphabetic(_ char: Character) -> Bool {
        return char.isLetter
    }

    // MARK: - TCVN3 / VNI Encoding Support

    /// Unicode to TCVN3 conversion table (simplified — most common chars)
    static let unicodeToTCVN3: [Character: UInt8] = [
        "À": 0xC0, "Á": 0xC1, "Â": 0xC2, "Ã": 0xC3,
        // Full table would be populated here for production
    ]

    /// Unicode to VNI Windows conversion table
    static let unicodeToVNI: [Character: String] = [
        "á": "a\u{0301}", "à": "a\u{0300}",
        // Full table would be populated here for production
    ]
}
