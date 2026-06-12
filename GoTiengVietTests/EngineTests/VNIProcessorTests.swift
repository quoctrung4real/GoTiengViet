import XCTest
@testable import GoTiengVietEngine

/// Comprehensive tests for the VNI input processor
final class VNIProcessorTests: XCTestCase {

    var processor: VNIProcessor!
    var tonePlacement: TonePlacement!

    override func setUp() {
        super.setUp()
        processor = VNIProcessor()
        tonePlacement = TonePlacement(style: .new)
    }

    // MARK: - Helper

    func typeVNI(_ input: String) -> String {
        var buffer: [Character] = []
        var composed: String = ""

        for char in input {
            _ = processor.processKey(char, buffer: &buffer, composed: &composed, tonePlacement: tonePlacement)
        }
        return composed
    }

    // MARK: - Vowel Modification Tests (6, 7, 8)

    func test_a6_produces_â() {
        XCTAssertEqual(typeVNI("ca6n"), "cân")
    }

    func test_e6_produces_ê() {
        XCTAssertEqual(typeVNI("te6n"), "tên")
    }

    func test_o6_produces_ô() {
        XCTAssertEqual(typeVNI("co6n"), "côn")
    }

    func test_a8_produces_ă() {
        XCTAssertEqual(typeVNI("ta8m"), "tăm")
    }

    func test_o7_produces_ơ() {
        XCTAssertEqual(typeVNI("mo7"), "mơ")
    }

    func test_u7_produces_ư() {
        XCTAssertEqual(typeVNI("mu7"), "mư")
    }

    func test_d9_produces_đ() {
        XCTAssertEqual(typeVNI("d9i"), "đi")
    }

    // MARK: - Tone Mark Tests (1-5)

    func test_1_adds_sac() {
        XCTAssertEqual(typeVNI("ca1"), "cá")
    }

    func test_2_adds_huyen() {
        XCTAssertEqual(typeVNI("ca2"), "cà")
    }

    func test_3_adds_hoi() {
        XCTAssertEqual(typeVNI("ca3"), "cả")
    }

    func test_4_adds_nga() {
        XCTAssertEqual(typeVNI("ca4"), "cã")
    }

    func test_5_adds_nang() {
        XCTAssertEqual(typeVNI("ca5"), "cạ")
    }

    // MARK: - Complex Words

    func test_complex_word_vni_thuong() {
        XCTAssertEqual(typeVNI("thu7o72ng"), "thường")
    }

    func test_complex_word_vni_viet() {
        XCTAssertEqual(typeVNI("vie65t"), "việt")
    }

    // MARK: - Edge Cases

    func test_number_without_vowels() {
        // Numbers should passthrough when no vowels present
        var buffer: [Character] = []
        var composed: String = ""

        // Just "b" in buffer — no vowels
        _ = processor.processKey("b", buffer: &buffer, composed: &composed, tonePlacement: tonePlacement)
        let result = processor.processKey("1", buffer: &buffer, composed: &composed, tonePlacement: tonePlacement)
        XCTAssertEqual(result, .passthrough)
    }

    func test_empty_buffer_number() {
        var buffer: [Character] = []
        var composed: String = ""
        let result = processor.processKey("1", buffer: &buffer, composed: &composed, tonePlacement: tonePlacement)
        XCTAssertEqual(result, .passthrough)
    }

    func test_single_vowel_with_tone() {
        XCTAssertEqual(typeVNI("a1"), "á")
    }

    func test_uppercase_preserved() {
        XCTAssertEqual(typeVNI("D9i"), "Đi")
    }
}
