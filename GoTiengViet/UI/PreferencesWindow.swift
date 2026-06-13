import Cocoa

/// Preferences window controller with Liquid Glass design
/// Tab-based interface: Chung (General), Gõ tắt (Macros), Chuyển mã (Convert), Nâng cao (Advanced)
class PreferencesWindowController: NSWindowController {

    private var tabView: NSTabView!
    private let prefs = PreferencesManager.shared

    /// Macro table data
    private var macroTableView: NSTableView?
    private var macroData: [(shortcut: String, expansion: String)] = []
    private let macroEngine = MacroEngine()

    /// App exclusion table data
    private var exclusionTableView: NSTableView?

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

        reloadMacroData()
        setupTabs()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    // MARK: - Macro Data

    private func reloadMacroData() {
        macroData = macroEngine.getAllMacros()
            .map { (shortcut: $0.key, expansion: $0.value) }
            .sorted(by: { $0.shortcut < $1.shortcut })
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

        y -= 50

        // Section: Khởi động
        let launchHeader = GlassSectionHeader(title: "KHỞI ĐỘNG")
        launchHeader.frame = NSRect(x: 20, y: y, width: 200, height: 16)
        container.addSubview(launchHeader)
        y -= 36

        let launchCard = GlassCardView(frame: NSRect(x: 20, y: y, width: 420, height: 40))
        container.addSubview(launchCard)

        let launchLabel = NSTextField(labelWithString: "Khởi động cùng hệ thống")
        launchLabel.frame = NSRect(x: 16, y: 10, width: 300, height: 20)
        launchLabel.font = NSFont.systemFont(ofSize: 13)
        launchCard.addSubview(launchLabel)

        let launchToggle = GlassToggle(frame: NSRect(x: 360, y: 8, width: 44, height: 24))
        launchToggle.isOn = LaunchAtLoginManager.shared.isEnabled
        launchToggle.onToggle = { isOn in
            LaunchAtLoginManager.shared.setEnabled(isOn)
        }
        launchCard.addSubview(launchToggle)

        y -= 50

        // Section: Phím tắt
        let hotkeyHeader = GlassSectionHeader(title: "PHÍM TẮT CHUYỂN ĐỔI")
        hotkeyHeader.frame = NSRect(x: 20, y: y, width: 200, height: 16)
        container.addSubview(hotkeyHeader)
        y -= 36

        let hotkeyCard = GlassCardView(frame: NSRect(x: 20, y: y, width: 420, height: 40))
        container.addSubview(hotkeyCard)

        let hotkeyLabel = NSTextField(labelWithString: "Phím tắt Việt/Anh")
        hotkeyLabel.frame = NSRect(x: 16, y: 10, width: 200, height: 20)
        hotkeyLabel.font = NSFont.systemFont(ofSize: 13)
        hotkeyCard.addSubview(hotkeyLabel)

        let hotkeyRecorder = HotkeyRecorderView(frame: NSRect(x: 260, y: 6, width: 144, height: 28))
        hotkeyRecorder.onHotkeyChanged = { keyCode, modifiers in
            HotkeyManager.shared.registerHotkey(keyCode: keyCode, modifiers: modifiers)
        }
        hotkeyCard.addSubview(hotkeyRecorder)

        return container
    }

    // MARK: - Tab 2: Macros (Fully Connected)

    private func createMacroView() -> NSView {
        let container = NSView(frame: NSRect(x: 0, y: 0, width: 460, height: 360))

        let header = GlassSectionHeader(title: "BẢNG GÕ TẮT")
        header.frame = NSRect(x: 20, y: 320, width: 200, height: 16)
        container.addSubview(header)

        // Macro count label
        let countLabel = NSTextField(labelWithString: "\(macroData.count) mục")
        countLabel.frame = NSRect(x: 360, y: 320, width: 80, height: 16)
        countLabel.font = NSFont.systemFont(ofSize: 11)
        countLabel.textColor = NSColor.tertiaryLabelColor
        countLabel.alignment = .right
        countLabel.tag = 999  // Tag to find it later for updating
        container.addSubview(countLabel)

        // Macro table
        let card = GlassCardView(frame: NSRect(x: 20, y: 60, width: 420, height: 250))
        container.addSubview(card)

        let scrollView = NSScrollView(frame: NSRect(x: 8, y: 8, width: 404, height: 234))
        scrollView.hasVerticalScroller = true
        scrollView.autoresizingMask = [.width, .height]

        let tableView = NSTableView(frame: scrollView.bounds)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 24
        tableView.gridStyleMask = [.solidHorizontalGridLineMask]
        tableView.allowsMultipleSelection = false

        let shortcutColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("shortcut"))
        shortcutColumn.title = "Từ viết tắt"
        shortcutColumn.width = 150
        shortcutColumn.isEditable = true
        tableView.addTableColumn(shortcutColumn)

