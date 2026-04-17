# Vibeliner — Launch Readiness Audit

**Date:** 2026-04-07
**Branch:** `claude/vib-319-batch-sprint`
**Auditor:** AI (VIB-316)
**Scope:** Full codebase read of every Swift file, Info.plist, project.pbxproj, docs, and CLAUDE.md.

---

## Section 1: UX Polish (Design Lead)

### 1.1 Light mode adaptation gaps

🟡 **Setup window is forced dark** — `SetupWindowController.swift:49` sets `window.appearance = NSAppearance(named: .darkAqua)`. All setup tokens (`DesignTokens.swift:554–632`) are hardcoded dark colors, not appearance-aware. If a user has macOS in light mode, the setup window will be dark while everything else is light. **Fix type:** Refactor (M) — convert ~30 setup tokens to appearance-aware and remove the forced dark appearance.

🟡 **Popover forced dark** — `PopoverViewController.swift` and the `PopoverWindow` use `DesignTokens.darkChromePopover` and hardcoded dark UI. The popover does not adapt to light mode. **Fix type:** Refactor (M) — same pattern as VIB-235 toolbar conversion.

🟡 **FirstUseTooltipView hardcoded dark** — `FirstUseTooltipView.swift:17–19` uses `DesignTokens.tooltipDarkBg` / `tooltipDarkBorder` and inline `NSColor(white: 1.0, alpha: …)` for text. In light mode over a light editor, this tooltip will look intentional but jarring. **Fix type:** Patch (S) — acceptable if the tooltip is always shown over the screenshot (dark background), but document the design decision.

🟡 **ScreenshotCanvasView border uses legacy token** — `ScreenshotCanvasView.swift:28` uses `DesignTokens.chromeBorder` (static rgba, not appearance-aware). In light mode the purple border will appear too faint. **Fix type:** Patch (XS).

🟡 **CaptureRowView uses legacy tokens** — `CaptureRowView.swift:69,84` use `DesignTokens.chromeBorder` for button backgrounds. **Fix type:** Patch (XS) — but the popover is forced dark so this only matters if the popover is converted.

### 1.2 Accessibility

🔴 **No VoiceOver labels anywhere** — Zero `setAccessibilityLabel()` calls in the entire codebase. ToolButton, ModeToggleView, CopyPillButton, and StatusPillView are all opaque to screen readers. **Fix type:** Patch (S).

🟡 **No keyboard navigation for toolbar** — The toolbar is entirely mouse-driven. There's no tab-key navigation between tool buttons, no focus ring on any ToolButton. A keyboard-only user cannot switch tools. **Fix type:** Refactor (M).

🟡 **Contrast concern on light mode toolbar** — `toolbarIconDefault` in light mode is `rgba(0,0,0,0.45)` (DesignTokens.swift:155). Against a white toolbar (`rgba(255,255,255,0.88)`), this gives roughly 3.5:1 contrast — below WCAG AA for small icons. **Fix type:** Patch (XS) — bump to 0.55.

### 1.3 App icon

🔴 **No app icon** — `Info.plist:9` has `CFBundleIconFile` set to empty string. The app will show the generic macOS app icon in Finder, About dialog, and the Settings window. `AboutTabView.swift:32–53` draws a red rounded rect with a crosshair as a placeholder. **Fix type:** Patch (S) — design and add an `.icns` file.

### 1.4 Animation & feedback

🟢 **No annotation delete animation** — When an annotation is deleted via the trash button, it disappears instantly. A brief fade-out would feel more polished. **Fix type:** Patch (S).

🟢 **Status pill "Copied" flash could conflict** — `StatusPillView.swift:77–96`: if the user clicks copy twice rapidly, the 2s revert timer fires for the first click and reverts the pill while the second copy animation is still showing. The timer is invalidated on re-entry so this is actually handled correctly. No issue.

### 1.5 Deprecated APIs

🟡 **`lockFocus` / `unlockFocus` used in 4 files** — `ScreenshotExporter.swift:15–36`, `AppDelegate.swift:120–169`, `AboutTabView.swift:42–50`, `VisualTestHarness.swift:142–181`. `lockFocus` is deprecated in macOS 14+ and will trigger warnings. **Fix type:** Refactor (S) per file — replace with `NSImage(size:flipped:drawingHandler:)` or `CGContext`-based drawing.

---

## Section 2: Product Completeness (PM)

### 2.1 PRD coverage

The PRD (`docs/specs/VIBELINER_PRD.md`) defines 12 product areas. Status:

