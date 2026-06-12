import Foundation

/// Detects which application is currently focused
/// and provides per-app settings
class ClientAppDetector {

    /// Per-app Vietnamese mode settings
    /// Key: bundle identifier, Value: whether Vietnamese is enabled
    private var perAppSettings: [String: Bool] = [:]

    /// Whether per-app mode is enabled
    var perAppModeEnabled: Bool = false

    /// The current client app's bundle identifier
    private(set) var currentAppBundleId: String?

    // MARK: - App Detection

    /// Update the current app from the client
    /// - Parameter bundleId: The bundle identifier of the active client
    func updateCurrentApp(bundleId: String?) {
        currentAppBundleId = bundleId
        if let id = bundleId {
            Log.input("Current app: \(id)")
        }
    }

    // MARK: - Per-App Settings

    /// Get the Vietnamese mode setting for the current app
    /// - Returns: true if Vietnamese should be enabled, nil if no per-app setting
    func getVietnameseMode() -> Bool? {
        guard perAppModeEnabled, let appId = currentAppBundleId else {
            return nil
        }
        return perAppSettings[appId]
    }

    /// Set the Vietnamese mode for the current app
    /// - Parameter enabled: Whether Vietnamese should be enabled
    func setVietnameseMode(enabled: Bool) {
        guard perAppModeEnabled, let appId = currentAppBundleId else {
            return
        }
        perAppSettings[appId] = enabled
        Log.input("Per-app setting for \(appId): Vietnamese = \(enabled)")
    }

    /// Load per-app settings from UserDefaults
    func loadSettings() {
        if let saved = UserDefaults.standard.dictionary(forKey: AppConstants.Prefs.perAppSettings) as? [String: Bool] {
            perAppSettings = saved
        }
    }

    /// Save per-app settings to UserDefaults
    func saveSettings() {
        UserDefaults.standard.set(perAppSettings, forKey: AppConstants.Prefs.perAppSettings)
    }

    // MARK: - Known App Workarounds

    /// Check if the current app needs special composition handling
    /// Some Electron/Chromium apps have issues with setMarkedText
    var needsDirectInsert: Bool {
        guard let appId = currentAppBundleId else { return false }

        // Known problematic apps that don't handle marked text well
        let directInsertApps: Set<String> = [
            // These tend to have composition issues
            // Add app bundle IDs here as discovered during testing
        ]

        return directInsertApps.contains(appId)
    }

    /// Check if the current app uses raw terminal mode
    var isTerminalApp: Bool {
        guard let appId = currentAppBundleId else { return false }

        let terminalApps: Set<String> = [
            "com.apple.Terminal",
            "com.googlecode.iterm2",
            "io.alacritty",
            "com.github.wez.wezterm",
            "net.kovidgoyal.kitty"
        ]

        return terminalApps.contains(appId)
    }
}
