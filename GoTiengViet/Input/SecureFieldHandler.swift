import Foundation
import AppKit
import InputMethodKit

/// Detects and handles secure text fields (password fields)
/// to prevent Vietnamese composition in security-sensitive contexts
///
/// ## Critical Bug Prevention:
/// When a user sets a password with Vietnamese IME active, the stored password
/// will contain Vietnamese characters. Later, entering the same keystrokes with
/// IME off produces different text, causing password mismatch.
///
/// ## Solution: Auto-detect secure fields and bypass all composition
class SecureFieldHandler {

    /// Whether secure field bypass is enabled (user preference)
    var bypassEnabled: Bool = true

    /// The Vietnamese mode state before entering a secure field
    /// Used to restore state when leaving the secure field
    private var savedVietnameseState: Bool = true

    /// Whether we are currently in a secure field
    private(set) var isInSecureField: Bool = false

    /// Bundle identifiers of known login/security processes
    private static let secureProcesses: Set<String> = [
        "com.apple.loginwindow",
        "com.apple.SecurityAgent",
        "com.apple.screensaver",
        "com.apple.ScreenSharing",
    ]

    // MARK: - Detection

    /// Check if the current client is a secure text field
    /// - Parameter client: The IMKTextInput client
    /// - Returns: true if this is a secure/password field
    func isSecureField(client: Any?) -> Bool {
        guard bypassEnabled else { return false }

        // Method 1: Check document attributes for secure flag
        if let textInput = client as? IMKTextInput {
            // Try to get attributes that indicate a secure field
            var lineRect = NSRect.zero
            if let attrs = textInput.attributes(forCharacterIndex: 0, lineHeightRectangle: &lineRect) {
                // Check for secure input attribute
                if let isSecure = attrs["IMKTextInputIsSecure"] as? Bool, isSecure {
                    Log.security("Detected secure field via attributes")
                    return true
                }
            }
        }

        // Method 2: Check if the client's bundle identifier is a known secure process
        if let textInput = client as? IMKTextInput {
            if let bundleId = textInput.bundleIdentifier() {
                if SecureFieldHandler.secureProcesses.contains(bundleId) {
                    Log.security("Detected secure process: \(bundleId)")
                    return true
                }
            }
        }

        // Method 3: Check system-wide Secure Input state
        if isSecureEventInputEnabled() {
            Log.security("Detected secure event input enabled system-wide")
            return true
        }

        return false
    }

    /// Check if the system has Secure Event Input enabled
    /// This is set by apps like Terminal, password managers, etc.
    private func isSecureEventInputEnabled() -> Bool {
        return IsSecureEventInputEnabled()
    }

    // MARK: - State Management

    /// Called when entering a secure field
    /// - Parameter currentVietnameseState: Whether Vietnamese mode is currently active
    func enterSecureField(currentVietnameseState: Bool) {
        guard !isInSecureField else { return }

        savedVietnameseState = currentVietnameseState
        isInSecureField = true
        Log.security("Entered secure field. Saved Vietnamese state: \(currentVietnameseState)")
    }

    /// Called when leaving a secure field
    /// - Returns: The Vietnamese mode state that should be restored
    func leaveSecureField() -> Bool {
        guard isInSecureField else { return true }

        isInSecureField = false
        let stateToRestore = savedVietnameseState
        Log.security("Left secure field. Restoring Vietnamese state: \(stateToRestore)")
        return stateToRestore
    }

    /// Reset state (e.g., when deactivating the input method)
    func reset() {
        isInSecureField = false
        savedVietnameseState = true
    }
}