| Area | Status |
|---|---|
| Setup flow | ✅ Fully implemented |
| Capture experience | ✅ Implemented (crosshair, dim overlay, dimension label) |
| 5 annotation tools | ✅ All 5 tools + select tool |
| Editor window | ✅ Implemented |
| Copy flow (IDE/App) | ✅ Both modes work |
| File structure | ✅ Folder/screenshot/prompt output |
| Prompt templates | ✅ Preamble, tools, footer, multi-image roles |
| Settings panel | ✅ 3 tabs + prompt sub-tabs |
| Menu bar popover | ✅ Implemented with recent captures |
| Global design rules | ✅ Token system in place |
| First-use tooltip | ✅ Implemented |
| Undo/redo | ✅ Implemented |

### 2.2 Missing or incomplete features

🟡 **About tab links are placeholder** — `AboutTabView.swift:99–107` links to `https://github.com/janaj2g-hub/vibeliner`. If this repo is private or doesn't exist yet, clicking "Documentation" or "Report an Issue" will 404. **Fix type:** Patch (XS) — verify URLs or gray them out until live.

🟡 **No multi-image capture flow in the editor** — `PromptTabView.swift` has a "Multi-image" settings sub-tab for role descriptions, but there's no actual multi-image capture or filmstrip UI in the editor. The role descriptions are configured but never consumed outside of `PromptGenerator.generateRoleDescription()`. This is a backlog feature, not a gap for v1 — but the settings tab creates an expectation that multi-image works. **Fix type:** Patch (XS) — consider hiding the Multi-image sub-tab until the feature ships, or add a "Coming soon" label.

🟢 **No capture folder size warning** — Screenshots accumulate in `~/Documents/vibeliner/` with no cleanup, no size warning, and no "delete old captures" mechanism. For a power user taking 50+ captures/day, this could quietly consume GBs. **Fix type:** Patch (S) — add a folder-size check and optional auto-cleanup in settings.

### 2.3 Five-minute test assessment

A developer downloads, opens, grants permissions, captures a region, drops a pin, types a note, hits copy, pastes into Claude Code. **Likely friction points:**

1. Generic app icon — first impression is "unfinished."
2. Setup window uses a dark chrome theme regardless of system appearance.
3. After granting permissions, the setup window polls every 2 seconds — user may need to wait.
4. The editor opens without explanation of the toolbar. The first-use tooltip helps but only explains IDE/App mode, not the tools themselves.
5. Copy works, prompt output is solid.

### 2.4 Sample prompt quality

For a single pin annotation with note "padding too tight on this card":

```
This is a screenshot of my running app. View it at ./screenshot.png

Numbered pins points to a specific issue. Each annotation has a number and a description.

Fix each issue:

1  [pin] padding too tight on this card

Make the changes and verify they match the design.
```

This is clear and actionable. The `[Screenshot Path]` and `[Tool Description]` templating works correctly. LLM-friendly output.

---

## Section 3: Software Engineering Quality (Senior SWE)

### 3.1 Debug logging in production

🟡 **8 `print()` calls in production code:**
- `ScreenCapture.swift:11,36,63,89`
- `CaptureCoordinator.swift:52,61,63`
- `GeneralTabView.swift:186`

These will appear in Console.app for end users. **Fix type:** Patch (XS) — replace with `os_log` or gate behind `#if DEBUG`.

🟡 **10 `NSLog()` calls:**
- `AppDelegate.swift:13,17`
- `HotkeyManager.swift:57,65,74,85`
- `VisualTestHarness.swift:119,125,132,134`

`NSLog` is heavier than `print` (goes to system log). The AppDelegate and HotkeyManager calls should be gated. VisualTestHarness is only used in `--visual-test` mode so less critical. **Fix type:** Patch (XS).

### 3.2 `fatalError()` in `init?(coder:)`

🟢 **26 occurrences across all NSView subclasses.** This is standard practice for AppKit views that are never loaded from nibs — not a production risk. No action needed.

### 3.3 Force unwraps

✅ **No `try!` or `!` force unwraps found** outside of `fatalError(init:coder)`. The codebase consistently uses `guard let`, `if let`, and `try?`.

**Exception:** `SetupWindowController.swift:629,633` uses `URL(string:)!` for system settings URLs. These are Apple-defined URLs that don't change, so the force unwrap is acceptable. **Fix type:** None (risk is negligible).

### 3.4 Memory — retain cycles

