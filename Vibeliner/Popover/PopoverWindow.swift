import AppKit

class PopoverBorderedSurfaceView: AppearanceAwareSurfaceView {
    var surfaceCornerRadius: CGFloat = 10

    override func refreshSurfaceAppearance() {
        SettingsUI.styleSurface(
            self,
            background: .clear,
            border: NSColor.separatorColor,
            cornerRadius: surfaceCornerRadius,
            borderWidth: 0.5
        )
    }
}

class PopoverHoverSurfaceView: AppearanceAwareSurfaceView {
    var hoverCornerRadius: CGFloat = 4
    var isSurfaceHovered = false {
        didSet { refreshSurfaceAppearance() }
    }

    override func refreshSurfaceAppearance() {
        SettingsUI.styleSurface(
            self,
            background: isSurfaceHovered ? DesignTokens.toolbarButtonHoverBg : .clear,
            cornerRadius: hoverCornerRadius,
            borderWidth: 0
        )
    }
}

final class PopoverDividerView: AppearanceAwareSurfaceView {
    override func refreshSurfaceAppearance() {
        SettingsUI.styleDividerSurface(self)
    }
}

final class PopoverKeyboardPillView: AppearanceAwareSurfaceView {
    override func refreshSurfaceAppearance() {
        SettingsUI.styleSurface(
            self,
            background: NSColor.quaternaryLabelColor,
            border: NSColor.separatorColor,
            cornerRadius: 5
        )
    }
}

// MARK: - Custom dark popover window (NOT NSPopover — that uses system chrome)

final class PopoverWindow: NSPanel {

    var onClose: (() -> Void)?  // VIB-175: callback when popover closes for any reason
    private var popoverContent: PopoverContentView?
    private var clickMonitor: Any?

    init() {
        super.init(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        level = .popUpMenu
        isMovableByWindowBackground = false
        isReleasedWhenClosed = false
        becomesKeyOnlyIfNeeded = true  // VIB-219: accept first click without activating app
    }

    override var canBecomeKey: Bool { true }

    /// Show below the status bar button
    func showRelativeTo(button: NSStatusBarButton) {
        guard let buttonWindow = button.window else { return }
        let buttonFrame = button.convert(button.bounds, to: nil)
        let screenFrame = buttonWindow.convertToScreen(buttonFrame)

        // Build content
        let content = PopoverContentView()
        content.popoverWindow = self
        self.popoverContent = content

        let popW: CGFloat = 240
        let contentH = content.frame.height

        // Position: centered below the status bar button with small gap
        let x = screenFrame.midX - popW / 2
        let y = screenFrame.minY - contentH - 4

        // Set window frame to exactly fit content
        let winFrame = NSRect(x: x, y: y, width: popW, height: contentH)
        setFrame(winFrame, display: false)

        // Set content view to a clear container, add our custom view inside
        let container = NSView(frame: NSRect(origin: .zero, size: winFrame.size))
        self.contentView = container
        content.frame.origin = .zero
        container.addSubview(content)

        orderFront(nil)

        // Close on click outside
        clickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.closePopover()
        }
    }

    func closePopover() {
        orderOut(nil)
        if let monitor = clickMonitor {
            NSEvent.removeMonitor(monitor)
            clickMonitor = nil
        }
        onClose?()  // VIB-175: notify AppDelegate to restore normal icon
    }
}

// MARK: - Popover content view (dark frosted glass with arrow)