        let expansionColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("expansion"))
        expansionColumn.title = "Nội dung thay thế"
        expansionColumn.width = 240
        expansionColumn.isEditable = true
        tableView.addTableColumn(expansionColumn)

        scrollView.documentView = tableView
        card.addSubview(scrollView)

        self.macroTableView = tableView

        // Buttons
        let addButton = NSButton(title: "Thêm", target: self, action: #selector(addMacro(_:)))
        addButton.bezelStyle = .rounded
        addButton.frame = NSRect(x: 20, y: 20, width: 80, height: 30)
        container.addSubview(addButton)

        let removeButton = NSButton(title: "Xóa", target: self, action: #selector(removeMacro(_:)))
        removeButton.bezelStyle = .rounded
        removeButton.frame = NSRect(x: 108, y: 20, width: 80, height: 30)
        container.addSubview(removeButton)

        let resetButton = NSButton(title: "Mặc định", target: self, action: #selector(resetMacros(_:)))
        resetButton.bezelStyle = .rounded
        resetButton.frame = NSRect(x: 196, y: 20, width: 80, height: 30)
        container.addSubview(resetButton)

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

        let advCard = GlassCardView(frame: NSRect(x: 20, y: y, width: 420, height: 80))
        container.addSubview(advCard)

        let macroToggle = GlassToggle(frame: NSRect(x: 360, y: 48, width: 44, height: 24))
        macroToggle.isOn = prefs.macroEnabled
        macroToggle.onToggle = { [weak self] isOn in
            self?.prefs.macroEnabled = isOn
        }
        advCard.addSubview(macroToggle)

        let macroLabel = NSTextField(labelWithString: "Bật gõ tắt (Macro)")
        macroLabel.frame = NSRect(x: 16, y: 50, width: 300, height: 20)
        macroLabel.font = NSFont.systemFont(ofSize: 13)
        advCard.addSubview(macroLabel)

        // OSD notification toggle
        let osdToggle = GlassToggle(frame: NSRect(x: 360, y: 12, width: 44, height: 24))
        osdToggle.isOn = prefs.osdEnabled
        osdToggle.onToggle = { [weak self] isOn in
            self?.prefs.osdEnabled = isOn
        }
        advCard.addSubview(osdToggle)

        let osdLabel = NSTextField(labelWithString: "Hiện thông báo khi chuyển đổi Việt/Anh")
        osdLabel.frame = NSRect(x: 16, y: 14, width: 300, height: 20)
        osdLabel.font = NSFont.systemFont(ofSize: 13)
        advCard.addSubview(osdLabel)

        y -= 100

        // Section: Ứng dụng loại trừ
        let exclusionHeader = GlassSectionHeader(title: "ỨNG DỤNG LOẠI TRỪ")
        exclusionHeader.frame = NSRect(x: 20, y: y, width: 200, height: 16)
        container.addSubview(exclusionHeader)
        y -= 6

        let exclusionHint = NSTextField(labelWithString: "Tự động tắt gõ Việt khi dùng các ứng dụng sau:")
        exclusionHint.frame = NSRect(x: 20, y: y - 14, width: 420, height: 14)
        exclusionHint.font = NSFont.systemFont(ofSize: 10)
        exclusionHint.textColor = NSColor.tertiaryLabelColor
        container.addSubview(exclusionHint)

        // Buttons for exclusion
        let addExclButton = NSButton(title: "+", target: self, action: #selector(addExcludedApp(_:)))
        addExclButton.bezelStyle = .rounded
        addExclButton.frame = NSRect(x: 380, y: y - 16, width: 28, height: 20)
        addExclButton.font = NSFont.systemFont(ofSize: 13, weight: .bold)
        container.addSubview(addExclButton)

        let removeExclButton = NSButton(title: "−", target: self, action: #selector(removeExcludedApp(_:)))
        removeExclButton.bezelStyle = .rounded
        removeExclButton.frame = NSRect(x: 412, y: y - 16, width: 28, height: 20)
        removeExclButton.font = NSFont.systemFont(ofSize: 13, weight: .bold)
        container.addSubview(removeExclButton)

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

    // MARK: - Macro Actions (Fully Connected)

    @objc private func addMacro(_ sender: Any?) {
        // Show an input dialog to add a new macro
        let alert = NSAlert()
        alert.messageText = "Thêm gõ tắt mới"
        alert.informativeText = "Nhập từ viết tắt và nội dung thay thế:"
        alert.addButton(withTitle: "Thêm")
        alert.addButton(withTitle: "Hủy")

        let containerView = NSView(frame: NSRect(x: 0, y: 0, width: 300, height: 60))

        let shortcutLabel = NSTextField(labelWithString: "Viết tắt:")
        shortcutLabel.frame = NSRect(x: 0, y: 36, width: 70, height: 20)
        containerView.addSubview(shortcutLabel)

        let shortcutField = NSTextField(frame: NSRect(x: 75, y: 34, width: 225, height: 24))
        shortcutField.placeholderString = "vd: ko"
        containerView.addSubview(shortcutField)

        let expansionLabel = NSTextField(labelWithString: "Thay thế:")
        expansionLabel.frame = NSRect(x: 0, y: 4, width: 70, height: 20)
        containerView.addSubview(expansionLabel)

        let expansionField = NSTextField(frame: NSRect(x: 75, y: 2, width: 225, height: 24))
        expansionField.placeholderString = "vd: không"
        containerView.addSubview(expansionField)

        alert.accessoryView = containerView
        alert.window.initialFirstResponder = shortcutField

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            let shortcut = shortcutField.stringValue.trimmingCharacters(in: .whitespaces)
            let expansion = expansionField.stringValue.trimmingCharacters(in: .whitespaces)
            guard !shortcut.isEmpty, !expansion.isEmpty else { return }

            macroEngine.addMacro(shortcut: shortcut, expansion: expansion)
            reloadMacroData()
            macroTableView?.reloadData()
            updateMacroCountLabel()
        }
    }

    @objc private func removeMacro(_ sender: Any?) {
        guard let tableView = macroTableView else { return }
        let selectedRow = tableView.selectedRow
        guard selectedRow >= 0, selectedRow < macroData.count else {
            let alert = NSAlert()
            alert.messageText = "Chưa chọn mục nào"
            alert.informativeText = "Hãy chọn một mục trong bảng để xóa."
            alert.alertStyle = .informational
            alert.addButton(withTitle: "OK")
            alert.runModal()
            return
        }

        let shortcut = macroData[selectedRow].shortcut
        macroEngine.removeMacro(shortcut: shortcut)
        reloadMacroData()
        tableView.reloadData()
        updateMacroCountLabel()
    }

    @objc private func resetMacros(_ sender: Any?) {
        let alert = NSAlert()
        alert.messageText = "Khôi phục mặc định?"
        alert.informativeText = "Tất cả gõ tắt hiện tại sẽ bị thay thế bằng danh sách mặc định."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Khôi phục")
        alert.addButton(withTitle: "Hủy")

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            macroEngine.resetToDefaults()
            reloadMacroData()
            macroTableView?.reloadData()
            updateMacroCountLabel()
        }
    }

    @objc private func importMacros(_ sender: Any?) {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.begin { [weak self] response in
            guard response == .OK, let url = panel.url else { return }
            do {
                try self?.macroEngine.importMacros(from: url, merge: true)
                self?.reloadMacroData()
                DispatchQueue.main.async {
                    self?.macroTableView?.reloadData()
                    self?.updateMacroCountLabel()

                    let alert = NSAlert()
                    alert.messageText = "Nhập thành công!"
                    alert.informativeText = "Đã nhập gõ tắt từ file."
                    alert.alertStyle = .informational
                    alert.addButton(withTitle: "OK")
                    alert.runModal()
                }
            } catch {
                DispatchQueue.main.async {
                    let alert = NSAlert()
                    alert.messageText = "Lỗi nhập file"
                    alert.informativeText = error.localizedDescription
                    alert.alertStyle = .critical
                    alert.addButton(withTitle: "OK")
                    alert.runModal()
                }
            }
        }
    }

    @objc private func exportMacros(_ sender: Any?) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "macros.json"
        panel.begin { [weak self] response in
            guard response == .OK, let url = panel.url else { return }
            do {
                try self?.macroEngine.exportMacros(to: url)
                DispatchQueue.main.async {
                    let alert = NSAlert()
                    alert.messageText = "Xuất thành công!"
                    alert.informativeText = "Đã lưu \(self?.macroData.count ?? 0) gõ tắt."
                    alert.alertStyle = .informational
                    alert.addButton(withTitle: "OK")
                    alert.runModal()
                }
            } catch {
                DispatchQueue.main.async {
                    let alert = NSAlert()
                    alert.messageText = "Lỗi xuất file"
                    alert.informativeText = error.localizedDescription
                    alert.alertStyle = .critical
                    alert.addButton(withTitle: "OK")
                    alert.runModal()
                }
            }
        }
    }

    private func updateMacroCountLabel() {
        // Find the count label by tag in the macro tab
        if let macroView = tabView?.tabViewItem(at: 1).view {
            if let countLabel = macroView.viewWithTag(999) as? NSTextField {
                countLabel.stringValue = "\(macroData.count) mục"
            }
        }
    }

    // MARK: - App Exclusion Actions

    @objc private func addExcludedApp(_ sender: Any?) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.application]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.message = "Chọn ứng dụng muốn loại trừ"
        panel.prompt = "Thêm"

        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            if let bundle = Bundle(url: url), let bundleId = bundle.bundleIdentifier {
                let appName = url.deletingPathExtension().lastPathComponent
                AppExclusionManager.shared.addExcludedApp(bundleId: bundleId, name: appName)
                Log.ui("Added excluded app: \(appName) (\(bundleId))")
            }
        }
    }

    @objc private func removeExcludedApp(_ sender: Any?) {
        // Show list of excluded apps to remove
        let excluded = AppExclusionManager.shared.excludedApps
        guard !excluded.isEmpty else {
            let alert = NSAlert()
            alert.messageText = "Chưa có ứng dụng loại trừ"
            alert.informativeText = "Bấm + để thêm ứng dụng vào danh sách loại trừ."
            alert.addButton(withTitle: "OK")
            alert.runModal()
            return
        }

        let alert = NSAlert()
        alert.messageText = "Xóa ứng dụng loại trừ"
        alert.informativeText = "Chọn ứng dụng muốn xóa khỏi danh sách:"
        alert.addButton(withTitle: "Xóa")
        alert.addButton(withTitle: "Hủy")

        let popup = NSPopUpButton(frame: NSRect(x: 0, y: 0, width: 250, height: 26), pullsDown: false)
        for app in excluded {
            popup.addItem(withTitle: "\(app.name) (\(app.bundleId))")
        }
        alert.accessoryView = popup

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            let selectedIndex = popup.indexOfSelectedItem
            guard selectedIndex >= 0, selectedIndex < excluded.count else { return }
            AppExclusionManager.shared.removeExcludedApp(bundleId: excluded[selectedIndex].bundleId)
        }
    }

    @objc private func convertClipboard(_ sender: Any?) {
        Log.ui("Convert clipboard action")
        // TODO: Implement clipboard conversion
    }
}

