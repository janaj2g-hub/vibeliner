import AppKit

final class PermissionPanel: NSView {

    weak var setupController: SetupWindowController?
    private var pollTimer: Timer?
    private let openButton = NSButton(title: "Open System Settings →", target: nil, action: nil)
    private let descLabel = NSTextField(wrappingLabelWithString: "")
    private let successLabel = NSTextField(labelWithString: "")

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
        if CGPreflightScreenCaptureAccess() {
            markComplete()
        } else {
            startPolling()
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupView() {
        descLabel.stringValue = "Vibeliner needs screen recording permission to capture screenshots of your running app."
        descLabel.font = NSFont.systemFont(ofSize: 13)
        descLabel.textColor = NSColor(white: 0.33, alpha: 1)
        descLabel.isEditable = false
        descLabel.isBordered = false
        descLabel.drawsBackground = false
        addSubview(descLabel)

        openButton.bezelStyle = .rounded
        openButton.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        openButton.target = self
        openButton.action = #selector(openSettings)
        addSubview(openButton)

        successLabel.font = NSFont.systemFont(ofSize: 12)
        successLabel.textColor = NSColor(red: 21/255, green: 128/255, blue: 61/255, alpha: 1)
        successLabel.isHidden = true
        addSubview(successLabel)
    }

    override func layout() {
        super.layout()
        let w = bounds.width
        descLabel.frame = NSRect(x: 0, y: bounds.height - 60, width: w, height: 48)
        openButton.frame = NSRect(x: 0, y: bounds.height - 90, width: w, height: 28)
        successLabel.frame = NSRect(x: 0, y: bounds.height - 86, width: w, height: 16)
    }

    @objc private func openSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
            NSWorkspace.shared.open(url)
        }
    }

    private func startPolling() {
        pollTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            if CGPreflightScreenCaptureAccess() {
                self?.markComplete()
            }
        }
    }

    private func markComplete() {
        pollTimer?.invalidate()
        pollTimer = nil
        openButton.isHidden = true
        successLabel.stringValue = "Vibeliner can now capture your screen."
        successLabel.isHidden = false
        setupController?.completeStep1()
    }

    deinit { pollTimer?.invalidate() }
}
