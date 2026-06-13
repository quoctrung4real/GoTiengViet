import Foundation

/// Manages the list of applications where Vietnamese input is automatically disabled
/// Essential feature for developers and gamers who don't want accidental Vietnamese input
class AppExclusionManager {

    /// Shared singleton
    static let shared = AppExclusionManager()

    /// Notification posted when the exclusion list changes
    static let exclusionListDidChangeNotification = Notification.Name("GoTiengVietExclusionListDidChange")

    /// An excluded app entry
    struct ExcludedApp: Codable {
        let bundleId: String
        let name: String
    }

    /// List of excluded apps
    private(set) var excludedApps: [ExcludedApp] = []

    /// Set of bundle IDs for fast lookup
    private var excludedBundleIds: Set<String> = []

    private let defaults = UserDefaults.standard
    private let storageKey = "excludedApps"

    private init() {
        loadExcludedApps()
    }

    // MARK: - Query

    /// Check if a given bundle ID is in the exclusion list
    /// - Parameter bundleId: The app's bundle identifier
    /// - Returns: true if the app should have Vietnamese disabled
    func isExcluded(bundleId: String?) -> Bool {
        guard let bundleId = bundleId else { return false }
        return excludedBundleIds.contains(bundleId)
    }

    // MARK: - Modification

    /// Add an app to the exclusion list
    func addExcludedApp(bundleId: String, name: String) {
        guard !excludedBundleIds.contains(bundleId) else { return }

        let app = ExcludedApp(bundleId: bundleId, name: name)
        excludedApps.append(app)
        excludedBundleIds.insert(bundleId)
        saveExcludedApps()
        notifyChange()
        Log.ui("Excluded app added: \(name) (\(bundleId))")
    }

    /// Remove an app from the exclusion list
    func removeExcludedApp(bundleId: String) {
        excludedApps.removeAll { $0.bundleId == bundleId }
        excludedBundleIds.remove(bundleId)
        saveExcludedApps()
        notifyChange()
        Log.ui("Excluded app removed: \(bundleId)")
    }

    /// Remove all excluded apps
    func clearAll() {
        excludedApps.removeAll()
        excludedBundleIds.removeAll()
        saveExcludedApps()
        notifyChange()
    }

    // MARK: - Persistence

    private func loadExcludedApps() {
        guard let data = defaults.data(forKey: storageKey) else {
            // Initialize with common defaults for developers
            excludedApps = Self.defaultExclusions
            excludedBundleIds = Set(excludedApps.map { $0.bundleId })
            saveExcludedApps()
            return
        }

        do {
            excludedApps = try JSONDecoder().decode([ExcludedApp].self, from: data)
            excludedBundleIds = Set(excludedApps.map { $0.bundleId })
        } catch {
            Log.error("Failed to load excluded apps: \(error.localizedDescription)")
            excludedApps = []
            excludedBundleIds = []
        }
    }

    private func saveExcludedApps() {
        do {
            let data = try JSONEncoder().encode(excludedApps)
            defaults.set(data, forKey: storageKey)
        } catch {
            Log.error("Failed to save excluded apps: \(error.localizedDescription)")
        }
    }

    private func notifyChange() {
        NotificationCenter.default.post(
            name: AppExclusionManager.exclusionListDidChangeNotification,
            object: nil
        )
    }

    // MARK: - Default Exclusions

    /// Default exclusion list — common apps where Vietnamese typing is unwanted
    static let defaultExclusions: [ExcludedApp] = [
        // These are suggestions — user can remove them
    ]
}
