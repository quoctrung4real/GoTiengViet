import Foundation

/// Centralized preferences manager
/// Uses UserDefaults for persistence with default values
class PreferencesManager {

    /// Shared singleton instance
    static let shared = PreferencesManager()

    /// Notification posted when preferences change
    static let preferencesDidChangeNotification = Notification.Name("GoTiengVietPreferencesDidChange")

    private let defaults = UserDefaults.standard

    // MARK: - Initialization

    private init() {
        registerDefaults()
    }

    /// Register default values for all preferences
    private func registerDefaults() {
        defaults.register(defaults: [
            AppConstants.Prefs.inputMethod: AppConstants.InputMethod.telex.rawValue,
            AppConstants.Prefs.toneStyle: AppConstants.ToneStyle.new.rawValue,
            AppConstants.Prefs.outputEncoding: AppConstants.OutputEncoding.unicode.rawValue,
            AppConstants.Prefs.spellCheckEnabled: false,
            AppConstants.Prefs.autoRestoreEnabled: false,
            AppConstants.Prefs.secureFieldBypass: true,
            AppConstants.Prefs.vietnameseEnabled: true,
            AppConstants.Prefs.macroEnabled: true,
            AppConstants.Prefs.osdEnabled: true,
        ])
    }

    // MARK: - Properties

    var inputMethod: AppConstants.InputMethod {
        get {
            let raw = defaults.string(forKey: AppConstants.Prefs.inputMethod) ?? "telex"
            return AppConstants.InputMethod(rawValue: raw) ?? .telex
        }
        set {
            defaults.set(newValue.rawValue, forKey: AppConstants.Prefs.inputMethod)
            notifyChange()
        }
    }

    var toneStyle: AppConstants.ToneStyle {
        get {
            let raw = defaults.string(forKey: AppConstants.Prefs.toneStyle) ?? "new"
            return AppConstants.ToneStyle(rawValue: raw) ?? .new
        }
        set {
            defaults.set(newValue.rawValue, forKey: AppConstants.Prefs.toneStyle)
            notifyChange()
        }
    }

    var outputEncoding: AppConstants.OutputEncoding {
        get {
            let raw = defaults.string(forKey: AppConstants.Prefs.outputEncoding) ?? "unicode"
            return AppConstants.OutputEncoding(rawValue: raw) ?? .unicode
        }
        set {
            defaults.set(newValue.rawValue, forKey: AppConstants.Prefs.outputEncoding)
            notifyChange()
        }
    }

    var spellCheckEnabled: Bool {
        get { defaults.bool(forKey: AppConstants.Prefs.spellCheckEnabled) }
        set {
            defaults.set(newValue, forKey: AppConstants.Prefs.spellCheckEnabled)
            notifyChange()
        }
    }

    var autoRestoreEnabled: Bool {
        get { defaults.bool(forKey: AppConstants.Prefs.autoRestoreEnabled) }
        set {
            defaults.set(newValue, forKey: AppConstants.Prefs.autoRestoreEnabled)
            notifyChange()
        }
    }

    var secureFieldBypass: Bool {
        get { defaults.bool(forKey: AppConstants.Prefs.secureFieldBypass) }
        set {
            defaults.set(newValue, forKey: AppConstants.Prefs.secureFieldBypass)
            notifyChange()
        }
    }

    var vietnameseEnabled: Bool {
        get { defaults.bool(forKey: AppConstants.Prefs.vietnameseEnabled) }
        set {
            defaults.set(newValue, forKey: AppConstants.Prefs.vietnameseEnabled)
            // Don't notify change for this — it's a runtime state
        }
    }

    var macroEnabled: Bool {
        get { defaults.bool(forKey: AppConstants.Prefs.macroEnabled) }
        set {
            defaults.set(newValue, forKey: AppConstants.Prefs.macroEnabled)
            notifyChange()
        }
    }

    var osdEnabled: Bool {
        get { defaults.bool(forKey: AppConstants.Prefs.osdEnabled) }
        set {
            defaults.set(newValue, forKey: AppConstants.Prefs.osdEnabled)
            notifyChange()
        }
    }

    // MARK: - Change Notification

    private func notifyChange() {
        NotificationCenter.default.post(
            name: PreferencesManager.preferencesDidChangeNotification,
            object: nil
        )
    }
}
