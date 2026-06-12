import Foundation
import os.log

/// Debug logging utility for GoTiengViet
/// Logs are visible in Console.app under the GoTiengViet subsystem
enum Log {
    private static let subsystem = AppConstants.bundleIdentifier

    private static let engineLog = OSLog(subsystem: subsystem, category: "Engine")
    private static let inputLog = OSLog(subsystem: subsystem, category: "Input")
    private static let uiLog = OSLog(subsystem: subsystem, category: "UI")
    private static let securityLog = OSLog(subsystem: subsystem, category: "Security")
    private static let generalLog = OSLog(subsystem: subsystem, category: "General")

    // MARK: - Engine Logging

    static func engine(_ message: String) {
        os_log("[Engine] %{public}@", log: engineLog, type: .debug, message)
    }

    static func engineError(_ message: String) {
        os_log("[Engine] ERROR: %{public}@", log: engineLog, type: .error, message)
    }

    // MARK: - Input Logging

    static func input(_ message: String) {
        os_log("[Input] %{public}@", log: inputLog, type: .debug, message)
    }

    static func inputError(_ message: String) {
        os_log("[Input] ERROR: %{public}@", log: inputLog, type: .error, message)
    }

    // MARK: - UI Logging

    static func ui(_ message: String) {
        os_log("[UI] %{public}@", log: uiLog, type: .debug, message)
    }

    // MARK: - Security Logging (for secure field handling)

    static func security(_ message: String) {
        os_log("[Security] %{public}@", log: securityLog, type: .info, message)
    }

    // MARK: - General Logging

    static func info(_ message: String) {
        os_log("[Info] %{public}@", log: generalLog, type: .info, message)
    }

    static func warning(_ message: String) {
        os_log("[Warning] %{public}@", log: generalLog, type: .default, message)
    }

    static func error(_ message: String) {
        os_log("[Error] %{public}@", log: generalLog, type: .error, message)
    }
}
