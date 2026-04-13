import AppKit

final class SetupWindowController: NSWindowController {

    // MARK: - State

    var step1Done = false
    var step2Done = false
    var step3Done = false
    var folderPath = ""
    var isRerun: Bool

    // MARK: - UI refs

    var panel1Container: NSView!
    var panel2Container: NSView!
    var panel3Container: NSView!
    var footerContent: SetupFooterSurfaceView!
    var badge1View: NSView!
    var badge2View: NSView!
    var badge3View: NSView!
    var step1ActionRow: NSView!
    var step1DoneArea: NSView!
    var pathDisplay: NSTextField!
    var step2ActionRow: NSView!
    var step2Helper: NSTextField!
    var step3ActionRow: NSView!
    var step3RestartNote: NSTextField!
    var status1: NSTextField!
    var status2: NSTextField!
    var status3: NSTextField!
    var permissionTimer: Timer?
    var divider1: NSView!
    var divider2: NSView!
    var footerBorderView: NSView!

    // MARK: - Init

    convenience init() {
        let winW = DesignTokens.setupWindowWidth
        let totalH = DesignTokens.setupPanelHeight + DesignTokens.setupFooterHeight
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: winW, height: totalH),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Welcome to Vibeliner"
        window.center()
        window.isReleasedWhenClosed = false
        // VIB-332: Follow system appearance — no forced dark mode
        window.backgroundColor = DesignTokens.setupWindowBg
        self.init(window: window)
        buildUI()
        startPermissionPolling()
    }

    override init(window: NSWindow?) {
        isRerun = ConfigManager.shared.capturesFolderExists
        super.init(window: window)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    deinit { permissionTimer?.invalidate() }

    // MARK: - Build UI

    func buildUI() {
        // VIB-332: Use SetupContentView to track appearance changes for layer color re-application
        let contentView = SetupContentView(frame: window?.contentView?.frame ?? .zero)
        contentView.wantsLayer = true
        window?.contentView = contentView
        contentView.onAppearanceChange = { [weak self] in self?.reapplyLayerColors() }
        guard let cv = window?.contentView else { return }
        cv.wantsLayer = true

        let winW = DesignTokens.setupWindowWidth
        let footerH = DesignTokens.setupFooterHeight
        let panelH = DesignTokens.setupPanelHeight
        let panelW = (winW - 2) / 3

        let panelsY = footerH

        // VIB-303: Panel 1: Captures folder (immediately active)
        panel1Container = NSView(frame: NSRect(x: 0, y: panelsY, width: panelW, height: panelH))
        buildPanel1(in: panel1Container)
        cv.addSubview(panel1Container)

        // Divider 1
        divider1 = makeDivider(x: panelW, y: panelsY, height: panelH)
        cv.addSubview(divider1)

        // VIB-303: Panel 2: Accessibility (locked until folder chosen)
        panel2Container = NSView(frame: NSRect(x: panelW + 1, y: panelsY, width: panelW, height: panelH))
        buildPanel2(in: panel2Container)
        cv.addSubview(panel2Container)
        panel2Container.alphaValue = 0.35

        // Divider 2
        divider2 = makeDivider(x: panelW * 2 + 1, y: panelsY, height: panelH)
        cv.addSubview(divider2)

        // VIB-303: Panel 3: Screen recording (locked until accessibility granted)
        panel3Container = NSView(frame: NSRect(x: panelW * 2 + 2, y: panelsY, width: panelW, height: panelH))
        buildPanel3(in: panel3Container)
        cv.addSubview(panel3Container)
        panel3Container.alphaValue = 0.35

        // Footer
        footerContent = SetupFooterSurfaceView(frame: NSRect(x: 0, y: 0, width: winW, height: footerH))
        cv.addSubview(footerContent)

        footerBorderView = makeDivider(x: 0, y: footerH - 1, height: 1)
        footerBorderView.frame.size.width = winW
        cv.addSubview(footerBorderView)

        updateFooter()
    }

    // MARK: - Permission polling

    // VIB-303: Reordered — step 1 is folder (no polling), step 2 is accessibility, step 3 is screen recording
    func startPermissionPolling() {
        // Immediate check: if re-running with valid folder, auto-complete step 1
        if isRerun && !folderPath.isEmpty && ConfigManager.shared.capturesFolderExists {
            completeStep1()
        }

        permissionTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            if self.step1Done && !self.step2Done && AXIsProcessTrusted() {
                self.completeStep2()
            }
            if self.step2Done && !self.step3Done && CGPreflightScreenCaptureAccess() {
                self.completeStep3()
            }
        }
    }

}
