import Cocoa

/// Preferences window controller with Liquid Glass design
/// Tab-based interface: Chung (General), Gõ tắt (Macros), Chuyển mã (Convert), Nâng cao (Advanced)
class PreferencesWindowController: NSWindowController {

    private var tabView: NSTabView!
    private let prefs = PreferencesManager.shared

    init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 440),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Gõ Tiếng Việt — Bảng điều khiển"
        window.center()
        window.isReleasedWhenClosed = false

        // Vibrancy effect for Liquid Glass
        let visualEffect = NSVisualEffectView(frame: window.contentView!.bounds)
        visualEffect.autoresizingMask = [.width, .height]
        visualEffect.blendingMode = .behindWindow
        visualEffect.state = .active
        visualEffect.material = .hudWindow
        window.contentView?.addSubview(visualEffect, positioned: .below, relativeTo: nil)

        super.init(window: window)

        setupTabs()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    // MARK: - Tab Setup

    private func setupTabs() {
        tabView = NSTabView(frame: NSRect(x: 16, y: 16, width: 488, height: 408))
        tabView.autoresizingMask = [.width, .height]
        tabView.tabViewType = .topTabsBezelBorder

        // Tab 1: Chung (General)
        let generalTab = NSTabViewItem(identifier: "general")
        generalTab.label = "Chung"
        generalTab.view = createGeneralView()
        tabView.addTabViewItem(generalTab)

        // Tab 2: Gõ tắt (Macros)
        let macroTab = NSTabViewItem(identifier: "macros")
        macroTab.label = "Gõ tắt"
        macroTab.view = createMacroView()
        tabView.addTabViewItem(macroTab)

        // Tab 3: Chuyển mã (Convert)
        let convertTab = NSTabViewItem(identifier: "convert")
        convertTab.label = "Chuyển mã"
        convertTab.view = createConvertView()
        tabView.addTabViewItem(convertTab)

        // Tab 4: Nâng cao (Advanced)
        let advancedTab = NSTabViewItem(identifier: "advanced")
        advancedTab.label = "Nâng cao"
        advancedTab.view = createAdvancedView()
        tabView.addTabViewItem(advancedTab)

        window?.contentView?.addSubview(tabView)
    }

    // MARK: - Tab 1: General

    private func createGeneralView() -> NSView {
        let container = NSView(frame: NSRect(x: 0, y: 0, width: 460, height: 360))

        var y: CGFloat = 320

        // Section: Kiểu gõ (Input Method)
        let inputMethodHeader = GlassSectionHeader(title: "KIỂU GÕ")
        inputMethodHeader.frame = NSRect(x: 20, y: y, width: 200, height: 16)
        container.addSubview(inputMethodHeader)
        y -= 36

        let inputMethodCard = GlassCardView(frame: NSRect(x: 20, y: y, width: 420, height: 40))
        container.addSubview(inputMethodCard)

        let inputMethodLabel = NSTextField(labelWithString: "Phương pháp gõ")
        inputMethodLabel.frame = NSRect(x: 16, y: 10, width: 200, height: 20)
        inputMethodLabel.font = NSFont.systemFont(ofSize: 13)
        inputMethodCard.addSubview(inputMethodLabel)

        let inputMethodDropdown = GlassDropdown(frame: NSRect(x: 280, y: 8, width: 124, height: 24), pullsDown: false)
        inputMethodDropdown.addItems(withTitles: AppConstants.InputMethod.allCases.map { $0.displayName })
        inputMethodDropdown.selectItem(withTitle: prefs.inputMethod.displayName)
        inputMethodDropdown.target = self
        inputMethodDropdown.action = #selector(inputMethodChanged(_:))
        inputMethodCard.addSubview(inputMethodDropdown)

        y -= 50

        // Section: Kiểu đặt dấu (Tone Style)
        let toneHeader = GlassSectionHeader(title: "KIỂU ĐẶT DẤU")
        toneHeader.frame = NSRect(x: 20, y: y, width: 200, height: 16)
        container.addSubview(toneHeader)
        y -= 36

        let toneCard = GlassCardView(frame: NSRect(x: 20, y: y, width: 420, height: 40))
        container.addSubview(toneCard)

        let toneLabel = NSTextField(labelWithString: "Vị trí dấu thanh")
        toneLabel.frame = NSRect(x: 16, y: 10, width: 200, height: 20)
        toneLabel.font = NSFont.systemFont(ofSize: 13)
        toneCard.addSubview(toneLabel)

        let toneDropdown = GlassDropdown(frame: NSRect(x: 220, y: 8, width: 184, height: 24), pullsDown: false)
        toneDropdown.addItems(withTitles: AppConstants.ToneStyle.allCases.map { $0.displayName })
        toneDropdown.selectItem(withTitle: prefs.toneStyle.displayName)
        toneDropdown.target = self
        toneDropdown.action = #selector(toneStyleChanged(_:))
        toneCard.addSubview(toneDropdown)

        y -= 50

        // Section: Bảng mã (Encoding)
        let encodingHeader = GlassSectionHeader(title: "BẢNG MÃ ĐẦU RA")
        encodingHeader.frame = NSRect(x: 20, y: y, width: 200, height: 16)
        container.addSubview(encodingHeader)
        y -= 36

        let encodingCard = GlassCardView(frame: NSRect(x: 20, y: y, width: 420, height: 40))
        container.addSubview(encodingCard)

        let encodingLabel = NSTextField(labelWithString: "Bảng mã")
        encodingLabel.frame = NSRect(x: 16, y: 10, width: 200, height: 20)
        encodingLabel.font = NSFont.systemFont(ofSize: 13)
        encodingCard.addSubview(encodingLabel)

        let encodingDropdown = GlassDropdown(frame: NSRect(x: 280, y: 8, width: 124, height: 24), pullsDown: false)
        encodingDropdown.addItems(withTitles: AppConstants.OutputEncoding.allCases.map { $0.displayName })
        encodingDropdown.selectItem(withTitle: prefs.outputEncoding.displayName)
        encodingDropdown.target = self
        encodingDropdown.action = #selector(encodingChanged(_:))
        encodingCard.addSubview(encodingDropdown)

        y -= 60

        // Info text
        let infoLabel = NSTextField(wrappingLabelWithString: "Sử dụng phím tắt trên menu bar hoặc phím tắt hệ thống để chuyển đổi giữa Tiếng Việt và English.")
        infoLabel.frame = NSRect(x: 20, y: y, width: 420, height: 40)
        infoLabel.font = NSFont.systemFont(ofSize: 11)
        infoLabel.textColor = NSColor.tertiaryLabelColor
        container.addSubview(infoLabel)

        return container
    }

    // MARK: - Tab 2: Macros

    private func createMacroView() -> NSView {
        let container = NSView(frame: NSRect(x: 0, y: 0, width: 460, height: 360))

        let header = GlassSectionHeader(title: "BẢNG GÕ TẮT")
        header.frame = NSRect(x: 20, y: 320, width: 200, height: 16)
        container.addSubview(header)

        // Macro table (placeholder — would use NSTableView)
        let card = GlassCardView(frame: NSRect(x: 20, y: 60, width: 420, height: 250))
        container.addSubview(card)

        let scrollView = NSScrollView(frame: NSRect(x: 8, y: 8, width: 404, height: 234))
        scrollView.hasVerticalScroller = true
        scrollView.autoresizingMask = [.width, .height]

        let tableView = NSTableView(frame: scrollView.bounds)
        let shortcutColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("shortcut"))
        shortcutColumn.title = "Từ viết tắt"
        shortcutColumn.width = 150
        tableView.addTableColumn(shortcutColumn)

        let expansionColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("expansion"))
        expansionColumn.title = "Nội dung thay thế"
        expansionColumn.width = 240
        tableView.addTableColumn(expansionColumn)

        scrollView.documentView = tableView
        card.addSubview(scrollView)

        // Buttons
        let addButton = NSButton(title: "Thêm", target: self, action: #selector(addMacro(_:)))
        addButton.bezelStyle = .rounded
        addButton.frame = NSRect(x: 20, y: 20, width: 80, height: 30)
        container.addSubview(addButton)

        let removeButton = NSButton(title: "Xóa", target: self, action: #selector(removeMacro(_:)))
        removeButton.bezelStyle = .rounded
        removeButton.frame = NSRect(x: 108, y: 20, width: 80, height: 30)
        container.addSubview(removeButton)

        let importButton = NSButton(title: "Nhập file", target: self, action: #selector(importMacros(_:)))
        importButton.bezelStyle = .rounded
        importButton.frame = NSRect(x: 280, y: 20, width: 80, height: 30)
        container.addSubview(importButton)

        let exportButton = NSButton(title: "Xuất file", target: self, action: #selector(exportMacros(_:)))
        exportButton.bezelStyle = .rounded
        exportButton.frame = NSRect(x: 368, y: 20, width: 80, height: 30)
        container.addSubview(exportButton)

        return container
    }

    // MARK: - Tab 3: Convert

    private func createConvertView() -> NSView {
        let container = NSView(frame: NSRect(x: 0, y: 0, width: 460, height: 360))

        let header = GlassSectionHeader(title: "CHUYỂN MÃ CLIPBOARD")
        header.frame = NSRect(x: 20, y: 320, width: 200, height: 16)
        container.addSubview(header)

        let card = GlassCardView(frame: NSRect(x: 20, y: 120, width: 420, height: 190))
        container.addSubview(card)

        // Source encoding
        let sourceLabel = NSTextField(labelWithString: "Bảng mã nguồn:")
        sourceLabel.frame = NSRect(x: 16, y: 150, width: 120, height: 20)
        sourceLabel.font = NSFont.systemFont(ofSize: 13)
        card.addSubview(sourceLabel)

        let sourceDropdown = GlassDropdown(frame: NSRect(x: 160, y: 148, width: 240, height: 24), pullsDown: false)
        sourceDropdown.addItems(withTitles: ["Unicode", "TCVN3 (ABC)", "VNI Windows", "VISCII", "UTF-8"])
        card.addSubview(sourceDropdown)

        // Destination encoding
        let destLabel = NSTextField(labelWithString: "Bảng mã đích:")
        destLabel.frame = NSRect(x: 16, y: 110, width: 120, height: 20)
        destLabel.font = NSFont.systemFont(ofSize: 13)
        card.addSubview(destLabel)

        let destDropdown = GlassDropdown(frame: NSRect(x: 160, y: 108, width: 240, height: 24), pullsDown: false)
        destDropdown.addItems(withTitles: ["Unicode", "TCVN3 (ABC)", "VNI Windows", "VISCII", "UTF-8"])
        destDropdown.selectItem(at: 0)
        card.addSubview(destDropdown)

        // Separator
        let sep = GlassSeparator(frame: NSRect(x: 16, y: 90, width: 388, height: 1))
        card.addSubview(sep)

        // Options
        let clipboardCheck = NSButton(checkboxWithTitle: "Chuyển mã Clipboard", target: nil, action: nil)
        clipboardCheck.frame = NSRect(x: 16, y: 56, width: 240, height: 20)
        clipboardCheck.state = .on
        card.addSubview(clipboardCheck)

        // Convert button
        let convertButton = NSButton(title: "Chuyển mã", target: self, action: #selector(convertClipboard(_:)))
        convertButton.bezelStyle = .rounded
        convertButton.frame = NSRect(x: 160, y: 14, width: 120, height: 30)
        convertButton.controlSize = .large
        card.addSubview(convertButton)

        // Instructions
        let instructions = NSTextField(wrappingLabelWithString: "Hướng dẫn: Copy văn bản cần chuyển mã (Cmd+C), chọn bảng mã nguồn và đích, sau đó nhấn \"Chuyển mã\". Kết quả sẽ nằm trong clipboard, dán bằng Cmd+V.")
        instructions.frame = NSRect(x: 20, y: 50, width: 420, height: 60)
        instructions.font = NSFont.systemFont(ofSize: 11)
        instructions.textColor = NSColor.tertiaryLabelColor
        container.addSubview(instructions)

        return container
    }

    // MARK: - Tab 4: Advanced

    private func createAdvancedView() -> NSView {
        let container = NSView(frame: NSRect(x: 0, y: 0, width: 460, height: 360))

        var y: CGFloat = 320

        // Section: Kiểm tra chính tả
        let spellHeader = GlassSectionHeader(title: "KIỂM TRA CHÍNH TẢ")
        spellHeader.frame = NSRect(x: 20, y: y, width: 200, height: 16)
        container.addSubview(spellHeader)
        y -= 36

        let spellCard = GlassCardView(frame: NSRect(x: 20, y: y, width: 420, height: 80))
        container.addSubview(spellCard)

        let spellToggle = GlassToggle(frame: NSRect(x: 360, y: 48, width: 44, height: 24))
        spellToggle.isOn = prefs.spellCheckEnabled
        spellToggle.onToggle = { [weak self] isOn in
            self?.prefs.spellCheckEnabled = isOn
        }
        spellCard.addSubview(spellToggle)

        let spellLabel = NSTextField(labelWithString: "Bật kiểm tra chính tả")
        spellLabel.frame = NSRect(x: 16, y: 50, width: 300, height: 20)
        spellLabel.font = NSFont.systemFont(ofSize: 13)
        spellCard.addSubview(spellLabel)

        let restoreToggle = GlassToggle(frame: NSRect(x: 360, y: 12, width: 44, height: 24))
        restoreToggle.isOn = prefs.autoRestoreEnabled
        restoreToggle.onToggle = { [weak self] isOn in
            self?.prefs.autoRestoreEnabled = isOn
        }
        spellCard.addSubview(restoreToggle)

        let restoreLabel = NSTextField(labelWithString: "Tự động phục hồi từ gõ sai")
        restoreLabel.frame = NSRect(x: 16, y: 14, width: 300, height: 20)
        restoreLabel.font = NSFont.systemFont(ofSize: 13)
        spellCard.addSubview(restoreLabel)

        y -= 100

        // Section: Bảo mật
        let securityHeader = GlassSectionHeader(title: "BẢO MẬT")
        securityHeader.frame = NSRect(x: 20, y: y, width: 200, height: 16)
        container.addSubview(securityHeader)
        y -= 36

        let securityCard = GlassCardView(frame: NSRect(x: 20, y: y, width: 420, height: 44))
        container.addSubview(securityCard)

        let secureToggle = GlassToggle(frame: NSRect(x: 360, y: 10, width: 44, height: 24))
        secureToggle.isOn = prefs.secureFieldBypass
        secureToggle.onToggle = { [weak self] isOn in
            self?.prefs.secureFieldBypass = isOn
        }
        securityCard.addSubview(secureToggle)

        let secureLabel = NSTextField(labelWithString: "Tự động tắt gõ Việt trong ô mật khẩu")
        secureLabel.frame = NSRect(x: 16, y: 12, width: 320, height: 20)
        secureLabel.font = NSFont.systemFont(ofSize: 13)
        securityCard.addSubview(secureLabel)

        y -= 60

        // Section: Nâng cao
        let advHeader = GlassSectionHeader(title: "NÂNG CAO")
        advHeader.frame = NSRect(x: 20, y: y, width: 200, height: 16)
        container.addSubview(advHeader)
        y -= 36

        let advCard = GlassCardView(frame: NSRect(x: 20, y: y, width: 420, height: 44))
        container.addSubview(advCard)

        let macroToggle = GlassToggle(frame: NSRect(x: 360, y: 10, width: 44, height: 24))
        macroToggle.isOn = prefs.macroEnabled
        macroToggle.onToggle = { [weak self] isOn in
            self?.prefs.macroEnabled = isOn
        }
        advCard.addSubview(macroToggle)

        let macroLabel = NSTextField(labelWithString: "Bật gõ tắt (Macro)")
        macroLabel.frame = NSRect(x: 16, y: 12, width: 300, height: 20)
        macroLabel.font = NSFont.systemFont(ofSize: 13)
        advCard.addSubview(macroLabel)

        return container
    }

    // MARK: - Actions

    @objc private func inputMethodChanged(_ sender: NSPopUpButton) {
        guard let title = sender.titleOfSelectedItem,
              let method = AppConstants.InputMethod.allCases.first(where: { $0.displayName == title }) else { return }
        prefs.inputMethod = method
    }

    @objc private func toneStyleChanged(_ sender: NSPopUpButton) {
        guard let title = sender.titleOfSelectedItem,
              let style = AppConstants.ToneStyle.allCases.first(where: { $0.displayName == title }) else { return }
        prefs.toneStyle = style
    }

    @objc private func encodingChanged(_ sender: NSPopUpButton) {
        guard let title = sender.titleOfSelectedItem,
              let encoding = AppConstants.OutputEncoding.allCases.first(where: { $0.displayName == title }) else { return }
        prefs.outputEncoding = encoding
    }

    @objc private func addMacro(_ sender: Any?) {
        Log.ui("Add macro action")
    }

    @objc private func removeMacro(_ sender: Any?) {
        Log.ui("Remove macro action")
    }

    @objc private func importMacros(_ sender: Any?) {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            // Import macros from file
            Log.ui("Import macros from: \(url.path)")
        }
    }

    @objc private func exportMacros(_ sender: Any?) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "macros.json"
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            Log.ui("Export macros to: \(url.path)")
        }
    }

    @objc private func convertClipboard(_ sender: Any?) {
        Log.ui("Convert clipboard action")
        // TODO: Implement clipboard conversion
    }
}
