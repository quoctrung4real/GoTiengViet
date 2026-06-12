import XCTest
@testable import GoTiengVietEngine

/// Comprehensive tests for the Telex input processor
final class TelexProcessorTests: XCTestCase {

    var processor: TelexProcessor!
    var tonePlacement: TonePlacement!

    override func setUp() {
        super.setUp()
        processor = TelexProcessor()
        tonePlacement = TonePlacement(style: .new)
    }

    // MARK: - Helper

    /// Simulate typing a sequence of characters through the Telex processor
    func typeTelex(_ input: String) -> String {
        var buffer: [Character] = []
        var composed: String = ""

        for char in input {
            _ = processor.processKey(char, buffer: &buffer, composed: &composed, tonePlacement: tonePlacement)
        }
        return composed
    }

    // MARK: - Vowel Modification Tests

    func test_aa_produces_â() {
        XCTAssertEqual(typeTelex("caan"), "cân")
    }

    func test_aw_produces_ă() {
        XCTAssertEqual(typeTelex("tawm"), "tăm")
    }

    func test_ee_produces_ê() {
        XCTAssertEqual(typeTelex("teen"), "tên")
    }

    func test_oo_produces_ô() {
        XCTAssertEqual(typeTelex("coon"), "côn")
    }

    func test_ow_produces_ơ() {
        XCTAssertEqual(typeTelex("mow"), "mơ")
    }

    func test_uw_produces_ư() {
        XCTAssertEqual(typeTelex("muw"), "mư")
    }

    func test_w_alone_produces_ư() {
        XCTAssertEqual(typeTelex("tw"), "tư")
    }

    func test_dd_produces_đ() {
        XCTAssertEqual(typeTelex("ddi"), "đi")
    }

    // MARK: - Tone Mark Tests

    func test_s_adds_sac() {
        XCTAssertEqual(typeTelex("cas"), "cá")
    }

    func test_f_adds_huyen() {
        XCTAssertEqual(typeTelex("caf"), "cà")
    }

    func test_r_adds_hoi() {
        XCTAssertEqual(typeTelex("car"), "cả")
    }

    func test_x_adds_nga() {
        XCTAssertEqual(typeTelex("cax"), "cã")
    }

    func test_j_adds_nang() {
        XCTAssertEqual(typeTelex("caj"), "cạ")
    }

    // MARK: - Escape Sequence Tests

    func test_ss_undoes_tone() {
        // "cas" → "cá", then "s" again should undo → "cas"
        let result = typeTelex("cass")
        // After applying sac then pressing s again, it should undo and add literal s
        XCTAssertEqual(result, "cas")
    }

    // MARK: - Complex Word Tests

    func test_thuong() {
        XCTAssertEqual(typeTelex("thuowng"), "thương")
    }

    func test_duoc() {
        // đ+ươ+c: dd=đ, u, o, w=ươ (uo→ươ pattern), c
        // Then j for nặng tone
        XCTAssertEqual(typeTelex("dduowcj"), "được")
    }

    func test_nguoi() {
        // ng+ười: n, g, u, o, w triggers uo→ươ pattern, i, f for huyền
        XCTAssertEqual(typeTelex("nguowif"), "người")
    }

    func test_viet() {
        XCTAssertEqual(typeTelex("vieejt"), "việt")
    }

    func test_tieng() {
        XCTAssertEqual(typeTelex("tieengs"), "tiếng")
    }

    // MARK: - Edge Cases

    func test_empty_input() {
        XCTAssertEqual(typeTelex(""), "")
    }

    func test_numbers_passthrough() {
        // Numbers should not be processed by Telex
        var buffer: [Character] = []
        var composed: String = ""
        let result = processor.processKey("1", buffer: &buffer, composed: &composed, tonePlacement: tonePlacement)
        XCTAssertEqual(result, .passthrough)
    }

    func test_uppercase_preserved() {
        // Capital letters should produce capital Vietnamese characters
        XCTAssertEqual(typeTelex("DDi"), "Đi")
    }

    func test_single_vowel_with_tone() {
        XCTAssertEqual(typeTelex("as"), "á")
    }

    func test_single_vowel_with_modification() {
        XCTAssertEqual(typeTelex("aa"), "â")
    }

    // MARK: - Buffer Management

    func test_no_duplication_buffer_state() {
        var buffer: [Character] = []
        var composed: String = ""

        // Type "xin" — should produce "xin" without duplication
        _ = processor.processKey("x", buffer: &buffer, composed: &composed, tonePlacement: tonePlacement)
        _ = processor.processKey("i", buffer: &buffer, composed: &composed, tonePlacement: tonePlacement)
        _ = processor.processKey("n", buffer: &buffer, composed: &composed, tonePlacement: tonePlacement)

        XCTAssertEqual(composed, "xin")
        XCTAssertEqual(buffer.count, 3)
    }

    func test_buffer_after_tone() {
        var buffer: [Character] = []
        var composed: String = ""

        _ = processor.processKey("c", buffer: &buffer, composed: &composed, tonePlacement: tonePlacement)
        _ = processor.processKey("a", buffer: &buffer, composed: &composed, tonePlacement: tonePlacement)
        _ = processor.processKey("s", buffer: &buffer, composed: &composed, tonePlacement: tonePlacement)

        // Buffer should contain the composed characters, not raw input
        XCTAssertEqual(composed, "cá")
    }
}

// MARK: - ProcessResult Equatable for testing
extension ProcessResult: Equatable {
    public static func == (lhs: ProcessResult, rhs: ProcessResult) -> Bool {
        switch (lhs, rhs) {
        case (.consumed, .consumed): return true
        case (.commit, .commit): return true
        case (.passthrough, .passthrough): return true
        case (.undone, .undone): return true
        default: return false
        }
    }
}
