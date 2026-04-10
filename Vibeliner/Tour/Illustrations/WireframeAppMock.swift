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
        let topBarH = DesignTokens.tourWireframeTopbarHeight
        ctx.setFillColor(DesignTokens.tourWireframeTopbarBg.cgColor)
        ctx.fill(CGRect(x: 0, y: h - topBarH, width: w, height: topBarH))

        // Brand icon (purple gradient square)
        let iconSize = DesignTokens.tourWireframeBrandIconSize
        let iconX: CGFloat = 12
        let iconY = h - topBarH + (topBarH - iconSize) / 2
        if let brandGradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                          colors: [DesignTokens.purpleDark.cgColor, DesignTokens.purpleLight.cgColor] as CFArray,
                                          locations: [0, 1]) {
            ctx.saveGState()
            let iconRect = CGRect(x: iconX, y: iconY, width: iconSize, height: iconSize)
            let iconPath = CGPath(roundedRect: iconRect, cornerWidth: 4, cornerHeight: 4, transform: nil)
            ctx.addPath(iconPath)
            ctx.clip()
            ctx.drawLinearGradient(brandGradient, start: iconRect.origin,
                                   end: CGPoint(x: iconRect.maxX, y: iconRect.maxY), options: [])
            ctx.restoreGState()
        }

        // "Dashflow" label
        let dashflowStr = NSAttributedString(string: "Dashflow", attributes: [
            .font: DesignTokens.tourWireframeBrandFont,
            .foregroundColor: DesignTokens.tourWireframeBrandColor,
        ])
        dashflowStr.draw(at: NSPoint(x: iconX + iconSize + 8, y: iconY + 1))

        // Nav pills (3 pills, right-aligned, pill-shaped)
        let navPillH = DesignTokens.tourWireframeNavPillHeight
        let navPillY = h - topBarH + (topBarH - navPillH) / 2
        let pillWidths: [CGFloat] = [60, 44, 28]
        let pillGap: CGFloat = 6
        let totalPillW = pillWidths.reduce(0, +) + pillGap * CGFloat(pillWidths.count - 1)
        var pillX = w - 12 - totalPillW
        ctx.setFillColor(DesignTokens.tourWireframeSidebarItem.cgColor)
        for pw in pillWidths {
            let pillR = navPillH / 2
            let pp = CGPath(roundedRect: CGRect(x: pillX, y: navPillY, width: pw, height: navPillH),
                            cornerWidth: pillR, cornerHeight: pillR, transform: nil)
            ctx.addPath(pp)
            ctx.fillPath()
            pillX += pw + pillGap
        }

        // Divider below top bar
        ctx.setFillColor(DesignTokens.tourWireframeTopbarBorder.cgColor)
        ctx.fill(CGRect(x: 0, y: h - topBarH - 1, width: w, height: 1))

        // Sidebar
        let sideW = DesignTokens.tourWireframeSidebarWidth
        let bodyTop = h - topBarH - 1
        ctx.setFillColor(DesignTokens.tourWireframeSidebarBg.cgColor)
        ctx.fill(CGRect(x: 0, y: 0, width: sideW, height: bodyTop))

        // Sidebar nav items (3 pills, 10px h-padding, 14px top-padding, 8px gap)
        let navItemH: CGFloat = 14
        let navItemW = sideW - 20
        let sidebarPadV: CGFloat = 14
        let sidebarGap: CGFloat = 8
        for i in 0..<3 {
            let ny = bodyTop - sidebarPadV - CGFloat(i + 1) * navItemH - CGFloat(i) * sidebarGap
            let fc = (i == 0) ? DesignTokens.tourWireframeSidebarActive : DesignTokens.tourWireframeSidebarItem
            ctx.setFillColor(fc.cgColor)
            let sp = CGPath(roundedRect: CGRect(x: 10, y: ny, width: navItemW, height: navItemH),
                            cornerWidth: navItemH / 2, cornerHeight: navItemH / 2, transform: nil)
            ctx.addPath(sp)
            ctx.fillPath()
        }

        // Sidebar divider
        ctx.setFillColor(DesignTokens.tourWireframeSidebarBorder.cgColor)
        ctx.fill(CGRect(x: sideW, y: 0, width: 1, height: bodyTop))

        // Main content area (16px padding, 12px gap)
        let mainX = sideW + 1
        let mainPad: CGFloat = 16
        let contentX = mainX + mainPad
        let contentW = w - mainX - mainPad * 2
        let mainGap: CGFloat = 12

        // Heading pill
        let headingH: CGFloat = 14
        let headingY = bodyTop - mainPad - headingH
        let headingW = min(CGFloat(120), contentW * 0.5)
        ctx.setFillColor(DesignTokens.tourWireframeHeading.cgColor)
        let hp = CGPath(roundedRect: CGRect(x: contentX, y: headingY, width: headingW, height: headingH),
                        cornerWidth: headingH / 2, cornerHeight: headingH / 2, transform: nil)
        ctx.addPath(hp)
        ctx.fillPath()

        // Card grid: 3 cards in a row
        let cardTop = headingY - mainGap
        let cardGap: CGFloat = 8
        let cardH = DesignTokens.tourWireframeCardHeight
        let cardR = DesignTokens.tourWireframeCardRadius
        let cardW = (contentW - cardGap * 2) / 3
        let cardPad: CGFloat = 10
        let lineH: CGFloat = 7
        let lineGap: CGFloat = 6

        for i in 0..<3 {
            let cx = contentX + CGFloat(i) * (cardW + cardGap)
            let cardRect = CGRect(x: cx, y: cardTop - cardH, width: cardW, height: cardH)
            let cp = CGPath(roundedRect: cardRect, cornerWidth: cardR, cornerHeight: cardR, transform: nil)

            if i == 0 && config.showErrorCard {
                ctx.setFillColor(DesignTokens.tourWireframeCardErrorBg.cgColor)
                ctx.addPath(cp)
                ctx.fillPath()
                ctx.setStrokeColor(DesignTokens.tourWireframeCardErrorBorder.cgColor)
                ctx.setLineWidth(1)
                ctx.addPath(cp)
                ctx.strokePath()
            } else {
                ctx.setFillColor(DesignTokens.tourWireframeCardBg.cgColor)
                ctx.addPath(cp)
                ctx.fillPath()
                ctx.setStrokeColor(DesignTokens.tourWireframeCardBorder.cgColor)
                ctx.setLineWidth(1)
                ctx.addPath(cp)
                ctx.strokePath()
            }

            // Content lines in all cards (full-width + 60% short)
            ctx.setFillColor(DesignTokens.tourWireframeLine.cgColor)
            let lw = cardW - cardPad * 2
            let ly1 = cardRect.maxY - cardPad - lineH
            let l1 = CGPath(roundedRect: CGRect(x: cx + cardPad, y: ly1, width: lw, height: lineH),
                            cornerWidth: lineH / 2, cornerHeight: lineH / 2, transform: nil)
            ctx.addPath(l1)
            ctx.fillPath()

            let ly2 = ly1 - lineGap - lineH
            let l2 = CGPath(roundedRect: CGRect(x: cx + cardPad, y: ly2, width: lw * 0.6, height: lineH),
                            cornerWidth: lineH / 2, cornerHeight: lineH / 2, transform: nil)
            ctx.addPath(l2)
            ctx.fillPath()
        }

        // Table (4-column cells, header + 2 data rows)
        let tableTop = cardTop - cardH - mainGap
        let rowPadV: CGFloat = 8
        let rowPadH: CGFloat = 10
        let cellH: CGFloat = 7
        let cellGap: CGFloat = 8
        let rowH = rowPadV * 2 + cellH
        let tableH = rowH * 3
        let tableR = DesignTokens.tourWireframeTableRadius
        let tableRect = CGRect(x: contentX, y: tableTop - tableH, width: contentW, height: tableH)
        let tp = CGPath(roundedRect: tableRect, cornerWidth: tableR, cornerHeight: tableR, transform: nil)

        // Clip to table rounded rect
        ctx.saveGState()
        ctx.addPath(tp)
        ctx.clip()

        ctx.setFillColor(DesignTokens.tourWireframeTableBg.cgColor)
        ctx.fill(tableRect)

        // Header row
        let headerRowY = tableRect.maxY - rowH
        ctx.setFillColor(DesignTokens.tourWireframeTableHeadBg.cgColor)
        ctx.fill(CGRect(x: tableRect.minX, y: headerRowY, width: contentW, height: rowH))
        drawTableCells(ctx, x: tableRect.minX + rowPadH, y: headerRowY + rowPadV,
                       width: contentW - rowPadH * 2, cellH: cellH, cellGap: cellGap)

        // Data rows
        for i in 0..<2 {
            let ry = headerRowY - CGFloat(i + 1) * rowH

            if i == 0 && config.showErrorRow {
                ctx.setFillColor(DesignTokens.tourWireframeTableErrorBg.cgColor)
                ctx.fill(CGRect(x: tableRect.minX, y: ry, width: contentW, height: rowH))
            }

            // Row divider
            ctx.setFillColor(DesignTokens.tourWireframeTableRowBorder.cgColor)
            ctx.fill(CGRect(x: tableRect.minX, y: ry + rowH, width: contentW, height: 0.5))

            drawTableCells(ctx, x: tableRect.minX + rowPadH, y: ry + rowPadV,
                           width: contentW - rowPadH * 2, cellH: cellH, cellGap: cellGap)
        }

        ctx.restoreGState()

        // Table border
        ctx.setStrokeColor(DesignTokens.tourWireframeTableBorder.cgColor)
        ctx.setLineWidth(1)
        ctx.addPath(tp)
        ctx.strokePath()
    }

    private func drawTableCells(_ ctx: CGContext, x: CGFloat, y: CGFloat, width: CGFloat, cellH: CGFloat, cellGap: CGFloat) {
        let count = 4
        let cellW = (width - cellGap * CGFloat(count - 1)) / CGFloat(count)
        ctx.setFillColor(DesignTokens.tourWireframeTableCell.cgColor)
        for i in 0..<count {
            let cx = x + CGFloat(i) * (cellW + cellGap)
            let cp = CGPath(roundedRect: CGRect(x: cx, y: y, width: cellW, height: cellH),
                            cornerWidth: cellH / 2, cornerHeight: cellH / 2, transform: nil)
            ctx.addPath(cp)
            ctx.fillPath()
        }
    }
}
