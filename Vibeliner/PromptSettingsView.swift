import AppKit
import SwiftUI

struct PromptSettingsView: View {
    @State private var preambleSingle: String
    @State private var preambleBatch: String

    private let defaults = VibelinerConfig()
    private let onClose: () -> Void

    init(onClose: @escaping () -> Void) {
        let config = Config.shared
        _preambleSingle = State(initialValue: config.preambleSingle)
        _preambleBatch = State(initialValue: config.preambleBatch)
        self.onClose = onClose
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            tokenGuidance
            preambleSection(
                title: "Single capture preamble",
                helper: "Use \(PromptBuilder.screenshotPathToken) to place the screenshot path yourself. If you omit it, Vibeliner appends a separate screenshot line automatically.",
                text: $preambleSingle,
                resetAction: { preambleSingle = defaults.preambleSingle }
            )
            preambleSection(
                title: "Batch preamble",
                helper: "Reserved for multi-capture exports. The same screenshot-path token rules apply when this template is used.",
                text: $preambleBatch,
                resetAction: { preambleBatch = defaults.preambleBatch }
            )
            HStack {
                Spacer()
                Button("Save") {
                    Config.shared.preambleSingle = preambleSingle
                    Config.shared.preambleBatch = preambleBatch
                    Config.shared.save()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(16)
        .frame(width: 540)
        .background(Color(nsColor: NSColor(calibratedWhite: 0.13, alpha: 1.0)))
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Prompt settings")
                .font(.system(size: 14, weight: .bold))
            Spacer()
            Button("Done") {
                onClose()
            }
            .buttonStyle(.plain)
            .foregroundStyle(.blue)
        }
    }

    private var tokenGuidance: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Screenshot path token")
                .font(.system(size: 12, weight: .bold))

            Text(PromptBuilder.screenshotPathToken)
                .font(.system(size: 11, design: .monospaced))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(nsColor: NSColor(calibratedWhite: 0.2, alpha: 1.0)))
                )

            Text("Saved prompt.md files keep a relative screenshot path (\(PromptBuilder.savedScreenshotReference)). Copy for LLM resolves that path to an absolute screenshot path so pasting works from any Claude Code or Cursor working directory.")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func preambleSection(
        title: String,
        helper: String,
        text: Binding<String>,
        resetAction: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.system(size: 12, weight: .bold))
                Spacer()
                Button("Insert token") {
                    insertToken(into: text)
                }
                .buttonStyle(.plain)
                .font(.system(size: 11))
                .foregroundStyle(.blue)
                Button("Reset") {
                    resetAction()
                }
                .buttonStyle(.plain)
                .font(.system(size: 11))
                .foregroundStyle(.blue)
            }

            TextEditor(text: text)
                .font(.system(size: 11, design: .monospaced))
                .scrollContentBackground(.hidden)
                .foregroundStyle(.white)
                .frame(minHeight: 90)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(nsColor: NSColor(calibratedWhite: 0.18, alpha: 1.0)))
                )

            Text(helper)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func insertToken(into text: Binding<String>) {
        if text.wrappedValue.contains(PromptBuilder.screenshotPathToken) {
            return
        }

        if text.wrappedValue.isEmpty {
            text.wrappedValue = PromptBuilder.screenshotPathToken
        } else {
            text.wrappedValue += " \(PromptBuilder.screenshotPathToken)"
        }
    }
}

enum PromptSettingsPanelPresenter {
    private final class CloseObserver: NSObject, NSWindowDelegate {
        let onClose: () -> Void

        init(onClose: @escaping () -> Void) {
            self.onClose = onClose
        }

        func windowWillClose(_ notification: Notification) {
            onClose()
        }
    }

    private static var controller: NSWindowController?
    private static var closeObserver: CloseObserver?

    static func show(onClose: @escaping () -> Void) {
        Config.shared.reload()
        controller?.close()

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 540, height: 430),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.title = "Prompt settings"
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.appearance = NSAppearance(named: .darkAqua)
        panel.center()

        let closeObserver = CloseObserver {
            Self.controller = nil
            Self.closeObserver = nil
            onClose()
        }

        let controller = NSWindowController(window: panel)
        panel.delegate = closeObserver
        panel.contentView = NSHostingView(
            rootView: PromptSettingsView {
                controller.close()
            }
        )

        Self.closeObserver = closeObserver
        Self.controller = controller
        controller.showWindow(nil)
    }
}
