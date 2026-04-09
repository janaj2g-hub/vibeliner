# Tour Illustration API — Guide for 229B

This document describes everything needed to build real illustration views for the tour window (VIB-229B). The TourWindowController (229A) currently shows placeholder labels; this spec explains how to replace them.

---

## Illustration Pane Container

The illustration pane is an `NSView` stored as `illustrationPane` (private) in `TourWindowController`. Its size is determined by Auto Layout:

- **Width:** 60% of the body area (`bodyView.widthAnchor * 0.6`) for steps 0–7. Full width for step 8 (see below).
- **Height:** Fills the space between the header (44px) and footer (48px), so approximately `700 - 44 - 48 = 608px`.
- **Background:** Inherits from the window background (`tourWindowBg` — rgba(30,30,30,0.92)).

The illustration pane has no padding or insets — subviews fill the entire rect. If you want internal padding, add it within your illustration view.

---

## How Illustration Views Are Swapped

`TourWindowController.renderStep(_ index:)` calls `updateIllustration(for:step:)`, which:

1. Removes all existing subviews from `illustrationPane` (`illustrationPane.subviews.forEach { $0.removeFromSuperview() }`)
2. For steps 0–7 (non-fullWidth): calls `buildPlaceholder(for:in:)` — **replace this with your illustration builder**
3. For step 8 (fullWidth / "You're all set"): calls `buildDoneContent(in:)` — this is the final illustration and does NOT need replacing

### Lifecycle
- Views are created fresh each time a step is displayed (no caching)
- The previous step's view is removed before the new one is added
- Views should use Auto Layout constraints pinned to the `container` parameter

### Method to modify

In `TourWindowController.updateIllustration(for:step:)`:

```swift
private func updateIllustration(for index: Int, step: TourStep) {
    illustrationPane.subviews.forEach { $0.removeFromSuperview() }

    if step.isFullWidth {
        buildDoneContent(in: illustrationPane)
    } else {
        // Replace this call with your illustration factory:
        buildPlaceholder(for: index, in: illustrationPane)
    }
}
```

Replace `buildPlaceholder(for:in:)` with a switch or array lookup:

```swift
private func buildIllustration(for index: Int, in container: NSView) {
    let view: NSView
    switch index {
    case 0: view = TourIllustration0()
    case 1: view = TourIllustration1()
    // ... etc
    default: return
    }
    view.translatesAutoresizingMaskIntoConstraints = false
    container.addSubview(view)
    NSLayoutConstraint.activate([
        view.topAnchor.constraint(equalTo: container.topAnchor),
        view.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        view.leadingAnchor.constraint(equalTo: container.leadingAnchor),
        view.trailingAnchor.constraint(equalTo: container.trailingAnchor),
    ])
}
```

---

## Step Index to Illustration Mapping

| Index | Title | Illustration needed |
|-------|-------|-------------------|
| 0 | Visual bugs are hard to describe | Yes |
| 1 | Screenshots become LLM ready prompts | Yes |
| 2 | Point at what you see | Yes |
| 3 | Marks become instructions | Yes |
| 4 | Give your AI the full picture | Yes |
| 5 | One paste or two | Yes |
| 6 | Add more screenshots | Yes |
| 7 | Label what each image shows | Yes |
| 8 | You're all set | **No** — already built (green checkmark, heading, kbd pills) |

---

## Step 9 Full-Width Mode (Index 8)

On the final step (`isFullWidth: true`), the layout changes:

1. `textPane` is hidden (`textPane.isHidden = true`)
2. `dividerView` is hidden (`dividerView.isHidden = true`)
3. `illustrationWidthConstraint` is replaced: the illustration pane now takes `bodyView.widthAnchor` (100%) instead of 60%
4. The "You're all set" content (green checkmark circle, heading, body text, keyboard pills) is built directly inside the illustration pane by `buildDoneContent(in:)`
5. This content is final — 229B does not need to replace it

When navigating back from step 9, the layout reverts: text pane and divider reappear, illustration pane goes back to 60%.

---

## Tokens and Constants for Illustration Views

| Token | Value | Use for |
|-------|-------|---------|
| `DesignTokens.tourWindowBg` | rgba(30,30,30,0.92) | Pane background (already set) |
| `DesignTokens.tourTextPrimary` | #E0E0E0 | Primary labels in illustrations |
| `DesignTokens.tourTextSecondary` | rgba(255,255,255,0.55) | Secondary labels |
| `DesignTokens.tourTextDim` | rgba(255,255,255,0.35) | Dim/subtle labels |
| `DesignTokens.purpleLight` | #AFA9EC | Purple accents |
| `DesignTokens.red` | #EF4444 | Annotation mark color |
| `DesignTokens.chromeBorder` | rgba(175,169,236,0.12) | Borders and dividers |
| `DesignTokens.tourBodyFont` | System 14px regular | Body text in illustrations |

---

## Minimal Example: Creating an Illustration View

```swift
import AppKit

final class TourIllustration0: NSView {

    override init(frame: NSRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        wantsLayer = true

        // Example: centered image or custom drawing
        let imageView = NSImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.imageScaling = .scaleProportionallyUpOrDown
        // imageView.image = NSImage(named: "tour-step-0")
        addSubview(imageView)

        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            imageView.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor, constant: -40),
            imageView.heightAnchor.constraint(lessThanOrEqualTo: heightAnchor, constant: -40),
        ])
    }
}
```

Then in `TourWindowController.updateIllustration(for:step:)`, replace the placeholder call:

```swift
case 0: view = TourIllustration0()
```

The illustration view is added edge-to-edge in the pane. Use internal constraints for padding.