✅ **Delegates are consistently `weak`.** All tool classes (`PinTool`, `ArrowTool`, etc.) declare `weak var editorPanel`. `ToolbarView.delegate` is `weak`. Timer closures and notification observers use `[weak self]`.

🟡 **`CaptureCoordinator.swift:50` captures `[self]` strongly** — `DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [self] in`. Since `CaptureCoordinator` is a singleton, this won't leak, but it's an unusual pattern. **Fix type:** None (singleton — no cycle possible).

### 3.5 Thread safety

🟡 **ConfigManager properties are not synchronized for reads.** `ConfigManager.swift` uses `queue.sync` for `load()` and `save()`, but individual property reads (`capturesFolder`, `hotkey`, `copyMode`, etc.) are not protected. If a background save is in progress while the main thread reads a property, there's a theoretical race. In practice the app is single-user and saves are infrequent, so risk is low. **Fix type:** Patch (S) — wrap properties in computed getters that read through the queue, or accept the risk for v1.

🟡 **`ScreenshotExporter.exportAnnotatedScreenshot` uses `lockFocus` on a background thread** (`AutoSaveManager.swift:54`). `lockFocus` implicitly creates an `NSGraphicsContext` which is not thread-safe in all scenarios. Works in practice but is technically unsafe. **Fix type:** Refactor (S) — use `CGBitmapContext` directly.

### 3.6 Dead code

🟡 **Legacy non-appearance tokens still exist** — `DesignTokens.swift` contains ~15 pre-VIB-235 tokens (`darkChrome`, `darkChromeStatus`, `dividerColor`, `closeHoverBg`, `trashHoverBg`, `iconDefault`, `iconHover`, `buttonHoverBg`, `toolActiveBg`, `toggleActiveBg`, `toggleBg`, `toggleInactiveText`, `closeIconHover`) that were superseded by the `toolbar*` appearance-aware family. Some are still used by the popover/capture row. **Fix type:** Refactor (S) — audit usage and remove truly dead ones.

🟡 **`VisualTestHarness.swift`** — Test-only file included in the production target. Activated by `--visual-test` CLI flag. **Fix type:** Patch (XS) — move to a separate target or gate with `#if DEBUG`.

### 3.7 Code duplication

🟢 **Icon drawing functions** — `ToolbarView` has static icon drawing methods (`drawPinIcon`, `drawArrowIcon`, etc.) that are also called from `PromptTabView.ToolIconView`. This is an intentional shared API, not duplication.

🟢 **Pill chrome builder** — `PillChromeBuilder` in `NotePillRenderer.swift` is a proper shared abstraction used by both resting pills and the editing pill. Good pattern.

### 3.8 Test coverage

🔴 **Zero tests.** No test target exists in the Xcode project. No unit tests, UI tests, or snapshot tests. The `VisualTestHarness` is a manual visual-only check. **Fix type:** Refactor (M) — at minimum, add unit tests for `PromptGenerator`, `ConfigManager` (TOML round-trip), `AnnotationStore`, and `UndoRedoManager`.

---

## Section 4: Security & Privacy (Security Engineer)

### 4.1 Data at rest

🟡 **Screenshots in world-readable directory** — Default path is `~/Documents/vibeliner/`. This is user-owned (mode 0700 on Documents) but within the user's Documents folder which is synced by iCloud by default. Screenshots may contain sensitive application data. **Fix type:** Patch (S) — document this in the first-run experience, or default to `~/Library/Application Support/Vibeliner/` (not iCloud-synced).

🟡 **No capture expiry or cleanup** — Captures persist indefinitely. A user might not realize they have 2GB of screenshots with sensitive content. **Fix type:** Patch (S) — add an optional auto-delete-after-N-days setting.

### 4.2 Data in transit

✅ **No network calls.** Grep for `URLSession`, `URLRequest`, `NSURLConnection`, `WKWebView`, `fetch`, `http://`, `https://` confirms: the only URLs in the codebase are the GitHub links in `AboutTabView.swift:99–104` (opened via `NSWorkspace.shared.open`). The app does not phone home, collect analytics, or transmit any data.

### 4.3 Clipboard

🟢 **Clipboard data persists indefinitely** — After copying prompt text or an image, the content stays on `NSPasteboard.general` until replaced. This is standard macOS behavior. A clipboard timeout would be unusual for a developer tool. **Fix type:** None.

### 4.4 Config file

