import XCTest
@testable import GoTiengVietEngine

/// Critical tests for tone placement algorithm
/// Tests both old-style (traditional) and new-style (linguistic) placement
final class TonePlacementTests: XCTestCase {

    var oldStyle: TonePlacement!
    var newStyle: TonePlacement!

    override func setUp() {
        super.setUp()
        oldStyle = TonePlacement(style: .old)
        newStyle = TonePlacement(style: .new)
    }

    // MARK: - Decomposition Tests

    func test_decompose_simple() {
        let syllable = newStyle.decompose("can")
        XCTAssertNotNil(syllable)
        XCTAssertEqual(syllable?.initial, "c")
        XCTAssertEqual(syllable?.vowelCluster, "a")
        XCTAssertEqual(syllable?.final_, "n")
    }

    func test_decompose_complex_initial() {
        let syllable = newStyle.decompose("nghiên")
        XCTAssertNotNil(syllable)
        XCTAssertEqual(syllable?.initial, "ngh")
    }

    func test_decompose_no_initial() {
        let syllable = newStyle.decompose("an")
        XCTAssertNotNil(syllable)
        XCTAssertEqual(syllable?.initial, "")
        XCTAssertEqual(syllable?.vowelCluster, "a")
        XCTAssertEqual(syllable?.final_, "n")
    }

    func test_decompose_no_final() {
        let syllable = newStyle.decompose("ba")
        XCTAssertNotNil(syllable)
        XCTAssertEqual(syllable?.initial, "b")
        XCTAssertEqual(syllable?.vowelCluster, "a")
        XCTAssertEqual(syllable?.final_, "")
    }

    func test_decompose_vowel_cluster() {
        let syllable = newStyle.decompose("hoa")
        XCTAssertNotNil(syllable)
        XCTAssertEqual(syllable?.initial, "h")
        XCTAssertEqual(syllable?.vowelCluster, "oa")
        XCTAssertEqual(syllable?.final_, "")
    }

    // MARK: - Tone Placement: Priority Rule
    // If a vowel has a quality diacritic, tone MUST go on it

    func test_thue_always_on_ê() {
        // "thuê" + sắc → "thuế" — tone always on ê
        let result = newStyle.applyTone(to: "thuê", tone: .sac)
        XCTAssertEqual(result, "thuế")

        let resultOld = oldStyle.applyTone(to: "thuê", tone: .sac)
        XCTAssertEqual(resultOld, "thuế")
    }

    func test_muon_always_on_ô() {
        // "muôn" + sắc → "muốn"
        let result = newStyle.applyTone(to: "muôn", tone: .sac)
        XCTAssertEqual(result, "muốn")
    }

    func test_tuong_on_ư() {
        // "tương" + huyền → "tường" — tone on ư (has quality diacritic = horn)
        let result = newStyle.applyTone(to: "tương", tone: .huyen)
        XCTAssertEqual(result, "tường")
    }

    // MARK: - Old Style Tests (Traditional)

    func test_hoa_old_no_final() {
        // hoa + huyền: "hòa" (dấu trên o — next-to-last vowel)
        let result = oldStyle.applyTone(to: "hoa", tone: .huyen)
        XCTAssertEqual(result, "hòa")
    }

    func test_hoan_old_with_final() {
        // hoan + huyền: "hoàn" (dấu trên a — last vowel)
        let result = oldStyle.applyTone(to: "hoan", tone: .huyen)
        XCTAssertEqual(result, "hoàn")
    }

    func test_huy_old() {
        // huy + hỏi: "hủy" (dấu trên u — next-to-last)
        let result = oldStyle.applyTone(to: "huy", tone: .hoi)
        XCTAssertEqual(result, "hủy")
    }

    // MARK: - New Style Tests (Linguistic)

    func test_hoa_new_no_final() {
        // hoa + huyền: "hoà" (dấu trên a — main vowel/nucleus)
        let result = newStyle.applyTone(to: "hoa", tone: .huyen)
        XCTAssertEqual(result, "hoà")
    }

    func test_hoan_new_with_final() {
        // hoan + huyền: "hoàn" (dấu trên a — same as old style when final present)
        let result = newStyle.applyTone(to: "hoan", tone: .huyen)
        XCTAssertEqual(result, "hoàn")
    }

    func test_huy_new() {
        // huy + hỏi: "huỷ" (dấu trên y — nucleus vowel)
        let result = newStyle.applyTone(to: "huy", tone: .hoi)
        XCTAssertEqual(result, "huỷ")
    }

    // MARK: - Single Vowel Tests

    func test_single_vowel_tone() {
        XCTAssertEqual(newStyle.applyTone(to: "a", tone: .sac), "á")
        XCTAssertEqual(newStyle.applyTone(to: "ca", tone: .sac), "cá")
        XCTAssertEqual(newStyle.applyTone(to: "can", tone: .sac), "cán")
    }

    // MARK: - Special Cases

    func test_gia() {
        // gi as initial consonant → tone on a
        let result = newStyle.applyTone(to: "gia", tone: .sac)
        XCTAssertEqual(result, "giá")
    }

    func test_qua() {
        // qu as initial consonant → tone on a
        let result = newStyle.applyTone(to: "qua", tone: .sac)
        XCTAssertEqual(result, "quá")
    }

    // MARK: - Remove Tone Tests

    func test_remove_tone() {
        let result = newStyle.removeTone(from: "cá")
        XCTAssertEqual(result, "ca")
    }

    func test_remove_tone_preserves_quality() {
        // "ấ" → "â" (keeps circumflex, removes sắc)
        let result = newStyle.removeTone(from: "ấ")
        XCTAssertEqual(result, "â")
    }

    func test_remove_tone_full_word() {
        let result = newStyle.removeTone(from: "thuế")
        XCTAssertEqual(result, "thuê")
    }
}
