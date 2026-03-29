import AppKit
import ArgumentParser
import Foundation

// Initialize NSApplication for clipboard access
private let _appInit: Void = { let _ = NSApplication.shared }()

@main
struct VibeLinerCLI: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "vibeliner",
        abstract: "Vibeliner — capture, annotate, and package screenshots for AI tools.",
        subcommands: [List.self, Copy.self, Send.self, Clean.self]
    )
}

// MARK: - List

extension VibeLinerCLI {
    struct List: ParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "list",
            abstract: "List all captures."
        )

        func run() throws {
            let records = CaptureStore.shared.list()

            guard !records.isEmpty else {
                print("No captures found.")
                return
            }

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

            // Header
            print(String(format: "%-4s %-8s %-22s %-12s %s", "#", "Status", "Date", "Annotations", "Slug"))
            print(String(repeating: "-", count: 60))

            for (i, record) in records.enumerated() {
                let status = record.sent ? "sent" : "unsent"
                let date = dateFormatter.string(from: record.created)
                print(String(format: "%-4d %-8s %-22s %-12d %s",
                    i + 1, status, date, record.count, record.slug))
            }
        }
    }
}

// MARK: - Copy

extension VibeLinerCLI {
    struct Copy: ParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "copy",
            abstract: "Copy a capture's prompt or image to clipboard."
        )

        @Argument(help: "1-based index from 'vibeliner list'")
        var index: Int

        @Flag(name: .long, help: "Copy the screenshot image instead of prompt text")
        var image: Bool = false

        func run() throws {
            let records = CaptureStore.shared.list()

            guard !records.isEmpty else {
                print("No captures found.")
                return
            }

            guard index >= 1 && index <= records.count else {
                print("Error: No capture at index \(index). Run 'vibeliner list' to see available captures.")
                return
            }

            let record = records[index - 1]

            if image {
                try copyImage(from: record)
            } else {
                try copyPrompt(from: record, index: index)
            }
        }

        private func copyPrompt(from record: CaptureRecord, index: Int) throws {
            let text = try CaptureStore.shared.clipboardPrompt(for: record)
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(text, forType: .string)
            print("Copied prompt for capture #\(index) to clipboard.")
        }

        private func copyImage(from record: CaptureRecord) throws {
            let imageURL = record.folderURL.appendingPathComponent("screenshot.png")
            guard let img = NSImage(contentsOf: imageURL) else {
                print("Error: Could not load screenshot.png for capture #\(index).")
                return
            }
            NSPasteboard.general.clearContents()
            NSPasteboard.general.writeObjects([img])
            print("Copied image for capture #\(index) to clipboard.")
        }
    }
}

// MARK: - Send

extension VibeLinerCLI {
    struct Send: ParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "send",
            abstract: "Copy prompt to clipboard and mark capture as sent."
        )

        @Argument(help: "1-based index from 'vibeliner list'")
        var index: Int

        func run() throws {
            let records = CaptureStore.shared.list()

            guard !records.isEmpty else {
                print("No captures found.")
                return
            }

            guard index >= 1 && index <= records.count else {
                print("Error: No capture at index \(index). Run 'vibeliner list' to see available captures.")
                return
            }

            let record = records[index - 1]
            let text = try CaptureStore.shared.clipboardPrompt(for: record)

            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(text, forType: .string)

            CaptureStore.shared.markSent(record)
            print("Copied and marked capture #\(index) as sent.")
        }
    }
}

// MARK: - Clean

extension VibeLinerCLI {
    struct Clean: ParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "clean",
            abstract: "Delete old capture folders."
        )

        @Flag(name: .long, help: "Delete ALL captures regardless of age")
        var all: Bool = false

        func run() throws {
            let records = CaptureStore.shared.list()

            guard !records.isEmpty else {
                print("No captures to clean.")
                return
            }

            let toDelete: [CaptureRecord]
            if all {
                toDelete = records
            } else {
                let retainDays = Config.shared.config.retainDays
                let cutoff = Calendar.current.date(byAdding: .day, value: -retainDays, to: Date()) ?? Date()
                toDelete = records.filter { $0.created < cutoff }
            }

            guard !toDelete.isEmpty else {
                print("No captures to clean.")
                return
            }

            for record in toDelete {
                CaptureStore.shared.delete(record: record)
            }

            print("Cleaned \(toDelete.count) capture\(toDelete.count == 1 ? "" : "s").")
        }
    }
}
