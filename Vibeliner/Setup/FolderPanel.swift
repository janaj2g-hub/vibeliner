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
        descLabel.font = NSFont.systemFont(ofSize: 13)
        descLabel.textColor = NSColor(white: 0.33, alpha: 1)
        descLabel.isEditable = false
        descLabel.isBordered = false
        descLabel.drawsBackground = false
        addSubview(descLabel)

        pathLabel.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        pathLabel.textColor = NSColor(white: 0.33, alpha: 1)
        pathLabel.wantsLayer = true
        pathLabel.layer?.backgroundColor = NSColor(white: 0.96, alpha: 1).cgColor
        pathLabel.layer?.cornerRadius = 6
        pathLabel.layer?.borderWidth = 1
        pathLabel.layer?.borderColor = NSColor(white: 0.88, alpha: 1).cgColor
        pathLabel.alignment = .center
        addSubview(pathLabel)

        // Create folder button — dark style
        createButton.bezelStyle = .rounded
        createButton.wantsLayer = true
        createButton.isBordered = false
        createButton.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        createButton.contentTintColor = .white
        createButton.layer?.backgroundColor = NSColor(white: 0.2, alpha: 1).cgColor
        createButton.layer?.cornerRadius = 6
        createButton.target = self
        createButton.action = #selector(createFolder)
        addSubview(createButton)

        // Choose different button — secondary style
        chooseButton.bezelStyle = .rounded
        chooseButton.wantsLayer = true
        chooseButton.isBordered = false
        chooseButton.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        chooseButton.contentTintColor = NSColor(white: 0.33, alpha: 1)
        chooseButton.layer?.backgroundColor = NSColor.white.cgColor
        chooseButton.layer?.borderWidth = 1
        chooseButton.layer?.borderColor = NSColor(white: 0.8, alpha: 1).cgColor
        chooseButton.layer?.cornerRadius = 6
        chooseButton.target = self
        chooseButton.action = #selector(chooseFolder)
        addSubview(chooseButton)

        helperLabel.stringValue = "Each capture gets its own subfolder with the annotated screenshot and prompt."
        helperLabel.font = NSFont.systemFont(ofSize: 12)
        helperLabel.textColor = NSColor(white: 0.53, alpha: 1)
        helperLabel.isEditable = false
        helperLabel.isBordered = false
        helperLabel.drawsBackground = false
        addSubview(helperLabel)
    }

    override func layout() {
        super.layout()
        let w = bounds.width
        descLabel.frame = NSRect(x: 0, y: bounds.height - 40, width: w, height: 32)
        pathLabel.frame = NSRect(x: 0, y: bounds.height - 70, width: w, height: 24)
        createButton.frame = NSRect(x: 0, y: bounds.height - 104, width: w, height: 28)
        chooseButton.frame = NSRect(x: 0, y: bounds.height - 136, width: w, height: 28)
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
        helperLabel.stringValue = "\((selectedPath as NSString).expandingTildeInPath) is ready."
        setupController?.completeStep2()
    }
}
