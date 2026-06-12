import Foundation

/// Application-wide constants for GoTiengViet
enum AppConstants {
    static let appName = "Gõ Tiếng Việt"
    static let bundleIdentifier = "com.govietnamese.inputmethod.GoTiengViet"
    static let connectionName = "com.govietnamese.inputmethod.GoTiengViet_Connection"
    static let version = "1.0.0"

    // MARK: - UserDefaults Keys
    enum Prefs {
        static let inputMethod = "inputMethod"              // "telex" | "vni"
        static let toneStyle = "toneStyle"                  // "old" | "new"
        static let outputEncoding = "outputEncoding"        // "unicode" | "tcvn3" | "vni"
        static let spellCheckEnabled = "spellCheckEnabled"
        static let autoRestoreEnabled = "autoRestoreEnabled"
        static let secureFieldBypass = "secureFieldBypass"
        static let vietnameseEnabled = "vietnameseEnabled"
        static let macroEnabled = "macroEnabled"
        static let macroData = "macroData"
        static let switchHotkey = "switchHotkey"
        static let perAppSettings = "perAppSettings"
    }

    // MARK: - Input Method Types
    enum InputMethod: String, CaseIterable {
        case telex = "telex"
        case vni = "vni"

        var displayName: String {
            switch self {
            case .telex: return "Telex"
            case .vni: return "VNI"
            }
        }
    }

    // MARK: - Tone Placement Style
    enum ToneStyle: String, CaseIterable {
        case old = "old"    // Traditional: hòa
        case new = "new"    // Modern/Linguistic: hoà

        var displayName: String {
            switch self {
            case .old: return "Kiểu cũ (hòa)"
            case .new: return "Kiểu mới (hoà)"
            }
        }
    }

    // MARK: - Output Encoding
    enum OutputEncoding: String, CaseIterable {
        case unicode = "unicode"
        case tcvn3 = "tcvn3"
        case vniWindows = "vni"

        var displayName: String {
            switch self {
            case .unicode: return "Unicode"
            case .tcvn3: return "TCVN3 (ABC)"
            case .vniWindows: return "VNI Windows"
            }
        }
    }

    // MARK: - Composition Limits
    static let maxBufferLength = 12
    static let maxSyllableLength = 8
}
