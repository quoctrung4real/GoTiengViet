import XCTest
@testable import GoTiengVietEngine

/// Integration tests for the full VietnameseEngine
/// Tests end-to-end typing scenarios
final class VietnameseEngineTests: XCTestCase {

    // MARK: - Helper

    func typeFullSequence(_ input: String, method: AppConstants.InputMethod = .telex, toneStyle: AppConstants.ToneStyle = .new) -> String {
        let engine = VietnameseEngine(inputMethod: method, toneStyle: toneStyle)
        var result = ""

        for char in input {
            let engineResult = engine.processKey(char)
            switch engineResult {
            case .compositionUpdated:
                break // Still composing
            case .commitText(let text):
                result += text
            case .commitAndPassthrough(let text):
                result += text
            case .passthrough:
                // Non-Vietnamese character
                if engine.hasComposition {
                    let commit = engine.forceCommit()
                    if case .commitText(let text) = commit {
                        result += text
                    }
                }
                result += String(char)
            default:
                break
            }
        }

        // Commit any remaining composition
        if engine.hasComposition {
            let commit = engine.forceCommit()
            if case .commitText(let text) = commit {
                result += text
            }
        }

        return result
    }

    // MARK: - Telex Full Sentence Tests

    func test_telex_xin_chao() {
        let result = typeFullSequence("xin chaof")
        XCTAssertEqual(result, "xin chào")
    }

    func test_telex_toi_la() {
        let result = typeFullSequence("tooi laf")
        XCTAssertEqual(result, "tôi là")
    }

    func test_telex_tieng_viet() {
        let result = typeFullSequence("tieengs vieejt")
        XCTAssertEqual(result, "tiếng việt")
    }

    // MARK: - VNI Full Sentence Tests

    func test_vni_xin_chao() {
        let result = typeFullSequence("xin cha2o", method: .vni)
        XCTAssertEqual(result, "xin chào")
    }

    // MARK: - Vietnamese Mode Toggle

    func test_engine_disabled_passthrough() {
        let engine = VietnameseEngine(inputMethod: .telex)
        engine.isVietnameseEnabled = false

        let result = engine.processKey("s")
        XCTAssertEqual(result, .passthrough)
    }

    // MARK: - Buffer Reset on Space

    func test_buffer_reset_on_space() {
        let engine = VietnameseEngine(inputMethod: .telex)

        // Type "ca" — should be composing
        _ = engine.processKey("c")
        _ = engine.processKey("a")
        XCTAssertTrue(engine.hasComposition)

        // Type space — should commit
        let result = engine.processKey(" ")
        if case .commitText(let text) = result {
            XCTAssertEqual(text, "ca ")
        }
        XCTAssertFalse(engine.hasComposition)
    }

    // MARK: - Backspace Tests

    func test_backspace_removes_last_char() {
        let engine = VietnameseEngine(inputMethod: .telex)

        _ = engine.processKey("c")
        _ = engine.processKey("a")
        _ = engine.processKey("s") // "cá"

        let result = engine.processBackspace()
        // Should remove the last raw character, effectively removing the tone
        XCTAssertNotEqual(result, .passthrough)
    }

    func test_backspace_empty_buffer_passthrough() {
        let engine = VietnameseEngine(inputMethod: .telex)
        let result = engine.processBackspace()
        XCTAssertEqual(result, .passthrough)
    }

    // MARK: - Force Commit

    func test_force_commit_with_content() {
        let engine = VietnameseEngine(inputMethod: .telex)
        _ = engine.processKey("c")
        _ = engine.processKey("a")

        let result = engine.forceCommit()
        if case .commitText(let text) = result {
            XCTAssertEqual(text, "ca")
        } else {
            XCTFail("Expected commitText")
        }
    }

    func test_force_commit_empty_buffer() {
        let engine = VietnameseEngine(inputMethod: .telex)
        let result = engine.forceCommit()
        XCTAssertEqual(result, .nothing)
    }
}

// MARK: - EngineResult Equatable
extension EngineResult: Equatable {
    public static func == (lhs: EngineResult, rhs: EngineResult) -> Bool {
        switch (lhs, rhs) {
        case (.nothing, .nothing): return true
        case (.compositionCleared, .compositionCleared): return true
        case (.passthrough, .passthrough): return true
        case (.compositionUpdated(let a), .compositionUpdated(let b)): return a == b
        case (.commitText(let a), .commitText(let b)): return a == b
        case (.commitAndPassthrough(let a), .commitAndPassthrough(let b)): return a == b
        default: return false
        }
    }
}