🟡 **TOML parser doesn't handle backslash properly** — `ConfigManager.swift:226–229`: `escapeString` only escapes `"` and `\n`. A preamble containing a literal backslash (`\`) will be written unescaped and re-read incorrectly (e.g., `\t` would be preserved as `\t` on write but read back as a tab character... actually no, `unquoteString` only replaces `\\n` → `\n` and `\\"` → `"`, so `\t` stays as `\t`). The real risk: a preamble containing `\n` as a literal two characters (not a newline) would be corrupted. **Fix type:** Patch (S) — escape `\` to `\\` in `escapeString`.

### 4.5 Entitlements & sandboxing

🔴 **No sandboxing** — `CODE_SIGN_ENTITLEMENTS = ""` in project.pbxproj. No `.entitlements` file exists. The app runs with full user-level filesystem access. This is acceptable for a developer tool distributed outside the App Store, but:
- Makes App Store distribution impossible without adding a sandbox.
- The app has access to the entire filesystem, not just the captures folder.

🔴 **Hardened runtime not explicitly enabled** — No `ENABLE_HARDENED_RUNTIME` flag found in build settings. Without hardened runtime, the app cannot be notarized by Apple, and macOS Gatekeeper will block it on other machines with a "cannot be opened because the developer cannot be verified" warning. **Fix type:** Patch (XS) — enable in Xcode build settings.

🟡 **No privacy manifest** — macOS 14+ introduced `PrivacyInfo.xcprivacy` for apps using specific APIs. Vibeliner uses `CGWindowListCreateImage` (screen capture API) which is a privacy-sensitive API. A privacy manifest may be required for notarization. **Fix type:** Patch (S) — add a `PrivacyInfo.xcprivacy` declaring screen capture and file system access reasons.

### 4.6 Screen recording permission

✅ **Permission handled correctly** — `SetupWindowController.swift:607` checks `CGPreflightScreenCaptureAccess()` and `ScreenCapture.swift:9` calls `CGRequestScreenCaptureAccess()` before capture. The app cannot capture without explicit user permission.

### 4.7 Temp files

✅ **Atomic writes with temp files** — `ScreenshotExporter.swift:43–46` and `PromptGenerator.swift:83–85` write to `.tmp` files and rename atomically. Temp files are cleaned up in the same operation.

---

## Section 5: Architecture & Future-Proofing (Architect)

### 5.1 Data model extensibility

🟡 **`AnnotationPosition` enum is rigid** — `AnnotationModel.swift` defines positions as an enum with associated values (`.pin(tip:)`, `.arrow(start:end:)`, etc.). Adding a new annotation type requires modifying this enum and every `switch` statement that matches on it. There are ~15 such switch statements across tools, renderers, and the select tool. **Fix type:** Accept for v1 — the 5 tool types are stable. Revisit if a 6th tool is added.

🟡 **No per-image annotation isolation** — The `AnnotationStore` is a flat array. Multi-image support would require either multiple stores or a parent-image ID on each annotation. The store would need a moderate refactor. **Fix type:** Refactor (M) when multi-image ships.

### 5.2 Config system

🟡 **Custom TOML parser is fragile** — `ConfigManager.swift:124–176` is a hand-rolled line-by-line TOML parser that only handles flat key-value pairs and one level of `[sections]`. It doesn't support: nested tables, arrays, inline tables, multi-line strings (triple quotes), or comments after values. Adding more settings is fine, but adding structured data (e.g., a list of prompt presets) would require parser changes. **Fix type:** Accept for v1 — the config is flat by design. If presets are added, consider migrating to JSON or `Codable` plist.

### 5.3 Editor coupling

🟡 **EditorPanel is a god object** — `EditorPanel.swift` is the largest file in the codebase (~350 lines). It implements `ToolbarDelegate` (12 methods), manages the canvas, auto-save, note editing, undo/redo, and copy flows. It's the single entry point for all editor behavior. Not yet a problem but trending that direction. **Fix type:** Accept for v1 — extract concerns (copy flow, auto-save coordination) into helpers if the file grows past 500 lines.

### 5.4 Design token architecture

✅ **Token system is well-structured.** The VIB-235 appearance-aware token pattern (`NSColor(name:)` with `isDarkAppearance()`) is clean and extensible. The `DesignTokens` enum is the single source of truth. New tokens can be added without touching other files.

🟡 **Two generations of tokens coexist** — Legacy static tokens (e.g., `darkChrome`, `iconDefault`) and VIB-235 appearance-aware tokens (e.g., `toolbarBg`, `toolbarIconDefault`) exist side by side. The old tokens are still used by the popover, capture row, and a few other surfaces. **Fix type:** Refactor (S) — migrate remaining consumers to appearance-aware tokens as those surfaces get light-mode support.

