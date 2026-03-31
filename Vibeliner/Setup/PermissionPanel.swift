import AppKit

final class PermissionPanel: NSView {

    weak var setupController: SetupWindowController?
    private var pollTimer: Timer?
    private let openButton = NSButton(title: "Open System Settings →", target: nil, action: nil)
    private let descLabel = NSTextField(wrappingLabelWithString: "")
    private let helperLabel = NSTextField(wrappingLabelWithString: "")

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
        startPolling()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupView() {
        descLabel.stringValue = "Vibeliner needs screen recording permission to capture screenshots of your running app."
        descLabel.font = NSFont.systemFont(ofSize: 12)
        descLabel.textColor = NSColor(white: 0.3, alpha: 1)
        descLabel.isEditable = false
        descLabel.isBordered = false
        descLabel.drawsBackground = false
        addSubview(descLabel)

        openButton.bezelStyle = .rounded
        openButton.target = self
        openButton.action = #selector(openSettings)
        addSubview(openButton)

        helperLabel.stringValue = "Toggle Vibeliner on in Privacy & Security → Screen Recording. You may need to restart the app."
        helperLabel.font = NSFont.systemFont(ofSize: 11)
        helperLabel.textColor = NSColor(white: 0.5, alpha: 1)
        helperLabel.isEditable = false
        helperLabel.isBordered = false
        helperLabel.drawsBackground = false
        addSubview(helperLabel)

        if CGPreflightScreenCaptureAccess() {
            markComplete()
        }
    }

    override func layout() {
        super.layout()
        let w = bounds.width
        descLabel.frame = NSRect(x: 0, y: bounds.height - 50, width: w, height: 40)
        openButton.frame = NSRect(x: (w - 180) / 2, y: bounds.height - 84, width: 180, height: 28)
        helperLabel.frame = NSRect(x: 0, y: 0, width: w, height: 40)
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
        helperLabel.stringValue = "Vibeliner can now capture your screen."
        setupController?.completeStep1()
    }

    deinit {
        pollTimer?.invalidate()
    }
}
