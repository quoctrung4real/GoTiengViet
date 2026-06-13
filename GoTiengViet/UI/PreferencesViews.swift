import Cocoa

// MARK: - General Tab

class GeneralPrefsView: NSView {

    private let prefs = PreferencesManager.shared

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    private func setup() {
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .width
        stack.spacing = 24
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        // 1. KIỂU GÕ
        let inputSection = createSection(title: "KIỂU GÕ VÀ DẤU THANH") {
            let vStack = NSStackView()
            vStack.orientation = .vertical
            vStack.spacing = 16
            vStack.alignment = .leading

            // Input Method
            let inputMethodRow = createRow(label: "Phương pháp gõ:") {
                let dropdown = GlassDropdown(frame: .zero, pullsDown: false)
                dropdown.addItems(withTitles: AppConstants.InputMethod.allCases.map { $0.displayName })
                dropdown.selectItem(withTitle: prefs.inputMethod.displayName)
                dropdown.target = self
                dropdown.action = #selector(inputMethodChanged(_:))
                dropdown.widthAnchor.constraint(equalToConstant: 120).isActive = true
                return dropdown
            }
            vStack.addArrangedSubview(inputMethodRow)

            // Tone Style
            let toneStyleRow = createRow(label: "Vị trí dấu thanh:") {
                let dropdown = GlassDropdown(frame: .zero, pullsDown: false)
                dropdown.addItems(withTitles: AppConstants.ToneStyle.allCases.map { $0.displayName })
                dropdown.selectItem(withTitle: prefs.toneStyle.displayName)
                dropdown.target = self
                dropdown.action = #selector(toneStyleChanged(_:))
                dropdown.widthAnchor.constraint(equalToConstant: 160).isActive = true
                return dropdown
            }
            vStack.addArrangedSubview(toneStyleRow)

            // Tone UI Checkboxes
            let checkboxes = NSStackView()
            checkboxes.orientation = .vertical
            checkboxes.spacing = 8
            checkboxes.alignment = .leading

            let spellCheckBtn = NSButton(checkboxWithTitle: "Kiểm tra chính tả (chỉ cho phép gõ dấu hợp lệ)", target: self, action: #selector(spellCheckToggled(_:)))
            spellCheckBtn.state = prefs.spellCheckEnabled ? .on : .off
            checkboxes.addArrangedSubview(spellCheckBtn)

            vStack.addArrangedSubview(checkboxes)

            return vStack
        }
        stack.addArrangedSubview(inputSection)

        // 2. KHỞI ĐỘNG
        let startupSection = createSection(title: "HỆ THỐNG") {
            let row = createRow(label: "Khởi động cùng macOS:") {
                let toggle = GlassToggle(frame: NSRect(x: 0, y: 0, width: 44, height: 24))
                toggle.isOn = LaunchAtLoginManager.shared.isEnabled
                toggle.onToggle = { isOn in
                    LaunchAtLoginManager.shared.setEnabled(isOn)
                }
                return toggle
            }
            return row
        }
        stack.addArrangedSubview(startupSection)

        // 3. PHÍM TẮT
        let hotkeySection = createSection(title: "PHÍM TẮT CHUYỂN ĐỔI") {
            let row = createRow(label: "Phím tắt Việt/Anh:") {
                let recorder = HotkeyRecorderView(frame: NSRect(x: 0, y: 0, width: 144, height: 28))
                recorder.widthAnchor.constraint(equalToConstant: 144).isActive = true
                recorder.heightAnchor.constraint(equalToConstant: 28).isActive = true
                recorder.onHotkeyChanged = { keyCode, modifiers in
                    HotkeyManager.shared.registerHotkey(keyCode: keyCode, modifiers: modifiers)
                }
                return recorder
            }
            return row
        }
        stack.addArrangedSubview(hotkeySection)
    }

    // MARK: - Actions

    @objc private func inputMethodChanged(_ sender: NSPopUpButton) {
        guard let title = sender.titleOfSelectedItem else { return }
        if let method = AppConstants.InputMethod.allCases.first(where: { $0.displayName == title }) {
            prefs.inputMethod = method
            NotificationCenter.default.post(name: NSNotification.Name("InputMethodChanged"), object: nil)
        }
    }

    @objc private func toneStyleChanged(_ sender: NSPopUpButton) {
        guard let title = sender.titleOfSelectedItem else { return }
        if let style = AppConstants.ToneStyle.allCases.first(where: { $0.displayName == title }) {
            prefs.toneStyle = style
        }
    }

    @objc private func spellCheckToggled(_ sender: NSButton) {
        prefs.spellCheckEnabled = sender.state == .on
    }
}

// MARK: - Macro Tab

class MacroPrefsView: NSView, NSTableViewDelegate, NSTableViewDataSource, NSTextFieldDelegate {

