import XCTest
@testable import GoTiengVietEngine

/// Tests for the CharacterMap utility
final class CharacterMapTests: XCTestCase {

    // MARK: - Tone Application

    func test_apply_sac_to_a() {
        XCTAssertEqual(CharacterMap.applyTone("a", tone: .sac), "á")
    }

    func test_apply_huyen_to_a() {
        XCTAssertEqual(CharacterMap.applyTone("a", tone: .huyen), "à")
    }

    func test_apply_hoi_to_a() {
        XCTAssertEqual(CharacterMap.applyTone("a", tone: .hoi), "ả")
    }

    func test_apply_nga_to_a() {
        XCTAssertEqual(CharacterMap.applyTone("a", tone: .nga), "ã")
    }

    func test_apply_nang_to_a() {
        XCTAssertEqual(CharacterMap.applyTone("a", tone: .nang), "ạ")
    }

    func test_apply_tone_to_â() {
        XCTAssertEqual(CharacterMap.applyTone("â", tone: .sac), "ấ")
    }

    func test_apply_tone_to_ă() {
        XCTAssertEqual(CharacterMap.applyTone("ă", tone: .sac), "ắ")
    }

    func test_apply_tone_to_ê() {
        XCTAssertEqual(CharacterMap.applyTone("ê", tone: .sac), "ế")
    }

    func test_apply_tone_to_ô() {
        XCTAssertEqual(CharacterMap.applyTone("ô", tone: .sac), "ố")
    }

    func test_apply_tone_to_ơ() {
        XCTAssertEqual(CharacterMap.applyTone("ơ", tone: .sac), "ớ")
    }

    func test_apply_tone_to_ư() {
        XCTAssertEqual(CharacterMap.applyTone("ư", tone: .sac), "ứ")
    }

    func test_apply_tone_to_y() {
        XCTAssertEqual(CharacterMap.applyTone("y", tone: .sac), "ý")
    }

    // MARK: - Tone Uppercase

    func test_apply_tone_uppercase() {
        XCTAssertEqual(CharacterMap.applyTone("A", tone: .sac), "Á")
        XCTAssertEqual(CharacterMap.applyTone("Â", tone: .sac), "Ấ")
    }

    // MARK: - Get Tone

    func test_get_tone_from_á() {
        XCTAssertEqual(CharacterMap.getTone("á"), .sac)
    }

    func test_get_tone_from_ầ() {
        XCTAssertEqual(CharacterMap.getTone("ầ"), .huyen)
    }

    func test_get_tone_from_plain_a() {
        XCTAssertEqual(CharacterMap.getTone("a"), .none)
    }

    // MARK: - Strip Tone

    func test_strip_tone_á() {
        XCTAssertEqual(CharacterMap.stripTone("á"), "a")
    }

    func test_strip_tone_ấ() {
        XCTAssertEqual(CharacterMap.stripTone("ấ"), "â")
    }

    func test_strip_tone_ắ() {
        XCTAssertEqual(CharacterMap.stripTone("ắ"), "ă")
    }

    func test_strip_tone_ế() {
        XCTAssertEqual(CharacterMap.stripTone("ế"), "ê")
    }

    func test_strip_tone_preserves_plain() {
        XCTAssertEqual(CharacterMap.stripTone("a"), "a")
        XCTAssertEqual(CharacterMap.stripTone("â"), "â")
    }

    // MARK: - Vowel Modification

    func test_apply_circumflex() {
        XCTAssertEqual(CharacterMap.applyModification("a", modification: .circumflex), "â")
        XCTAssertEqual(CharacterMap.applyModification("e", modification: .circumflex), "ê")
        XCTAssertEqual(CharacterMap.applyModification("o", modification: .circumflex), "ô")
    }

    func test_apply_breve() {
        XCTAssertEqual(CharacterMap.applyModification("a", modification: .breve), "ă")
    }

    func test_apply_horn() {
        XCTAssertEqual(CharacterMap.applyModification("o", modification: .horn), "ơ")
        XCTAssertEqual(CharacterMap.applyModification("u", modification: .horn), "ư")
    }

    func test_invalid_modification() {
        // 'e' cannot have breve
        XCTAssertNil(CharacterMap.applyModification("e", modification: .breve))
        // 'a' cannot have horn
        XCTAssertNil(CharacterMap.applyModification("a", modification: .horn))
    }

    // MARK: - Vowel Detection

    func test_isVowel() {
        XCTAssertTrue(CharacterMap.isVowel("a"))
        XCTAssertTrue(CharacterMap.isVowel("ă"))
        XCTAssertTrue(CharacterMap.isVowel("â"))
        XCTAssertTrue(CharacterMap.isVowel("ê"))
        XCTAssertTrue(CharacterMap.isVowel("ư"))
        XCTAssertTrue(CharacterMap.isVowel("á"))  // toned vowel
        XCTAssertTrue(CharacterMap.isVowel("ấ"))  // toned + modified vowel
        XCTAssertFalse(CharacterMap.isVowel("b"))
        XCTAssertFalse(CharacterMap.isVowel("d"))
    }

    func test_hasQualityDiacritic() {
        XCTAssertTrue(CharacterMap.hasQualityDiacritic("â"))
        XCTAssertTrue(CharacterMap.hasQualityDiacritic("ă"))
        XCTAssertTrue(CharacterMap.hasQualityDiacritic("ê"))
        XCTAssertTrue(CharacterMap.hasQualityDiacritic("ô"))
        XCTAssertTrue(CharacterMap.hasQualityDiacritic("ơ"))
        XCTAssertTrue(CharacterMap.hasQualityDiacritic("ư"))
        XCTAssertFalse(CharacterMap.hasQualityDiacritic("a"))
        XCTAssertFalse(CharacterMap.hasQualityDiacritic("e"))
    }
}