### 5.5 Build system

✅ **Clean build system** — Single target, no script phases beyond the standard copy-to-dist. No stale targets or unused build phases in `project.pbxproj`.

---

## Section 6: Performance & Perceived Speed (Performance Engineer)

### 6.1 Main thread concerns

🟡 **`ScreenshotExporter.exportAnnotatedScreenshot` uses `lockFocus`** — This is called from `AutoSaveManager.performSave` on a background queue (`DispatchQueue.global`). `lockFocus` creates an `NSGraphicsContext` which has thread-safety concerns. In practice this works because only one save runs at a time (debounced), but it's a latent risk. **Fix type:** Refactor (S) — use `CGBitmapContext` for thread-safe off-screen rendering.

🟡 **Full image re-render on every auto-save** — `AutoSaveManager.swift:54–56` composites annotations onto the full-resolution screenshot (potentially 5120×2880 on a 5K display) on every save. The 0.2s debounce helps, but a burst of annotation edits will queue up full renders. **Fix type:** Accept for v1 — the debounce is adequate. Monitor if users report lag on high-res displays.

### 6.2 Image handling

✅ **Thumbnails loaded on background queue** — `CaptureRowView.swift:40` loads capture thumbnails on `DispatchQueue.global(qos: .utility)` with `[weak thumbView]` to avoid retain issues. Good pattern.

🟡 **No thumbnail downsampling** — `CaptureRowView.swift:41` loads the full `NSImage(contentsOf:)` for a 44×30pt thumbnail. A 5K screenshot (~25MB PNG) will be fully decoded in memory for a tiny thumbnail. **Fix type:** Patch (S) — use `CGImageSource` with `kCGImageSourceThumbnailMaxPixelSize` for efficient downsampled loading.

### 6.3 Startup time

✅ **Minimal startup work** — `AppDelegate.applicationDidFinishLaunching` (`AppDelegate.swift:12–54`) does: load config, ensure folder, apply appearance, set up menu bar icon (one `lockFocus` call), register hotkey. No heavy computation, no network calls. Cold start should be <200ms.

### 6.4 Annotation rendering

✅ **Annotation drawing uses direct Core Graphics** — No intermediate image buffers, no Combine pipelines, no SwiftUI layout engine. `needsDisplay = true` on the marks layer triggers a single `draw()` pass through all renderers. This is the optimal pattern for 60fps dragging.

🟢 **Note pill reuse pool** — `NotePillRenderer.swift:17–80` maintains a view reuse pool to avoid creating/destroying NSViews on every redraw. Good pattern for drag performance.

### 6.5 Auto-save debouncing

✅ **0.2s debounce** — `AutoSaveManager.swift:42`. Keystrokes in note editors won't trigger per-character saves. The debounce window is appropriate.

---

## Section 7: Launch Readiness (TPM)

### 7.1 Bundle configuration

| Item | Status | Notes |
|---|---|---|
| Bundle ID | ✅ `com.vibeliner.app` | Stable, appropriate |
| Version | 🟡 `1.0` / build `1` | CFBundleShortVersionString is "1.0", CFBundleVersion is "1". Consider "1.0.0" for semantic versioning |
| Deployment target | ✅ macOS 14.0 | Correct |
| LSUIElement | ✅ `true` | Correctly hides from Dock |
| App icon | 🔴 Missing | `CFBundleIconFile` is empty |

### 7.2 Code signing & distribution

🔴 **No hardened runtime** — Cannot notarize without it. Gatekeeper will block the app on other machines. **Fix type:** Patch (XS).

🔴 **No entitlements file** — Even without sandbox, screen recording and accessibility require proper entitlements for notarized distribution. **Fix type:** Patch (S).

🟡 **No DMG or installer** — The built app is at `dist/Vibeliner.app`. No `create-dmg` script, no Sparkle framework for updates, no distribution packaging. **Fix type:** Refactor (S) — create a simple DMG build script.

### 7.3 Debug artifacts

🟡 **`print()` and `NSLog()` calls in production** — 18 total (see Section 3.1). **Fix type:** Patch (XS).

🟡 **VisualTestHarness in production target** — `VisualTestHarness.swift` is compiled into the release binary and activated by `--visual-test`. **Fix type:** Patch (XS) — wrap in `#if DEBUG`.

### 7.4 Crash reporting & updates

