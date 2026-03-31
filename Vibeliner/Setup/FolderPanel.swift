import AppKit

final class FolderPanel: NSView {

    weak var setupController: SetupWindowController?
    private let pathLabel = NSTextField(labelWithString: "~/Documents/vibeliner")
    private let createButton = NSButton(title: "Create folder", target: nil, action: nil)
    private let chooseButton = NSButton(title: "Choose different…", target: nil, action: nil)
    private let descLabel = NSTextField(wrappingLabelWithString: "")
    private let helperLabel = NSTextField(wrappingLabelWithString: "")
    private var selectedPath = "~/Documents/vibeliner"

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupView() {
        descLabel.stringValue = "Choose where Vibeliner saves screenshots and prompts."
        descLabel.font = NSFont.systemFont(ofSize: 12)
        descLabel.textColor = NSColor(white: 0.3, alpha: 1)
        descLabel.isEditable = false
        descLabel.isBordered = false
        descLabel.drawsBackground = false
        addSubview(descLabel)

        pathLabel.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        pathLabel.textColor = NSColor(white: 0.3, alpha: 1)
        pathLabel.wantsLayer = true
        pathLabel.layer?.backgroundColor = NSColor(white: 0.96, alpha: 1).cgColor
        pathLabel.layer?.cornerRadius = 4
        pathLabel.layer?.borderWidth = 0.5
        pathLabel.layer?.borderColor = NSColor(white: 0.85, alpha: 1).cgColor
        pathLabel.alignment = .center
        addSubview(pathLabel)

        createButton.bezelStyle = .rounded
        createButton.target = self
        createButton.action = #selector(createFolder)
        addSubview(createButton)

        chooseButton.bezelStyle = .rounded
        chooseButton.target = self
        chooseButton.action = #selector(chooseFolder)
        addSubview(chooseButton)

        helperLabel.stringValue = "Each capture gets its own subfolder with the annotated screenshot and prompt."
        helperLabel.font = NSFont.systemFont(ofSize: 11)
        helperLabel.textColor = NSColor(white: 0.5, alpha: 1)
        helperLabel.isEditable = false
        helperLabel.isBordered = false
        helperLabel.drawsBackground = false
        addSubview(helperLabel)
    }

    override func layout() {
        super.layout()
        let w = bounds.width
        descLabel.frame = NSRect(x: 0, y: bounds.height - 40, width: w, height: 32)
        pathLabel.frame = NSRect(x: 0, y: bounds.height - 68, width: w, height: 22)
        createButton.frame = NSRect(x: 4, y: bounds.height - 100, width: (w - 12) / 2, height: 28)
        chooseButton.frame = NSRect(x: w / 2 + 2, y: bounds.height - 100, width: (w - 12) / 2, height: 28)
        helperLabel.frame = NSRect(x: 0, y: 0, width: w, height: 36)
    }

    @objc private func createFolder() {
        ConfigManager.shared.capturesFolder = selectedPath
        ConfigManager.shared.save()
        CapturesManager.shared.ensureBaseFolder()
        markComplete()
    }

    @objc private func chooseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.directoryURL = URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Documents")
        panel.begin { [weak self] response in
            guard response == .OK, let url = panel.url else { return }
            self?.selectedPath = url.path
            self?.pathLabel.stringValue = url.path
        }
    }

    private func markComplete() {
        createButton.isHidden = true
        chooseButton.isHidden = true
        let expandedPath = (selectedPath as NSString).expandingTildeInPath
        helperLabel.stringValue = "\(expandedPath) is ready to receive captures."
        setupController?.completeStep2()
    }
}
