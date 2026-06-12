import Foundation

/// Macro (abbreviation) engine for GoTiengViet
/// Supports user-defined shortcuts that expand to full text
class MacroEngine {

    /// Storage for macros: shortcut → expansion
    private var macros: [String: String] = [:]

    /// File path for macro persistence
    private let macroFilePath: URL

    init() {
        // Store macros in Application Support directory
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("GoTiengViet")
        
        // Create directory if it doesn't exist
        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
        
        macroFilePath = appDir.appendingPathComponent("macros.json")
        loadMacros()
    }

    // MARK: - Macro Operations

    /// Add or update a macro
    /// - Parameters:
    ///   - shortcut: The abbreviation to type
    ///   - expansion: The full text to expand to
    func addMacro(shortcut: String, expansion: String) {
        macros[shortcut.lowercased()] = expansion
        saveMacros()
        Log.engine("Macro added: '\(shortcut)' → '\(expansion)'")
    }

    /// Remove a macro
    /// - Parameter shortcut: The abbreviation to remove
    func removeMacro(shortcut: String) {
        macros.removeValue(forKey: shortcut.lowercased())
        saveMacros()
    }

    /// Get all macros
    func getAllMacros() -> [String: String] {
        return macros
    }

    /// Check if a string matches a macro and return the expansion
    /// - Parameter text: The text to check
    /// - Returns: The expansion if a macro matches, nil otherwise
    func expand(_ text: String) -> String? {
        return macros[text.lowercased()]
    }

    /// Check if the current buffer could be the start of a macro
    /// - Parameter prefix: The current buffer text
    /// - Returns: true if any macro starts with this prefix
    func hasMacroWithPrefix(_ prefix: String) -> Bool {
        let lower = prefix.lowercased()
        return macros.keys.contains(where: { $0.hasPrefix(lower) })
    }

    // MARK: - Import / Export

    /// Export macros to a file
    /// - Parameter url: File URL to export to
    func exportMacros(to url: URL) throws {
        let data = try JSONEncoder().encode(macros)
        try data.write(to: url)
        Log.engine("Exported \(macros.count) macros to \(url.path)")
    }

    /// Import macros from a file
    /// - Parameter url: File URL to import from
    /// - Parameter merge: If true, merge with existing macros. If false, replace.
    func importMacros(from url: URL, merge: Bool = true) throws {
        let data = try Data(contentsOf: url)
        let imported = try JSONDecoder().decode([String: String].self, from: data)

        if merge {
            macros.merge(imported) { _, new in new }
        } else {
            macros = imported
        }
        saveMacros()
        Log.engine("Imported \(imported.count) macros from \(url.path)")
    }

    // MARK: - Persistence

    private func loadMacros() {
        guard FileManager.default.fileExists(atPath: macroFilePath.path) else {
            // Initialize with some common defaults
            macros = [:]
            return
        }

        do {
            let data = try Data(contentsOf: macroFilePath)
            macros = try JSONDecoder().decode([String: String].self, from: data)
            Log.engine("Loaded \(macros.count) macros")
        } catch {
            Log.engineError("Failed to load macros: \(error.localizedDescription)")
            macros = [:]
        }
    }

    private func saveMacros() {
        do {
            let data = try JSONEncoder().encode(macros)
            try data.write(to: macroFilePath, options: .atomic)
        } catch {
            Log.engineError("Failed to save macros: \(error.localizedDescription)")
        }
    }
}
