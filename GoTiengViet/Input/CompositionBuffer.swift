import Foundation
import AppKit
import InputMethodKit

/// Manages text composition buffer and interaction with client applications
/// 
/// ## Critical: Anti-Duplication Architecture
/// This class uses a single-buffer approach and strict ordering to prevent
/// text jumping and character duplication:
/// 1. Always clear marked text BEFORE inserting committed text
/// 2. All client interactions happen on MainActor (synchronous)
/// 3. Never hold references to client objects beyond event scope
class CompositionBuffer {

    /// Current raw buffer (original keystrokes)
    private(set) var buffer: [Character] = []

    /// Current composed/displayed text
    private(set) var displayText: String = ""

    /// Whether we have an active composition (marked text shown)
    private(set) var isComposing: Bool = false

    // MARK: - Buffer Operations

    /// Update the composition with new text
    /// - Parameters:
    ///   - text: The new composed text to display
    ///   - client: The IMKTextInput client to update
    func updateComposition(_ text: String, client: IMKTextInput?) {
        displayText = text
        isComposing = !text.isEmpty

        guard let client = client else { return }

        if text.isEmpty {
            // Clear marked text
            clearMarkedText(client: client)
        } else {
            // Update marked text
            setMarkedText(text, client: client)
        }
    }

    /// Commit the current composition to the document
    /// - Parameters:
    ///   - text: The text to commit
    ///   - client: The IMKTextInput client
    func commitText(_ text: String, client: IMKTextInput?) {
        guard let client = client, !text.isEmpty else {
            reset()
            return
        }

        // CRITICAL ORDER: Clear marked text FIRST, then insert
        // This prevents duplication where marked text gets committed
        // alongside the insertText call
        clearMarkedText(client: client)

        // Insert the committed text
        client.insertText(
            text as NSString,
            replacementRange: NSRange(location: NSNotFound, length: 0)
        )

        reset()
        Log.input("Committed text: '\(text)'")
    }

    /// Clear the current composition without committing
    /// - Parameter client: The IMKTextInput client
    func clearComposition(client: IMKTextInput?) {
        if let client = client {
            clearMarkedText(client: client)
        }
        reset()
    }

    /// Reset internal state
    func reset() {
        buffer.removeAll()
        displayText = ""
        isComposing = false
    }

    // MARK: - Marked Text Management

    /// Set marked text on the client
    /// Marked text is the "in-progress" text shown with underline
    private func setMarkedText(_ text: String, client: IMKTextInput) {
        // Create attributed string with underline for composition indicator
        let attrs: [NSAttributedString.Key: Any] = [
            .underlineStyle: NSUnderlineStyle.single.rawValue,
            .foregroundColor: NSColor.textColor
        ]
        let attrString = NSAttributedString(string: text, attributes: attrs)

        client.setMarkedText(
            attrString,
            selectionRange: NSRange(location: text.count, length: 0),
            replacementRange: NSRange(location: NSNotFound, length: 0)
        )
    }

    /// Clear marked text from the client
    /// MUST be called before insertText to prevent duplication
    private func clearMarkedText(client: IMKTextInput) {
        client.setMarkedText(
            "" as NSString,
            selectionRange: NSRange(location: 0, length: 0),
            replacementRange: NSRange(location: NSNotFound, length: 0)
        )
    }

    // MARK: - State Queries

    /// Whether the buffer is empty
    var isEmpty: Bool {
        return buffer.isEmpty && displayText.isEmpty
    }

    /// Current text being composed
    var currentText: String {
        return displayText.isEmpty ? String(buffer) : displayText
    }
}
