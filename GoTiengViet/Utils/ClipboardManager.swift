import Cocoa

/// Manages clipboard history for GoTiengViet
/// Polls the system pasteboard for new text entries and stores them in a history list.
/// History is persisted to UserDefaults and limited to `maxHistoryCount` items.
class ClipboardManager {

    /// Shared instance
    static let shared = ClipboardManager()

    /// Maximum number of clipboard entries to keep
    static let maxHistoryCount = 30

    /// Maximum display length for menu items (truncate long text)
    static let maxDisplayLength = 60

    /// UserDefaults key for clipboard history
    private static let historyKey = "clipboardHistory"

    /// Notification posted when clipboard history changes
    static let historyDidChangeNotification = Notification.Name("ClipboardHistoryDidChange")

    /// The clipboard history — most recent first
    private(set) var history: [String] = []

    /// Last known pasteboard change count (used to detect new copies)
    private var lastChangeCount: Int = 0

    /// Timer for polling the pasteboard
    private var pollTimer: Timer?

    // MARK: - Initialization

    private init() {
        loadHistory()
        lastChangeCount = NSPasteboard.general.changeCount
    }

    // MARK: - Start/Stop Monitoring

    /// Start monitoring the system clipboard for changes
    func startMonitoring() {
        guard pollTimer == nil else { return }

        // Poll every 0.5 seconds — lightweight, standard approach on macOS
        pollTimer = Timer.scheduledTimer(
            withTimeInterval: 0.5,
            repeats: true
        ) { [weak self] _ in
            self?.checkForNewClipboardContent()
        }

        // Keep timer alive even during menu tracking / modal loops
        if let timer = pollTimer {
            RunLoop.main.add(timer, forMode: .common)
        }

        Log.info("Clipboard monitoring started")
    }

    /// Stop monitoring the clipboard
    func stopMonitoring() {
        pollTimer?.invalidate()
        pollTimer = nil
        Log.info("Clipboard monitoring stopped")
    }

    // MARK: - Clipboard Polling

    /// Check if the pasteboard has new content
    private func checkForNewClipboardContent() {
        let pasteboard = NSPasteboard.general
        let currentChangeCount = pasteboard.changeCount

        guard currentChangeCount != lastChangeCount else { return }
        lastChangeCount = currentChangeCount

        // Only track string content
        guard let newText = pasteboard.string(forType: .string),
              !newText.isEmpty else { return }

        // Don't add duplicates at the top
        if let first = history.first, first == newText { return }

        addToHistory(newText)
    }

    // MARK: - History Management

    /// Add a new entry to the clipboard history
    private func addToHistory(_ text: String) {
        // Remove existing duplicate if present (move to top)
        history.removeAll { $0 == text }

        // Insert at the beginning (most recent first)
        history.insert(text, at: 0)

        // Trim to max count
        if history.count > ClipboardManager.maxHistoryCount {
            history = Array(history.prefix(ClipboardManager.maxHistoryCount))
        }

        saveHistory()

        NotificationCenter.default.post(
            name: ClipboardManager.historyDidChangeNotification,
            object: nil
        )

        Log.ui("Clipboard history updated: \(history.count) items")
    }

    /// Copy a history entry back to the system clipboard
    /// - Parameter index: Index of the entry in the history array
    func restoreEntry(at index: Int) {
        guard index >= 0, index < history.count else { return }

        let text = history[index]
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        // Update change count so we don't re-add this as a "new" entry
        lastChangeCount = pasteboard.changeCount

        Log.ui("Restored clipboard entry #\(index): \"\(truncateForLog(text))\"")
    }

    /// Clear all clipboard history
    func clearHistory() {
        history.removeAll()
        saveHistory()

        NotificationCenter.default.post(
            name: ClipboardManager.historyDidChangeNotification,
            object: nil
        )

        Log.ui("Clipboard history cleared")
    }

    // MARK: - Persistence

    private func saveHistory() {
        UserDefaults.standard.set(history, forKey: ClipboardManager.historyKey)
    }

    private func loadHistory() {
        if let saved = UserDefaults.standard.stringArray(forKey: ClipboardManager.historyKey) {
            history = saved
        }
    }

    // MARK: - Menu Building

    /// Build a submenu showing all clipboard history entries
    /// Each item restores the text to the clipboard when clicked
    /// - Parameter target: The target object that handles menu actions
    /// - Returns: An NSMenu with clipboard history entries
    func buildClipboardMenu(target: AnyObject) -> NSMenu {
        let menu = NSMenu(title: "Clipboard")

        if history.isEmpty {
            let emptyItem = NSMenuItem(title: "Chưa có nội dung nào", action: nil, keyEquivalent: "")
            emptyItem.isEnabled = false
            menu.addItem(emptyItem)
        } else {
            for (index, text) in history.enumerated() {
                let displayText = truncateForDisplay(text)

                // Show index + 1 for human-readable numbering
                let item = NSMenuItem(
                    title: "\(index + 1). \(displayText)",
                    action: #selector(ClipboardMenuActionHandler.clipboardItemClicked(_:)),
                    keyEquivalent: ""
                )
                item.target = target
                item.tag = index
                item.toolTip = text  // Full text shown as tooltip

                menu.addItem(item)
            }

            menu.addItem(NSMenuItem.separator())

            // Clear all
            let clearItem = NSMenuItem(
                title: "Xóa lịch sử clipboard",
                action: #selector(ClipboardMenuActionHandler.clearClipboardHistory(_:)),
                keyEquivalent: ""
            )
            clearItem.target = target
            menu.addItem(clearItem)
        }

        return menu
    }

    // MARK: - Text Formatting Helpers

    /// Truncate text for display in menu items
    private func truncateForDisplay(_ text: String) -> String {
        // Replace newlines with ↵ for readability
        let singleLine = text
            .replacingOccurrences(of: "\r\n", with: " ↵ ")
            .replacingOccurrences(of: "\n", with: " ↵ ")
            .replacingOccurrences(of: "\r", with: " ↵ ")

        if singleLine.count > ClipboardManager.maxDisplayLength {
            let endIndex = singleLine.index(singleLine.startIndex, offsetBy: ClipboardManager.maxDisplayLength)
            return String(singleLine[..<endIndex]) + "..."
        }
        return singleLine
    }

    /// Truncate text for log messages
    private func truncateForLog(_ text: String) -> String {
        let clean = text.replacingOccurrences(of: "\n", with: " ")
        if clean.count > 40 {
            let endIndex = clean.index(clean.startIndex, offsetBy: 40)
            return String(clean[..<endIndex]) + "..."
        }
        return clean
    }
}

// MARK: - ClipboardMenuActionHandler Protocol

/// Protocol for objects that handle clipboard menu item clicks
@objc protocol ClipboardMenuActionHandler: AnyObject {
    func clipboardItemClicked(_ sender: NSMenuItem)
    func clearClipboardHistory(_ sender: Any?)
}