    private let macroEngine: MacroEngine
    private var macroData: [(shortcut: String, expansion: String)] = []
    private var tableView: NSTableView!

    init(macroEngine: MacroEngine) {
        self.macroEngine = macroEngine
        super.init(frame: .zero)
        reloadMacroData()
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func reloadMacroData() {
        macroData = macroEngine.getAllMacros()
            .map { (shortcut: $0.key, expansion: $0.value) }
            .sorted(by: { $0.shortcut < $1.shortcut })
    }

    private func setup() {
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .width
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        let enableBtn = NSButton(checkboxWithTitle: "Bật tính năng Gõ tắt (Macro)", target: self, action: #selector(toggleMacro(_:)))
        enableBtn.state = PreferencesManager.shared.macroEnabled ? .on : .off
        stack.addArrangedSubview(enableBtn)

        // Scroll view and Table
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.borderType = .bezelBorder
        scrollView.heightAnchor.constraint(equalToConstant: 250).isActive = true

        tableView = NSTableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 24
        tableView.usesAlternatingRowBackgroundColors = true
        tableView.allowsMultipleSelection = false
        tableView.style = .inset

        let col1 = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("Shortcut"))
        col1.title = "Gõ tắt"
        col1.width = 120
        tableView.addTableColumn(col1)

        let col2 = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("Expansion"))
        col2.title = "Đổi thành"
        col2.width = 300
        tableView.addTableColumn(col2)

        scrollView.documentView = tableView
        stack.addArrangedSubview(scrollView)

        // Buttons
        let hStack = NSStackView()
        hStack.orientation = .horizontal
        hStack.spacing = 8

        let addBtn = NSButton(title: "Thêm", target: self, action: #selector(addMacro))
        let rmBtn = NSButton(title: "Xóa", target: self, action: #selector(removeMacro))
        let impBtn = NSButton(title: "Nhập...", target: self, action: #selector(importMacros))
        let expBtn = NSButton(title: "Xuất...", target: self, action: #selector(exportMacros))
        let defBtn = NSButton(title: "Mặc định", target: self, action: #selector(resetMacros))

        hStack.addArrangedSubview(addBtn)
        hStack.addArrangedSubview(rmBtn)
        hStack.addArrangedSubview(NSView()) // Spacer
        hStack.addArrangedSubview(impBtn)
        hStack.addArrangedSubview(expBtn)
        hStack.addArrangedSubview(defBtn)

        stack.addArrangedSubview(hStack)
    }

    @objc private func toggleMacro(_ sender: NSButton) {
        PreferencesManager.shared.macroEnabled = sender.state == .on
    }

    // MARK: - Actions
    @objc private func addMacro() {
        let alert = NSAlert()
        alert.messageText = "Thêm từ gõ tắt mới"

        let stack = NSStackView(frame: NSRect(x: 0, y: 0, width: 260, height: 60))
        stack.orientation = .vertical

        let shortcutField = NSTextField(string: "")
        shortcutField.placeholderString = "Gõ tắt (vd: vn)"
        let expansionField = NSTextField(string: "")
        expansionField.placeholderString = "Đổi thành (vd: Việt Nam)"

        stack.addArrangedSubview(shortcutField)
        stack.addArrangedSubview(expansionField)

        alert.accessoryView = stack
        alert.addButton(withTitle: "Thêm")
        alert.addButton(withTitle: "Hủy")

        if alert.runModal() == .alertFirstButtonReturn {
            let sc = shortcutField.stringValue.trimmingCharacters(in: .whitespaces)
            let exp = expansionField.stringValue.trimmingCharacters(in: .whitespaces)
            if !sc.isEmpty && !exp.isEmpty {
                macroEngine.addMacro(shortcut: sc, expansion: exp)
                reloadMacroData()
                tableView.reloadData()
            }
        }
    }

    @objc private func removeMacro() {
        let row = tableView.selectedRow
        guard row >= 0 else { return }
        let macro = macroData[row]
        macroEngine.removeMacro(shortcut: macro.shortcut)
        reloadMacroData()
        tableView.reloadData()
    }

    @objc private func resetMacros() {
        macroEngine.resetToDefaults()
        reloadMacroData()
        tableView.reloadData()
    }

    @objc private func importMacros() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        if panel.runModal() == .OK, let url = panel.url {
            let alert = NSAlert()
            alert.messageText = "Import JSON chưa được hỗ trợ hoàn chỉnh."
            alert.runModal()
        }
    }

    @objc private func exportMacros() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "GoTiengViet_Macros.json"
        if panel.runModal() == .OK, let url = panel.url {
            let alert = NSAlert()
            alert.messageText = "Export JSON chưa được hỗ trợ hoàn chỉnh."
            alert.runModal()
        }
    }

    // MARK: - NSTableViewDataSource

    func numberOfRows(in tableView: NSTableView) -> Int {
        return macroData.count
    }

    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        let macro = macroData[row]
        return tableColumn?.identifier.rawValue == "Shortcut" ? macro.shortcut : macro.expansion
    }

    func tableView(_ tableView: NSTableView, setObjectValue object: Any?, for tableColumn: NSTableColumn?, row: Int) {
        guard let newValue = object as? String, !newValue.isEmpty else { return }
        let macro = macroData[row]

        if tableColumn?.identifier.rawValue == "Shortcut" {
            macroEngine.removeMacro(shortcut: macro.shortcut)
            macroEngine.addMacro(shortcut: newValue, expansion: macro.expansion)
        } else {
            macroEngine.addMacro(shortcut: macro.shortcut, expansion: newValue)
        }
        reloadMacroData()
    }
}

// MARK: - Convert Tab

class ConvertPrefsView: NSView {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        let label = NSTextField(labelWithString: "Tính năng Chuyển mã văn bản sẽ được cập nhật trong phiên bản tiếp theo.")
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
            heightAnchor.constraint(greaterThanOrEqualToConstant: 200)
        ])
    }
    required init?(coder: NSCoder) { fatalError() }
}

