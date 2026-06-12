import Cocoa

/// Manages the menu bar icon and dropdown menu
/// Also handles dock visibility and quit functionality
/// Uses custom-drawn NSImage (NOT emoji) for the status indicator
class StatusBarManager {

    /// Shared instance (set from AppDelegate)
    static var shared: StatusBarManager?

    /// The status item in the menu bar
    private var statusItem: NSStatusItem?

    /// Whether Vietnamese mode is currently active
    private(set) var isVietnamese: Bool = true

    /// Reference to the preferences window controller
    private var preferencesWindowController: PreferencesWindowController?

    /// Reference to the clipboard menu item (for dynamic updates)
    private var clipboardMenuItem: NSMenuItem?

    // MARK: - Setup

    func setup() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        updateIcon(isVietnamese: PreferencesManager.shared.vietnameseEnabled)
        setupMenu()
        Log.ui("Status bar setup complete")
    }

    // MARK: - Icon Drawing

    /// Update the menu bar icon
    /// - Parameter isVietnamese: Whether Vietnamese mode is active
    func updateIcon(isVietnamese: Bool) {
        self.isVietnamese = isVietnamese

        guard let button = statusItem?.button else { return }

        let icon = drawStatusIcon(isVietnamese: isVietnamese)
        icon.isTemplate = true  // Adapts to light/dark menu bar
        button.image = icon
        button.toolTip = isVietnamese ? "Gõ Tiếng Việt — Tiếng Việt" : "Gõ Tiếng Việt — English"
    }

    /// Draw a clean, minimal status bar icon
    /// Shows "V" for Vietnamese, "E" for English
    private func drawStatusIcon(isVietnamese: Bool) -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size, flipped: false) { rect in
            // Background — rounded rectangle
            let bgRect = rect.insetBy(dx: 1, dy: 1)
            let bgPath = NSBezierPath(roundedRect: bgRect, xRadius: 3, yRadius: 3)

            if isVietnamese {
                NSColor.controlTextColor.withAlphaComponent(0.9).setFill()
            } else {
                NSColor.controlTextColor.withAlphaComponent(0.4).setFill()
            }
            bgPath.fill()

            // Letter
            let letter = isVietnamese ? "V" : "E"
            let font = NSFont.systemFont(ofSize: 12, weight: .semibold)
            let attrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: isVietnamese
                    ? NSColor.controlBackgroundColor
                    : NSColor.controlTextColor.withAlphaComponent(0.7)
            ]

            let attrStr = NSAttributedString(string: letter, attributes: attrs)
            let strSize = attrStr.size()
            let strRect = NSRect(
                x: (rect.width - strSize.width) / 2,
                y: (rect.height - strSize.height) / 2,
                width: strSize.width,
                height: strSize.height
            )
            attrStr.draw(in: strRect)

            return true
        }

        return image
    }

    // MARK: - Menu

    private func setupMenu() {
        let menu = NSMenu()

        // Vietnamese/English toggle
        let toggleItem = NSMenuItem(
            title: "Chuyển đổi Việt/Anh",
            action: #selector(toggleVietnamese(_:)),
            keyEquivalent: ""
        )
        toggleItem.target = self
        menu.addItem(toggleItem)

        menu.addItem(NSMenuItem.separator())

        // Input method submenu
        let inputMethodItem = NSMenuItem(title: "Kiểu gõ", action: nil, keyEquivalent: "")
        let inputMethodMenu = NSMenu()

        let telexItem = NSMenuItem(title: "Telex", action: #selector(selectTelex(_:)), keyEquivalent: "")
        telexItem.target = self
        inputMethodMenu.addItem(telexItem)

        let vniItem = NSMenuItem(title: "VNI", action: #selector(selectVNI(_:)), keyEquivalent: "")
        vniItem.target = self
        inputMethodMenu.addItem(vniItem)

        inputMethodItem.submenu = inputMethodMenu
        menu.addItem(inputMethodItem)

        menu.addItem(NSMenuItem.separator())

        // Clipboard history submenu
        let clipboardItem = NSMenuItem(title: "Clipboard", action: nil, keyEquivalent: "")
        clipboardItem.submenu = ClipboardManager.shared.buildClipboardMenu(target: self)
        self.clipboardMenuItem = clipboardItem
        menu.addItem(clipboardItem)

        menu.addItem(NSMenuItem.separator())

        // Preferences
        let prefsItem = NSMenuItem(
            title: "Bảng điều khiển...",
            action: #selector(showPreferences(_:)),
            keyEquivalent: ","
        )
        prefsItem.target = self
        menu.addItem(prefsItem)

        // About
        let aboutItem = NSMenuItem(
            title: "Giới thiệu",
            action: #selector(showAbout(_:)),
            keyEquivalent: ""
        )
        aboutItem.target = self
        menu.addItem(aboutItem)

        menu.addItem(NSMenuItem.separator())

        // Quit
        let quitItem = NSMenuItem(
            title: "Thoát Gõ Tiếng Việt",
            action: #selector(quitApp(_:)),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem?.menu = menu
    }

    /// Create the input menu (called from InputController)
    func createInputMenu() -> NSMenu {
        let menu = NSMenu()

        let toggleItem = NSMenuItem(
            title: isVietnamese ? "Chuyển sang English" : "Chuyển sang Tiếng Việt",
            action: #selector(toggleVietnamese(_:)),
            keyEquivalent: ""
        )
        toggleItem.target = self
        menu.addItem(toggleItem)

        return menu
    }

    // MARK: - Actions

    @objc private func toggleVietnamese(_ sender: Any?) {
        isVietnamese.toggle()
        PreferencesManager.shared.vietnameseEnabled = isVietnamese
        updateIcon(isVietnamese: isVietnamese)
        NotificationCenter.default.post(
            name: PreferencesManager.preferencesDidChangeNotification,
            object: nil
        )
    }

    @objc private func selectTelex(_ sender: Any?) {
        PreferencesManager.shared.inputMethod = .telex
    }

    @objc private func selectVNI(_ sender: Any?) {
        PreferencesManager.shared.inputMethod = .vni
    }

    @objc private func showPreferences(_ sender: Any?) {
        activateAndShowPreferences()
    }

    /// Called from AppDelegate's dock menu
    func showPreferencesFromDock() {
        activateAndShowPreferences()
    }

    /// Activates the app and presents the preferences window
    private func activateAndShowPreferences() {
        if preferencesWindowController == nil {
            preferencesWindowController = PreferencesWindowController()
        }

        preferencesWindowController?.showWindow(nil)

        // Make sure the window becomes key and is brought to front
        if let window = preferencesWindowController?.window {
            window.makeKeyAndOrderFront(nil)
        }

        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func showAbout(_ sender: Any?) {
        NSApp.activate(ignoringOtherApps: true)

        let alert = NSAlert()
        alert.messageText = AppConstants.appName
        alert.informativeText = """
        Phiên bản \(AppConstants.version)
        
        Ứng dụng gõ tiếng Việt cho macOS
        Hỗ trợ Telex & VNI
        
        Thiết kế theo phong cách Liquid Glass
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Đóng")
        alert.runModal()
    }

    @objc private func quitApp(_ sender: Any?) {
        Log.info("User requested quit from status bar menu")
        NSApp.terminate(nil)
    }

    // MARK: - Menu Validation

    func validateMenuItems() {
        guard let menu = statusItem?.menu else { return }

        // Update input method checkmarks
        for item in menu.items {
            if let submenu = item.submenu {
                for subItem in submenu.items {
                    if subItem.title == "Telex" {
                        subItem.state = PreferencesManager.shared.inputMethod == .telex ? .on : .off
                    } else if subItem.title == "VNI" {
                        subItem.state = PreferencesManager.shared.inputMethod == .vni ? .on : .off
                    }
                }
            }
        }
    }

    /// Refresh the clipboard submenu with latest history
    func updateClipboardMenu() {
        clipboardMenuItem?.submenu = ClipboardManager.shared.buildClipboardMenu(target: self)
    }
}

// MARK: - NSWindowDelegate

extension StatusBarManager: NSWindowDelegate {
    // Window delegate kept for future use (e.g., tracking window lifecycle)
}

// MARK: - ClipboardMenuActionHandler

extension StatusBarManager: ClipboardMenuActionHandler {
    @objc func clipboardItemClicked(_ sender: NSMenuItem) {
        let index = sender.tag
        ClipboardManager.shared.restoreEntry(at: index)
        updateClipboardMenu()
    }

    @objc func clearClipboardHistory(_ sender: Any?) {
        ClipboardManager.shared.clearHistory()
        updateClipboardMenu()
    }
}
