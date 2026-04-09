import AppKit

/// Configuration for the wireframe app mock
struct WireframeConfig {
    var showErrorCard: Bool = true
    var showErrorRow: Bool = true
}

/// Reusable wireframe app mock that appears in tour steps 0-4.
/// Draws a simplified app UI with a top bar, sidebar, card grid, and table.
final class WireframeAppMock: NSView {

    private let config: WireframeConfig

    init(config: WireframeConfig = WireframeConfig()) {
        self.config = config
        super.init(frame: .zero)
        wantsLayer = true
        layer?.cornerRadius = 8
        layer?.masksToBounds = true
        layer?.backgroundColor = NSColor(white: 0.96, alpha: 1).cgColor
    }

    required init?(coder: NSCoder) { fatalError() }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        let w = bounds.width
        let h = bounds.height

        // Top bar (36px)
        let topBarH: CGFloat = min(36, h * 0.08)
        ctx.setFillColor(NSColor(white: 0.93, alpha: 1).cgColor)
        ctx.fill(CGRect(x: 0, y: h - topBarH, width: w, height: topBarH))

        // Brand icon (purple gradient square)
        let iconSize: CGFloat = 16
        let iconX: CGFloat = 12
        let iconY = h - topBarH + (topBarH - iconSize) / 2
        let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                  colors: [DesignTokens.purpleDark.cgColor, DesignTokens.purpleLight.cgColor] as CFArray,
                                  locations: [0, 1])!
        ctx.saveGState()
        let iconRect = CGRect(x: iconX, y: iconY, width: iconSize, height: iconSize)
        let iconPath = CGPath(roundedRect: iconRect, cornerWidth: 4, cornerHeight: 4, transform: nil)
        ctx.addPath(iconPath)
        ctx.clip()
        ctx.drawLinearGradient(gradient, start: iconRect.origin,
                               end: CGPoint(x: iconRect.maxX, y: iconRect.maxY), options: [])
        ctx.restoreGState()

        // "Dashflow" label
        let dashflowStr = NSAttributedString(string: "Dashflow", attributes: [
            .font: NSFont.systemFont(ofSize: 11, weight: .bold),
            .foregroundColor: NSColor(white: 0.25, alpha: 1),
        ])
        dashflowStr.draw(at: NSPoint(x: iconX + iconSize + 6, y: iconY + 1))

        // Nav pills in top bar
        let navPillY = h - topBarH + (topBarH - 12) / 2
        for i in 0..<2 {
            let px = w - 60 + CGFloat(i) * 30
            ctx.setFillColor(NSColor(white: 0.85, alpha: 1).cgColor)
            let pillRect = CGRect(x: px, y: navPillY, width: 24, height: 12)
            ctx.fill(pillRect)
        }

        // Divider below top bar
        ctx.setFillColor(NSColor(white: 0.88, alpha: 1).cgColor)
        ctx.fill(CGRect(x: 0, y: h - topBarH - 1, width: w, height: 1))

        // Sidebar (left, 100px or ~22% of width)
        let sideW: CGFloat = min(100, w * 0.22)
        let bodyTop = h - topBarH - 1
        ctx.setFillColor(NSColor(white: 0.94, alpha: 1).cgColor)
        ctx.fill(CGRect(x: 0, y: 0, width: sideW, height: bodyTop))

        // Sidebar nav items (3 pills)
        let navItemH: CGFloat = 14
        let navItemW: CGFloat = sideW - 24
        for i in 0..<3 {
            let ny = bodyTop - 20 - CGFloat(i) * (navItemH + 6)
            if i == 0 {
                // Active item — purple tinted
                ctx.setFillColor(NSColor(red: 175/255, green: 169/255, blue: 236/255, alpha: 0.25).cgColor)
                let path = CGPath(roundedRect: CGRect(x: 12, y: ny, width: navItemW, height: navItemH),
                                  cornerWidth: 4, cornerHeight: 4, transform: nil)
                ctx.addPath(path)
                ctx.fillPath()
            } else {
                ctx.setFillColor(NSColor(white: 0.88, alpha: 1).cgColor)
                let path = CGPath(roundedRect: CGRect(x: 12, y: ny, width: navItemW, height: navItemH),
                                  cornerWidth: 4, cornerHeight: 4, transform: nil)
                ctx.addPath(path)
                ctx.fillPath()
            }
        }

        // Sidebar divider
        ctx.setFillColor(NSColor(white: 0.88, alpha: 1).cgColor)
        ctx.fill(CGRect(x: sideW, y: 0, width: 1, height: bodyTop))

        // Main content area
        let mainX = sideW + 1
        let mainW = w - mainX
        let mainPad: CGFloat = 14
        let contentX = mainX + mainPad
        let contentW = mainW - mainPad * 2

        // Heading placeholder
        let headingY = bodyTop - 24
        let headingW = min(120, contentW * 0.4)
        ctx.setFillColor(NSColor(red: 175/255, green: 169/255, blue: 236/255, alpha: 0.15).cgColor)
        let headingPath = CGPath(roundedRect: CGRect(x: contentX, y: headingY, width: headingW, height: 14),
                                  cornerWidth: 4, cornerHeight: 4, transform: nil)
        ctx.addPath(headingPath)
        ctx.fillPath()

        // Card grid: 3 cards in a row
        let cardTop = headingY - 14
        let cardGap: CGFloat = 8
        let cardH: CGFloat = min(64, (bodyTop - 80) * 0.35)
        let cardW = (contentW - cardGap * 2) / 3

        for i in 0..<3 {
            let cx = contentX + CGFloat(i) * (cardW + cardGap)
            let cardRect = CGRect(x: cx, y: cardTop - cardH, width: cardW, height: cardH)

            if i == 0 && config.showErrorCard {
                // Error card: red border + pink bg
                ctx.setFillColor(NSColor(red: 1, green: 0.92, blue: 0.92, alpha: 1).cgColor)
                let path = CGPath(roundedRect: cardRect, cornerWidth: 6, cornerHeight: 6, transform: nil)
                ctx.addPath(path)
                ctx.fillPath()
                ctx.setStrokeColor(NSColor(red: 239/255, green: 68/255, blue: 68/255, alpha: 0.4).cgColor)
                ctx.setLineWidth(1.5)
                ctx.addPath(path)
                ctx.strokePath()
            } else {
                // Normal card
                ctx.setFillColor(NSColor.white.cgColor)
                let path = CGPath(roundedRect: cardRect, cornerWidth: 6, cornerHeight: 6, transform: nil)
                ctx.addPath(path)
                ctx.fillPath()
                // Gray content lines
                for j in 0..<2 {
                    let ly = cardRect.maxY - 14 - CGFloat(j) * 12
                    let lw = j == 0 ? cardW * 0.7 : cardW * 0.5
                    ctx.setFillColor(NSColor(white: 0.85, alpha: 1).cgColor)
                    ctx.fill(CGRect(x: cx + 8, y: ly, width: lw, height: 6))
                }
            }
        }

        // Table
        let tableTop = cardTop - cardH - 14
        let tableH = min(tableTop - 10, max(50, bodyTop * 0.25))
        let tableRect = CGRect(x: contentX, y: tableTop - tableH, width: contentW, height: tableH)
        let tablePath = CGPath(roundedRect: tableRect, cornerWidth: 6, cornerHeight: 6, transform: nil)
        ctx.setFillColor(NSColor.white.cgColor)
        ctx.addPath(tablePath)
        ctx.fillPath()

        // Table header row
        let headerH: CGFloat = min(18, tableH * 0.35)
        ctx.setFillColor(NSColor(white: 0.93, alpha: 1).cgColor)
        ctx.fill(CGRect(x: tableRect.minX, y: tableRect.maxY - headerH, width: contentW, height: headerH))

        // Table data rows
        let rowH = (tableH - headerH) / 2
        for i in 0..<2 {
            let ry = tableRect.maxY - headerH - CGFloat(i + 1) * rowH

            if i == 0 && config.showErrorRow {
                // Error row: pink bg
                ctx.setFillColor(NSColor(red: 1, green: 0.94, blue: 0.94, alpha: 1).cgColor)
                ctx.fill(CGRect(x: tableRect.minX, y: ry, width: contentW, height: rowH))
            }

            // Row divider
            ctx.setFillColor(NSColor(white: 0.90, alpha: 1).cgColor)
            ctx.fill(CGRect(x: tableRect.minX + 8, y: ry, width: contentW - 16, height: 0.5))
        }
    }
}
