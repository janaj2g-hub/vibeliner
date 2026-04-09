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
        layer?.cornerRadius = DesignTokens.tourWireframeRadius
        layer?.masksToBounds = true
        layer?.backgroundColor = DesignTokens.tourWireframeBgTop.cgColor
    }

    required init?(coder: NSCoder) { fatalError() }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        let w = bounds.width
        let h = bounds.height

        // Background gradient
        if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                     colors: [DesignTokens.tourWireframeBgTop.cgColor, DesignTokens.tourWireframeBgBottom.cgColor] as CFArray,
                                     locations: [0, 1]) {
            ctx.drawLinearGradient(gradient, start: CGPoint(x: 0, y: h), end: CGPoint(x: 0, y: 0), options: [])
        }

        // Top bar
        let topBarH: CGFloat = min(DesignTokens.tourWireframeTopbarHeight, h * 0.08)
        ctx.setFillColor(DesignTokens.tourWireframeTopbarBg.cgColor)
        ctx.fill(CGRect(x: 0, y: h - topBarH, width: w, height: topBarH))

        // Brand icon (purple gradient square)
        let iconSize: CGFloat = DesignTokens.tourWireframeBrandIconSize
        let iconX: CGFloat = 12
        let iconY = h - topBarH + (topBarH - iconSize) / 2
        let brandGradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                  colors: [DesignTokens.purpleDark.cgColor, DesignTokens.purpleLight.cgColor] as CFArray,
                                  locations: [0, 1])!
        ctx.saveGState()
        let iconRect = CGRect(x: iconX, y: iconY, width: iconSize, height: iconSize)
        let iconPath = CGPath(roundedRect: iconRect, cornerWidth: 4, cornerHeight: 4, transform: nil)
        ctx.addPath(iconPath)
        ctx.clip()
        ctx.drawLinearGradient(brandGradient, start: iconRect.origin,
                               end: CGPoint(x: iconRect.maxX, y: iconRect.maxY), options: [])
        ctx.restoreGState()

        // "Dashflow" label
        let dashflowStr = NSAttributedString(string: "Dashflow", attributes: [
            .font: DesignTokens.tourWireframeBrandFont,
            .foregroundColor: DesignTokens.tourWireframeBrandColor,
        ])
        dashflowStr.draw(at: NSPoint(x: iconX + iconSize + 6, y: iconY + 1))

        // Nav pills in top bar
        let navPillY = h - topBarH + (topBarH - DesignTokens.tourWireframeNavPillHeight) / 2
        for i in 0..<2 {
            let px = w - 60 + CGFloat(i) * 30
            ctx.setFillColor(DesignTokens.tourWireframeSidebarItem.cgColor)
            let pillRect = CGRect(x: px, y: navPillY, width: 24, height: DesignTokens.tourWireframeNavPillHeight)
            ctx.fill(pillRect)
        }

        // Divider below top bar
        ctx.setFillColor(DesignTokens.tourWireframeTopbarBorder.cgColor)
        ctx.fill(CGRect(x: 0, y: h - topBarH - 1, width: w, height: 1))

        // Sidebar (left)
        let sideW: CGFloat = min(DesignTokens.tourWireframeSidebarWidth, w * 0.22)
        let bodyTop = h - topBarH - 1
        ctx.setFillColor(DesignTokens.tourWireframeSidebarBg.cgColor)
        ctx.fill(CGRect(x: 0, y: 0, width: sideW, height: bodyTop))

        // Sidebar nav items (3 pills)
        let navItemH: CGFloat = 14
        let navItemW: CGFloat = sideW - 24
        for i in 0..<3 {
            let ny = bodyTop - 20 - CGFloat(i) * (navItemH + 6)
            if i == 0 {
                // Active item — purple tinted
                ctx.setFillColor(DesignTokens.tourWireframeSidebarActive.cgColor)
                let path = CGPath(roundedRect: CGRect(x: 12, y: ny, width: navItemW, height: navItemH),
                                  cornerWidth: 4, cornerHeight: 4, transform: nil)
                ctx.addPath(path)
                ctx.fillPath()
            } else {
                ctx.setFillColor(DesignTokens.tourWireframeSidebarItem.cgColor)
                let path = CGPath(roundedRect: CGRect(x: 12, y: ny, width: navItemW, height: navItemH),
                                  cornerWidth: 4, cornerHeight: 4, transform: nil)
                ctx.addPath(path)
                ctx.fillPath()
            }
        }

        // Sidebar divider
        ctx.setFillColor(DesignTokens.tourWireframeSidebarBorder.cgColor)
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
        ctx.setFillColor(DesignTokens.tourWireframeHeading.cgColor)
        let headingPath = CGPath(roundedRect: CGRect(x: contentX, y: headingY, width: headingW, height: 14),
                                  cornerWidth: 4, cornerHeight: 4, transform: nil)
        ctx.addPath(headingPath)
        ctx.fillPath()

        // Card grid: 3 cards in a row
        let cardTop = headingY - 14
        let cardGap: CGFloat = 8
        let cardH: CGFloat = min(DesignTokens.tourWireframeCardHeight, (bodyTop - 80) * 0.35)
        let cardW = (contentW - cardGap * 2) / 3

        for i in 0..<3 {
            let cx = contentX + CGFloat(i) * (cardW + cardGap)
            let cardRect = CGRect(x: cx, y: cardTop - cardH, width: cardW, height: cardH)

            if i == 0 && config.showErrorCard {
                // Error card: red border + pink bg
                ctx.setFillColor(DesignTokens.tourWireframeCardErrorBg.cgColor)
                let path = CGPath(roundedRect: cardRect, cornerWidth: DesignTokens.tourWireframeCardRadius, cornerHeight: DesignTokens.tourWireframeCardRadius, transform: nil)
                ctx.addPath(path)
                ctx.fillPath()
                ctx.setStrokeColor(DesignTokens.tourWireframeCardErrorBorder.cgColor)
                ctx.setLineWidth(1.5)
                ctx.addPath(path)
                ctx.strokePath()
            } else {
                // Normal card
                ctx.setFillColor(DesignTokens.tourWireframeCardBg.cgColor)
                let path = CGPath(roundedRect: cardRect, cornerWidth: DesignTokens.tourWireframeCardRadius, cornerHeight: DesignTokens.tourWireframeCardRadius, transform: nil)
                ctx.addPath(path)
                ctx.fillPath()
                // Gray content lines
                for j in 0..<2 {
                    let ly = cardRect.maxY - 14 - CGFloat(j) * 12
                    let lw = j == 0 ? cardW * 0.7 : cardW * 0.5
                    ctx.setFillColor(DesignTokens.tourWireframeLine.cgColor)
                    ctx.fill(CGRect(x: cx + 8, y: ly, width: lw, height: 6))
                }
            }
        }

        // Table
        let tableTop = cardTop - cardH - 14
        let tableH = min(tableTop - 10, max(50, bodyTop * 0.25))
        let tableRect = CGRect(x: contentX, y: tableTop - tableH, width: contentW, height: tableH)
        let tablePath = CGPath(roundedRect: tableRect, cornerWidth: DesignTokens.tourWireframeTableRadius, cornerHeight: DesignTokens.tourWireframeTableRadius, transform: nil)
        ctx.setFillColor(DesignTokens.tourWireframeTableBg.cgColor)
        ctx.addPath(tablePath)
        ctx.fillPath()

        // Table header row
        let headerH: CGFloat = min(18, tableH * 0.35)
        ctx.setFillColor(DesignTokens.tourWireframeTableHeadBg.cgColor)
        ctx.fill(CGRect(x: tableRect.minX, y: tableRect.maxY - headerH, width: contentW, height: headerH))

        // Table data rows
        let rowH = (tableH - headerH) / 2
        for i in 0..<2 {
            let ry = tableRect.maxY - headerH - CGFloat(i + 1) * rowH

            if i == 0 && config.showErrorRow {
                // Error row: pink bg
                ctx.setFillColor(DesignTokens.tourWireframeTableErrorBg.cgColor)
                ctx.fill(CGRect(x: tableRect.minX, y: ry, width: contentW, height: rowH))
            }

            // Row divider
            ctx.setFillColor(DesignTokens.tourWireframeTableRowBorder.cgColor)
            ctx.fill(CGRect(x: tableRect.minX + 8, y: ry, width: contentW - 16, height: 0.5))
        }
    }
}
