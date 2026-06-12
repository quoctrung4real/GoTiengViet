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

        // Listen for preference changes
        NotificationCenter.default.addObserver(
            forName: PreferencesManager.preferencesDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.statusBarManager?.validateMenuItems()
        }

        Log.info("GoTiengViet ready!")
    }

    func applicationWillTerminate(_ notification: Notification) {
        Log.info("GoTiengViet shutting down...")
    }
}
