import XCTest
@testable import GoTiengVietEngine

/// Tests for the SpellChecker
final class SpellCheckerTests: XCTestCase {

    var checker: SpellChecker!

    override func setUp() {
        super.setUp()
        checker = SpellChecker()
    }

    // MARK: - Valid Syllables

    func test_valid_simple_syllables() {
        XCTAssertTrue(checker.isValidSyllable("ba"))
        XCTAssertTrue(checker.isValidSyllable("can"))
        XCTAssertTrue(checker.isValidSyllable("hoc"))
        XCTAssertTrue(checker.isValidSyllable("nam"))
    }

    func test_valid_complex_syllables() {
        XCTAssertTrue(checker.isValidSyllable("nghiên"))
        XCTAssertTrue(checker.isValidSyllable("thương"))
        XCTAssertTrue(checker.isValidSyllable("khuyên"))
    }

    func test_valid_with_tones() {
        XCTAssertTrue(checker.isValidSyllable("cá"))
        XCTAssertTrue(checker.isValidSyllable("thuế"))
        XCTAssertTrue(checker.isValidSyllable("được"))
    }

    func test_valid_no_initial() {
        XCTAssertTrue(checker.isValidSyllable("an"))
        XCTAssertTrue(checker.isValidSyllable("em"))
    }

    // MARK: - Invalid Syllables

    func test_invalid_consonant_cluster() {
        XCTAssertFalse(checker.isValidSyllable("bng"))
        XCTAssertFalse(checker.isValidSyllable("xyz"))
    }

    func test_empty_string() {
        XCTAssertFalse(checker.isValidSyllable(""))
    }

    // MARK: - looksVietnamese

    func test_looks_vietnamese_with_special_chars() {
        XCTAssertTrue(checker.looksVietnamese("đi"))
        XCTAssertTrue(checker.looksVietnamese("ăn"))
        XCTAssertTrue(checker.looksVietnamese("cá"))
    }

    func test_does_not_look_vietnamese() {
        XCTAssertFalse(checker.looksVietnamese("hello"))
        XCTAssertFalse(checker.looksVietnamese("code"))
    }
}