// MARK: - NSTableViewDataSource & NSTableViewDelegate (Macro Table)

extension PreferencesWindowController: NSTableViewDataSource, NSTableViewDelegate {

    func numberOfRows(in tableView: NSTableView) -> Int {
        return macroData.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard row < macroData.count else { return nil }

        let identifier = tableColumn?.identifier ?? NSUserInterfaceItemIdentifier("shortcut")
        let cellId = NSUserInterfaceItemIdentifier("MacroCell_\(identifier.rawValue)")

        let textField: NSTextField
        if let existing = tableView.makeView(withIdentifier: cellId, owner: self) as? NSTextField {
            textField = existing
        } else {
            textField = NSTextField()
            textField.identifier = cellId
            textField.isBordered = false
            textField.drawsBackground = false
            textField.font = NSFont.systemFont(ofSize: 13)
            textField.isEditable = true
            textField.delegate = self
        }

        // Tag encodes row + column for edit tracking
        textField.tag = row

        if identifier.rawValue == "shortcut" {
            textField.stringValue = macroData[row].shortcut
        } else {
            textField.stringValue = macroData[row].expansion
        }

        return textField
    }
}

// MARK: - NSTextFieldDelegate (Inline Macro Editing)

extension PreferencesWindowController: NSTextFieldDelegate {

    func controlTextDidEndEditing(_ obj: Notification) {
        guard let textField = obj.object as? NSTextField,
              let tableView = macroTableView else { return }

        let row = tableView.row(for: textField)
        let column = tableView.column(for: textField)
        guard row >= 0, row < macroData.count else { return }

        let oldEntry = macroData[row]
        let newValue = textField.stringValue.trimmingCharacters(in: .whitespaces)
        guard !newValue.isEmpty else { return }

        if column == 0 {
            // Shortcut changed
            macroEngine.updateMacro(oldShortcut: oldEntry.shortcut, newShortcut: newValue, expansion: oldEntry.expansion)
        } else {
            // Expansion changed
            macroEngine.updateMacro(oldShortcut: oldEntry.shortcut, newShortcut: oldEntry.shortcut, expansion: newValue)
        }

        reloadMacroData()
        tableView.reloadData()
    }
}
