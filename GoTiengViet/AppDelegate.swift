import Cocoa
import InputMethodKit

/// Application Delegate for GoTiengViet Input Method
/// Responsible for initializing the IMKServer and setting up the status bar
class AppDelegate: NSObject, NSApplicationDelegate {

    /// The IMK server instance — manages connections with client apps
    private var server: IMKServer?

    /// Status bar manager
    private var statusBarManager: StatusBarManager?

    // MARK: - Application Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        Log.info("GoTiengViet starting up...")

        // Initialize the IMK Server
        // The connection name and bundle ID must match Info.plist exactly
        guard let connectionName = Bundle.main.infoDictionary?["InputMethodConnectionName"] as? String else {
            Log.error("Missing InputMethodConnectionName in Info.plist!")
            return
        }

        guard let bundleId = Bundle.main.bundleIdentifier else {
            Log.error("Missing bundle identifier!")
            return
        }

        server = IMKServer(name: connectionName, bundleIdentifier: bundleId)

        if server != nil {
            Log.info("IMKServer initialized: \(connectionName)")
        } else {
            Log.error("Failed to initialize IMKServer!")
        }

        // Setup status bar
        statusBarManager = StatusBarManager()
        StatusBarManager.shared = statusBarManager
        statusBarManager?.setup()

        // Show app in Dock so dock menu (Clipboard, Quit) is accessible
        NSApp.setActivationPolicy(.regular)

        // Listen for preference changes
        NotificationCenter.default.addObserver(
            forName: PreferencesManager.preferencesDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.statusBarManager?.validateMenuItems()
        }

        // Start clipboard history monitoring
        ClipboardManager.shared.startMonitoring()

        // Listen for clipboard history changes to refresh menus
        NotificationCenter.default.addObserver(
            forName: ClipboardManager.historyDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.statusBarManager?.updateClipboardMenu()
        }

        Log.info("GoTiengViet ready!")
    }

    func applicationWillTerminate(_ notification: Notification) {
        ClipboardManager.shared.stopMonitoring()
        Log.info("GoTiengViet shutting down...")
    }

    // MARK: - Dock Menu

    /// Provides the dock menu when the user right-clicks on the app icon in the Dock
    func applicationDockMenu(_ sender: NSApplication) -> NSMenu? {
        let menu = NSMenu()

        // Clipboard history
        let clipboardItem = NSMenuItem(title: "Clipboard", action: nil, keyEquivalent: "")
        clipboardItem.submenu = ClipboardManager.shared.buildClipboardMenu(target: self)
        menu.addItem(clipboardItem)

        menu.addItem(NSMenuItem.separator())

        // Preferences
        let prefsItem = NSMenuItem(
            title: "Bảng điều khiển...",
            action: #selector(openPreferences(_:)),
            keyEquivalent: ","
        )
        prefsItem.target = self
        menu.addItem(prefsItem)

        menu.addItem(NSMenuItem.separator())

        // Quit
        let quitItem = NSMenuItem(
            title: "Thoát Gõ Tiếng Việt",
            action: #selector(quitApp(_:)),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        return menu
    }

    // MARK: - Actions

    @objc private func openPreferences(_ sender: Any?) {
        statusBarManager?.showPreferencesFromDock()
    }

    @objc private func quitApp(_ sender: Any?) {
        Log.info("User requested quit from Dock menu")
        NSApp.terminate(nil)
    }
}

// MARK: - ClipboardMenuActionHandler (Dock Menu)

extension AppDelegate: ClipboardMenuActionHandler {
    @objc func clipboardItemClicked(_ sender: NSMenuItem) {
        let index = sender.tag
        ClipboardManager.shared.restoreEntry(at: index)
    }

    @objc func clearClipboardHistory(_ sender: Any?) {
        ClipboardManager.shared.clearHistory()
    }
}