// MARK: - Advanced Tab

class AdvancedPrefsView: NSView, NSTableViewDelegate, NSTableViewDataSource {
    private var tableView: NSTableView!

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.spacing = 24
        stack.alignment = .width
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        // UX Options
        let uxSection = createSection(title: "TRẢI NGHIỆM NGƯỜI DÙNG") {
            let vStack = NSStackView()
            vStack.orientation = .vertical
            vStack.spacing = 8
            vStack.alignment = .leading

            let osdBtn = NSButton(checkboxWithTitle: "Hiển thị thông báo (OSD) khi chuyển đổi ngôn ngữ", target: self, action: #selector(osdToggled(_:)))
            osdBtn.state = PreferencesManager.shared.osdEnabled ? .on : .off
            vStack.addArrangedSubview(osdBtn)

            return vStack
        }
        stack.addArrangedSubview(uxSection)

        // Excluded Apps
        let excludeSection = createSection(title: "LOẠI TRỪ ỨNG DỤNG") {
            let vStack = NSStackView()
            vStack.orientation = .vertical
            vStack.spacing = 8

            let label = NSTextField(labelWithString: "Tự động tắt Tiếng Việt khi sử dụng các ứng dụng này:")
            label.font = NSFont.systemFont(ofSize: 12)
            label.textColor = .secondaryLabelColor
            vStack.addArrangedSubview(label)

            // Table
            let scrollView = NSScrollView()
            scrollView.hasVerticalScroller = true
            scrollView.borderType = .bezelBorder
            scrollView.heightAnchor.constraint(equalToConstant: 160).isActive = true
            scrollView.widthAnchor.constraint(equalToConstant: 400).isActive = true

            tableView = NSTableView()
            tableView.delegate = self
            tableView.dataSource = self
            tableView.headerView = nil

            let col = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("BundleID"))
            tableView.addTableColumn(col)

            scrollView.documentView = tableView
            vStack.addArrangedSubview(scrollView)

            let hStack = NSStackView()
            hStack.orientation = .horizontal
            hStack.spacing = 8

            let addBtn = NSButton(title: "Thêm...", target: self, action: #selector(addApp))
            let rmBtn = NSButton(title: "Xóa", target: self, action: #selector(removeApp))

            hStack.addArrangedSubview(addBtn)
            hStack.addArrangedSubview(rmBtn)
            vStack.addArrangedSubview(hStack)

            return vStack
        }
        stack.addArrangedSubview(excludeSection)
    }

    @objc private func osdToggled(_ sender: NSButton) {
        PreferencesManager.shared.osdEnabled = sender.state == .on
    }

    @objc private func addApp() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.application]
        if panel.runModal() == .OK, let url = panel.url {
            if let bundle = Bundle(url: url), let bundleId = bundle.bundleIdentifier {
                let name = url.deletingPathExtension().lastPathComponent
                AppExclusionManager.shared.addExcludedApp(bundleId: bundleId, name: name)
                tableView.reloadData()
            }
        }
    }

    @objc private func removeApp() {
        let row = tableView.selectedRow
        guard row >= 0 else { return }
        let apps = AppExclusionManager.shared.excludedApps
        AppExclusionManager.shared.removeExcludedApp(bundleId: apps[row].bundleId)
        tableView.reloadData()
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        return AppExclusionManager.shared.excludedApps.count
    }

    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        return AppExclusionManager.shared.excludedApps[row].bundleId
    }
}

