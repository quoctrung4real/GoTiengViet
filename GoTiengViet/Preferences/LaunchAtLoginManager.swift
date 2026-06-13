import Foundation
import ServiceManagement

/// Manages "Launch at Login" functionality
/// Uses SMAppService for macOS 13+ or falls back to legacy SMLoginItemSetEnabled
class LaunchAtLoginManager {

    /// Shared singleton
    static let shared = LaunchAtLoginManager()

    private let defaults = UserDefaults.standard
    private let storageKey = "launchAtLogin"

    private init() {}

    /// Whether launch at login is currently enabled
    var isEnabled: Bool {
        get {
            if #available(macOS 13.0, *) {
                return SMAppService.mainApp.status == .enabled
            } else {
                return defaults.bool(forKey: storageKey)
            }
        }
    }

    /// Enable or disable launch at login
    /// - Parameter enabled: Whether to enable launch at login
    func setEnabled(_ enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                    Log.info("Launch at login enabled (SMAppService)")
                } else {
                    try SMAppService.mainApp.unregister()
                    Log.info("Launch at login disabled (SMAppService)")
                }
            } catch {
                Log.error("Failed to set launch at login: \(error.localizedDescription)")
            }
        } else {
            // Legacy approach for older macOS
            let bundleId = AppConstants.bundleIdentifier
            let success = SMLoginItemSetEnabled(bundleId as CFString, enabled)
            if success {
                defaults.set(enabled, forKey: storageKey)
                Log.info("Launch at login \(enabled ? "enabled" : "disabled") (legacy)")
            } else {
                Log.error("Failed to set login item via SMLoginItemSetEnabled")
            }
        }
    }
}
