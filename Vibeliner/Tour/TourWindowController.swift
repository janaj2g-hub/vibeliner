import AppKit

final class TourWindowController: NSWindowController {

    // MARK: - Singleton

    static let shared = TourWindowController()

    // MARK: - State

    var currentStep = 0
    let steps = TourStep.allSteps

    // MARK: - UI refs — header

    var headerView: NSView!
    var headerBorderView: NSView!
    var exitButton: ExitTourPillView!

    // MARK: - UI refs — body

    var bodyView: NSView!
    var illustrationPane: NSView!
    var dividerView: NSView!
    var textPane: NSView!
    var stepBadgeLabel: NSTextField!
    var titleLabel: NSTextField!
    var bodyLabel: NSTextField!

    // MARK: - UI refs — footer

    var footerView: NSView!
    var footerBorderView: NSView!
    var progressLabel: NSTextField!
    var progressBars: [NSView] = []
    var backButton: HoverButton!
    var nextButton: HoverButton!

    // MARK: - UI refs — step 9 full-width done view

    var doneView: NSView?

    // MARK: - Layout constraints for split mode

    var illustrationWidthConstraint: NSLayoutConstraint!
    var textPaneWidthConstraint: NSLayoutConstraint!

    // MARK: - Init

    private init() {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0,
                                width: DesignTokens.tourWindowWidth,
                                height: DesignTokens.tourWindowHeight),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isMovableByWindowBackground = true
        panel.hasShadow = true
        panel.isReleasedWhenClosed = false
        panel.backgroundColor = .clear
        panel.isOpaque = false  // Keep false for rounded corners to show through

        super.init(window: panel)

        buildUI()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    // MARK: - Public API

    func showTour() {
        currentStep = 0
        refreshAppearanceColors()
        window?.center()
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

}