// MARK: - Helper UI Builders

fileprivate func createSection(title: String, content: () -> NSView) -> NSStackView {
    let stack = NSStackView()
    stack.orientation = .vertical
    stack.alignment = .width
    stack.spacing = 12

    let header = GlassSectionHeader(title: title)
    stack.addArrangedSubview(header)

    let card = GlassCardView(frame: .zero)
    card.translatesAutoresizingMaskIntoConstraints = false
    stack.addArrangedSubview(card)

    let innerView = content()
    innerView.setContentCompressionResistancePriority(.required, for: .vertical)
    innerView.translatesAutoresizingMaskIntoConstraints = false
    card.addSubview(innerView)

    NSLayoutConstraint.activate([
        innerView.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
        innerView.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),
        innerView.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
        innerView.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16)
    ])

    return stack
}

fileprivate func createRow(label: String, control: () -> NSView) -> NSStackView {
    let stack = NSStackView()
    stack.orientation = .horizontal
    stack.alignment = .centerY
    stack.spacing = 16

    let labelView = NSTextField(labelWithString: label)
    labelView.font = NSFont.systemFont(ofSize: 13, weight: .medium)
    labelView.textColor = .secondaryLabelColor
    // Force a fixed width so the controls align perfectly vertically!
    labelView.widthAnchor.constraint(equalToConstant: 150).isActive = true
    labelView.alignment = .left // Căn lề trái theo yêu cầu
    stack.addArrangedSubview(labelView)

    let controlView = control()
    stack.addArrangedSubview(controlView)

    return stack
}
