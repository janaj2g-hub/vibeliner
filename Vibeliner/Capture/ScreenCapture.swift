import AppKit
import CoreGraphics

final class ScreenCapture {

    @available(macOS, deprecated: 14.0, message: "Using CGWindowListCreateImage per project requirements")
    static func captureRegion(rect: NSRect, on screen: NSScreen) -> NSImage? {
        // Check screen recording permission
        if !CGPreflightScreenCaptureAccess() {
            CGRequestScreenCaptureAccess()
            print("Vibeliner: Screen recording permission required.")
            return nil
        }

        // VIB-179: Convert to global display coordinates for multi-monitor
        // CGWindowListCreateImage uses global display space (top-left origin)
        let screenFrame = screen.frame
        let mainScreenH = NSScreen.screens.first?.frame.height ?? screenFrame.height

        // Convert from screen-local bottom-left to global top-left
        let globalX = screenFrame.origin.x + rect.origin.x
        let globalY = mainScreenH - (screenFrame.origin.y + rect.origin.y + rect.height)

        let cgRect = CGRect(x: globalX, y: globalY, width: rect.width, height: rect.height)

        // Capture using CGWindowListCreateImage
        guard let cgImage = CGWindowListCreateImage(
            cgRect,
            .optionOnScreenBelowWindow,
            kCGNullWindowID,
            [.bestResolution]
        ) else {
            print("Vibeliner: CGWindowListCreateImage failed, attempting fallback")
            return captureWithFallback(rect: rect)
        }

        // VIB-179: Set image display size to POINT dimensions (not pixel)
        // CGWindowListCreateImage with .bestResolution returns 2x pixels on Retina
        let image = NSImage(cgImage: cgImage, size: NSSize(width: rect.width, height: rect.height))
        return image
    }

    private static func captureWithFallback(rect: NSRect) -> NSImage? {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("vibeliner_capture_\(ProcessInfo.processInfo.globallyUniqueString).png")

        let x = Int(rect.origin.x)
        let y = Int(rect.origin.y)
        let w = Int(rect.width)
        let h = Int(rect.height)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
        process.arguments = ["-R", "\(x),\(y),\(w),\(h)", "-t", "png", tempURL.path]

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            print("Vibeliner: screencapture fallback failed: \(error)")
            return nil
        }

        guard process.terminationStatus == 0,
              let image = NSImage(contentsOf: tempURL) else {
            return nil
        }

        try? FileManager.default.removeItem(at: tempURL)
        return image
    }
}

extension NSImage {
    func savePNG(to url: URL) -> Bool {
        guard let tiffData = tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData),
              let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
            return false
        }

        do {
            try pngData.write(to: url)
            return true
        } catch {
            print("Vibeliner: Failed to save PNG: \(error)")
            return false
        }
    }
}