🟡 **No crash reporting** — If the app crashes, no data is collected. For a v1 direct distribution, this means relying on users to file issues. **Fix type:** Patch (S) — add basic crash log collection to `~/Library/Logs/Vibeliner/` or integrate a lightweight crash reporter.

🟡 **No update mechanism** — Users have no way to know when a new version is available. **Fix type:** Refactor (M) — integrate Sparkle or implement a simple version-check against a GitHub release tag.

### 7.5 License & legal

🟡 **No LICENSE file** — The repository has no license file. Without one, the code is technically "all rights reserved." **Fix type:** Patch (XS) — add a LICENSE file.

✅ **No third-party dependencies** — No license compatibility concerns.

### 7.6 Documentation

🟡 **No user-facing README** — The repository README (if it exists) is developer-focused (`CLAUDE.md`, `AGENTS.md`). There's no user-facing installation guide, feature overview, or screenshot. **Fix type:** Patch (S).

---

## Appendix: Prioritized Ticket Recommendations

### 🔴 P0 — Must fix before launch

| # | Title | Section | Fix type | Size | Existing ticket? |
|---|---|---|---|---|---|
| 1 | Enable hardened runtime for notarization | §4.5, §7.2 | Patch | XS | No |
| 2 | Add entitlements file (screen recording, accessibility) | §4.5, §7.2 | Patch | S | No |
| 3 | Add app icon (.icns) at all required sizes | §1.3, §7.1 | Patch | S | No |
| 4 | Add VoiceOver accessibility labels to toolbar buttons | §1.2 | Patch | S | No |
| 5 | Add unit test target + core tests (PromptGenerator, ConfigManager, AnnotationStore, UndoRedoManager) | §3.8 | Refactor | M | No |

### 🟡 P1 — Should fix before launch

| # | Title | Section | Fix type | Size | Existing ticket? |
|---|---|---|---|---|---|
| 6 | Gate `print()`/`NSLog()` behind `#if DEBUG` or `os_log` | §3.1, §7.3 | Patch | XS | No |
| 7 | Move VisualTestHarness to `#if DEBUG` | §3.6, §7.3 | Patch | XS | No |
| 8 | Fix ConfigManager TOML backslash escaping | §4.4 | Patch | S | No |
| 9 | Replace `lockFocus` with `CGBitmapContext` in ScreenshotExporter | §3.5, §6.1 | Refactor | S | No |
| 10 | Add privacy manifest (`PrivacyInfo.xcprivacy`) | §4.5 | Patch | S | No |
| 11 | Replace `lockFocus` in AppDelegate menu bar icon | §1.5 | Patch | XS | No |
| 12 | Replace `lockFocus` in AboutTabView icon | §1.5 | Patch | XS | No |
| 13 | Convert setup window to appearance-aware (light mode) | §1.1 | Refactor | M | No |
| 14 | Convert popover to appearance-aware (light mode) | §1.1 | Refactor | M | No |
| 15 | Verify or gray out About tab GitHub links | §2.2 | Patch | XS | No |
| 16 | Add LICENSE file | §7.5 | Patch | XS | No |
| 17 | Add DMG build script for distribution | §7.2 | Refactor | S | No |
| 18 | Thumbnail downsampling for capture row | §6.2 | Patch | S | No |
| 19 | Add user-facing README | §7.6 | Patch | S | No |
| 20 | Bump version to 1.0.0 semantic format | §7.1 | Patch | XS | No |
| 21 | Audit and remove dead legacy tokens | §3.6, §5.4 | Refactor | S | No |

### 🟢 P2 — Fix after launch

| # | Title | Section | Fix type | Size | Existing ticket? |
|---|---|---|---|---|---|
| 22 | Add keyboard navigation for toolbar (tab key) | §1.2 | Refactor | M | No |
| 23 | Add capture folder size warning / auto-cleanup | §2.3, §4.1 | Patch | S | No |
| 24 | Add crash log collection | §7.4 | Patch | S | No |
| 25 | Add update mechanism (Sparkle or GitHub release check) | §7.4 | Refactor | M | No |
| 26 | Hide Multi-image settings tab until feature ships | §2.2 | Patch | XS | VIB-270 (related) |
| 27 | Add annotation delete animation | §1.4 | Patch | S | No |
| 28 | Consider moving default captures folder to ~/Library/Application Support | §4.1 | Patch | S | No |
| 29 | Boost light-mode icon contrast (0.45 → 0.55) | §1.2 | Patch | XS | No |
| 30 | ConfigManager thread-safe property reads | §3.5 | Patch | S | No |
