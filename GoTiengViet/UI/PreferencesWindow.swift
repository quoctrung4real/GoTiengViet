import Cocoa

/// Preferences window controller with Liquid Glass design & Auto Layout
class PreferencesWindowController: NSWindowController {

    private let prefs = PreferencesManager.shared
    private let macroEngine = MacroEngine()

    /// Container for the active tab view
    private let containerView = NSView()
    
    private let headerStack = NSStackView()
    private let segmentedControl = NSSegmentedControl(labels: ["Chung", "Gõ tắt", "Chuyển mã", "Nâng cao"], trackingMode: .selectOne, target: nil, action: nil)

    private var activeTabIndex: Int = -1
    
    /// Keep track of active constraints so we can deactivate them before switching tabs
    private var activeConstraints: [NSLayoutConstraint] = []
    private var containerBottomConstraint: NSLayoutConstraint?

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
        visualEffect.material = .popover // Maximum frosted glass effect
        window.contentView = visualEffect

        super.init(window: window)

        setupContainer()

        // Select first tab
        segmentedControl.selectedSegment = 0
        switchTab(to: 0)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    // MARK: - Setup

    private func setupContainer() {
        guard let contentView = window?.contentView else { return }

        // 1. Setup Header
        headerStack.orientation = .vertical
        headerStack.alignment = .centerX
        headerStack.spacing = 16
        headerStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(headerStack)

        let titleLabel = NSTextField(labelWithString: "Gõ Tiếng Việt")
        titleLabel.font = .systemFont(ofSize: 32, weight: .bold)
        titleLabel.textColor = .labelColor
        headerStack.addArrangedSubview(titleLabel)

        segmentedControl.segmentStyle = .separated
        segmentedControl.target = self
        segmentedControl.action = #selector(segmentChanged(_:))
        headerStack.addArrangedSubview(segmentedControl)

        // 2. Setup Container
        containerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(containerView)

        NSLayoutConstraint.activate([
            headerStack.topAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.topAnchor, constant: 32),
            headerStack.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            containerView.topAnchor.constraint(equalTo: headerStack.bottomAnchor, constant: 32),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32)
        ])
        
        containerBottomConstraint = containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -32)
        containerBottomConstraint?.isActive = true
    }

    @objc private func segmentChanged(_ sender: NSSegmentedControl) {
        switchTab(to: sender.selectedSegment)
    }

    // MARK: - Tab Switching

    private func switchTab(to index: Int) {
        guard index != activeTabIndex else { return }
        activeTabIndex = index

        // Remove current views and deactivate constraints
        NSLayoutConstraint.deactivate(activeConstraints)
        activeConstraints.removeAll()
        containerView.subviews.forEach { $0.removeFromSuperview() }

        let newView: NSView
        switch index {
        case 0:
            newView = GeneralPrefsView()
        case 1:
            newView = MacroPrefsView(macroEngine: macroEngine)
        case 2:
            newView = ConvertPrefsView()
        case 3:
            newView = AdvancedPrefsView()
        default:
            return
        }

        newView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(newView)

        // Only anchor top, leading, and trailing first to calculate fitting height
        activeConstraints = [
            newView.topAnchor.constraint(equalTo: containerView.topAnchor),
            newView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            newView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
        ]
        NSLayoutConstraint.activate(activeConstraints)
        
        // Force layout of the entire container to properly calculate widths before getting fittingSize
        window?.contentView?.layoutSubtreeIfNeeded()
        let targetHeight = newView.fittingSize.height
        
        // Calculate new window frame
        if let window = window {
            let targetHeight = newView.fittingSize.height
            
            // Calculate absolute top padding including safe area and header
            let topInset = window.contentView!.safeAreaInsets.top
            let headerHeight = headerStack.fittingSize.height
            // totalHeight = safeArea + 32 + headerHeight + 32 + targetHeight + 32
            let totalHeight = topInset + 32 + headerHeight + 32 + targetHeight + 32
            
            var frame = window.frame
            let heightDiff = totalHeight - window.contentView!.bounds.height
            frame.origin.y -= heightDiff
            frame.size.height = totalHeight
            
            // Animate window resize first
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.2
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                window.animator().setFrame(frame, display: true)
            }, completionHandler: {
                // Apply bottom constraint AFTER window has resized, if view is still active
                if newView.superview == self.containerView {
                    let bottomConstraint = newView.bottomAnchor.constraint(equalTo: self.containerView.bottomAnchor)
                    self.activeConstraints.append(bottomConstraint)
                    bottomConstraint.isActive = true
                }
            })
        }
    }
}
