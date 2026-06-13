import Cocoa

/// Preferences window controller with Liquid Glass design & Auto Layout
class PreferencesWindowController: NSWindowController, NSToolbarDelegate {

    private let prefs = PreferencesManager.shared
    private let macroEngine = MacroEngine()

    /// Container for the active tab view
    private let containerView = NSView()

    // MARK: - Toolbar Identifiers
    private let tabGeneral = NSToolbarItem.Identifier("tabGeneral")
    private let tabMacro = NSToolbarItem.Identifier("tabMacro")
    private let tabConvert = NSToolbarItem.Identifier("tabConvert")
    private let tabAdvanced = NSToolbarItem.Identifier("tabAdvanced")

    private var activeTab: NSToolbarItem.Identifier = NSToolbarItem.Identifier("")

    init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 540, height: 480),
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "Gõ Tiếng Việt"
        window.center()
        window.isReleasedWhenClosed = false
        window.titlebarAppearsTransparent = true

        // Vibrancy effect for the window background
        let visualEffect = NSVisualEffectView()
        visualEffect.translatesAutoresizingMaskIntoConstraints = false
        visualEffect.blendingMode = .behindWindow
        visualEffect.state = .active
        visualEffect.material = .windowBackground // Native macOS light/dark adapt
        window.contentView = visualEffect

        super.init(window: window)

        setupToolbar()
        setupContainer()

        // Select first tab
        switchTab(to: tabGeneral)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    // MARK: - Setup

    private func setupContainer() {
        guard let contentView = window?.contentView else { return }

        containerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(containerView)

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 48), // Space for titlebar
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24)
        ])
    }

    private func setupToolbar() {
        let toolbar = NSToolbar(identifier: "PreferencesToolbar")
        toolbar.delegate = self
        toolbar.displayMode = .iconAndLabel
        toolbar.selectedItemIdentifier = tabGeneral
        toolbar.allowsUserCustomization = false
        window?.toolbar = toolbar
    }

    // MARK: - NSToolbarDelegate

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [tabGeneral, tabMacro, tabConvert, tabAdvanced]
    }

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return toolbarDefaultItemIdentifiers(toolbar)
    }

    func toolbarSelectableItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return toolbarDefaultItemIdentifiers(toolbar)
    }

    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {

        let item = NSToolbarItem(itemIdentifier: itemIdentifier)
        item.target = self
        item.action = #selector(toolbarItemSelected(_:))

        switch itemIdentifier {
        case tabGeneral:
            item.label = "Chung"
            item.image = NSImage(systemSymbolName: "gearshape", accessibilityDescription: nil)
        case tabMacro:
            item.label = "Gõ tắt"
            item.image = NSImage(systemSymbolName: "text.badge.star", accessibilityDescription: nil)
        case tabConvert:
            item.label = "Chuyển mã"
            item.image = NSImage(systemSymbolName: "arrow.left.arrow.right", accessibilityDescription: nil)
        case tabAdvanced:
            item.label = "Nâng cao"
            item.image = NSImage(systemSymbolName: "slider.horizontal.3", accessibilityDescription: nil)
        default:
            return nil
        }
        return item
    }

    @objc private func toolbarItemSelected(_ sender: NSToolbarItem) {
        switchTab(to: sender.itemIdentifier)
    }

    // MARK: - Tab Switching

    private func switchTab(to identifier: NSToolbarItem.Identifier) {
        guard identifier != activeTab else { return }
        activeTab = identifier

        // Remove current views
        containerView.subviews.forEach { $0.removeFromSuperview() }

        let newView: NSView
        switch identifier {
        case tabGeneral:
            newView = GeneralPrefsView()
        case tabMacro:
            newView = MacroPrefsView(macroEngine: macroEngine)
        case tabConvert:
            newView = ConvertPrefsView()
        case tabAdvanced:
            newView = AdvancedPrefsView()
        default:
            return
        }

        newView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(newView)

        NSLayoutConstraint.activate([
            newView.topAnchor.constraint(equalTo: containerView.topAnchor),
            newView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            newView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            newView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])

        window?.toolbar?.selectedItemIdentifier = identifier
    }
}
