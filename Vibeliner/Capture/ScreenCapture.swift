import AppKit
import CoreGraphics

final class ScreenCapture {

    @available(macOS, deprecated: 14.0, message: "Using CGWindowListCreateImage per project requirements")
    static func captureRegion(rect: NSRect, on screen: NSScreen) -> NSImage? {
        // Check screen recording permission
        if !CGPreflightScreenCaptureAccess() {
            CGRequestScreenCaptureAccess()
            #if DEBUG
            print("Vibeliner: Screen recording permission required.")
            #endif
            return nil
        }

        // `rect` is already in GLOBAL screen coordinates (bottom-left origin, from
        // CaptureCoordinator's window.convertToScreen). We only need to flip Y to
        // CGWindowListCreateImage's top-left origin. Do NOT multiply by backingScaleFactor
        // — CGWindowListCreateImage takes point coordinates, not pixels.
        let mainScreenH = NSScreen.screens.first?.frame.height ?? screen.frame.height
        let flippedY = mainScreenH - rect.origin.y - rect.height

        let cgRect = CGRect(
            x: rect.origin.x,
            y: flippedY,
            width: rect.width,
            height: rect.height
        )

        // Capture using CGWindowListCreateImage
        guard let cgImage = CGWindowListCreateImage(
            cgRect,
            .optionOnScreenBelowWindow,
            kCGNullWindowID,
            [.bestResolution]
        ) else {
            #if DEBUG
            print("Vibeliner: CGWindowListCreateImage failed")
            #endif
            return nil
        }

        // Set image display size to POINT dimensions (not pixel dimensions).
        // CGWindowListCreateImage with .bestResolution returns 2x pixels on Retina,
        // but NSImage should display at point size.
        let image = NSImage(cgImage: cgImage, size: NSSize(width: rect.width, height: rect.height))
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
            #if DEBUG
            print("Vibeliner: Failed to save PNG: \(error)")
            #endif
            return false
        }
    }
}
