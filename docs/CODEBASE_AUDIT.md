# Vibeliner — Codebase Audit

**Date:** 2026-03-30
**Branch:** `codex/vib-75-canonical-runtime-capture` (latest `main` state)
**Build status:** Compiles cleanly with `xcodebuild -project Vibeliner.xcodeproj -scheme Vibeliner build`

---

## Executive Summary

Vibeliner is a functional v1 with a working capture-annotate-copy pipeline. The core product flow — hotkey, region select, annotate, Copy for LLM — works end-to-end. The codebase has sound architectural instincts (typed capture outcomes, centralized prompt generation, explicit permission state model) but is overweight for a v1 at ~3,900 lines of logic across 13 files. The most significant structural issue is that the menu bar uses a custom `NSPanel` with hosted SwiftUI instead of a native `NSMenu`, which makes the app feel non-native and consumes ~250 lines that shouldn't exist. The annotation system is well-modeled and reasonably extensible. The capture pipeline and prompt generation are solid. The editor window is correctly implemented as a floating `NSPanel`.

**Verdict:** You can build features on this foundation, but two structural fixes should come first: (1) replace the custom menu panel with a native `NSMenu`, and (2) split `AppDelegate.swift` (852 lines) so it stops being the god object. Everything else is polish or spec compliance work that can happen alongside features.

---

## File Inventory

| File | Total Lines | Logic Lines | Description |
|------|-------------|-------------|-------------|
| `Vibeliner/VibelinerApp.swift` | 12 | 10 | `@main` entry point, `NSApplicationDelegateAdaptor` bridge |
| `Vibeliner/AppDelegate.swift` | 852 | 717 | Menu bar, hotkey, capture orchestration, menu panel, permission handling, settings presentation, alert system — everything |
| `Vibeliner/AnnotationCanvas.swift` | 1,204 | 1,000 | Custom `NSView`: drawing, hit-testing, inline text editing, badge rendering, shape tools |
| `Vibeliner/EditorWindowController.swift` | 629 | 542 | Borderless floating `NSPanel`, toolbar construction, save/copy/delete actions, toast |
| `Vibeliner/CaptureStore.swift` | 419 | 339 | File-system capture persistence: save, update, list, clean, clipboard prompt derivation |
| `Vibeliner/PromptSettingsView.swift` | 412 | 357 | SwiftUI settings panel with About, Hotkey, Prompt Settings, General tabs + panel presenter |
| `Vibeliner/MenuBarPopover.swift` | 286 | 242 | SwiftUI menu content: setup cards, capture actions, settings links, issue display |
| `Vibeliner/Config.swift` | 286 | 229 | `PromptBuilder` (prompt generation) + `VibelinerConfig` model + `Config` class (TOML read/write) |
| `Vibeliner/CaptureManager.swift` | 261 | 229 | `screencapture -i -x` invocation, outcome classification, diagnostic reporting |
| `Vibeliner/CLI/VibeLinerCLI.swift` | 186 | 142 | CLI: list, copy, send, clean commands via ArgumentParser |
| `Vibeliner/AppRuntimeIdentity.swift` | 87 | 68 | Runtime bundle identity checks (dist vs DerivedData vs other) |
| `Vibeliner/Annotation.swift` | 31 | 27 | Data model: `Annotation` struct + `AnnotationType` enum |
| `Vibeliner/Constants.swift` | 20 | 19 | Shared color and sizing constants |
| **Total** | **4,685** | **3,921** | |

**vs. Product vision target:** The vision says "~10 source files." We have 13 files (12 excluding CLI). This is acceptable — the file count is close and the separation is generally logical. The problem is not file count but line count distribution.

---

## Architecture Verdict

### Total Weight

3,921 lines of logic for a v1 capture-annotate-copy tool is **high**. The healthy range for this scope is 1,500–2,500. Where is the bulk?

- **AnnotationCanvas.swift: 1,000 lines** — This is the largest file and the core interaction surface. It includes drawing, hit-testing, inline text editing, undo, drag, context menus, keyboard shortcuts, and badge rendering. Most of this complexity is necessary. However, ~200 lines of note-rect/editor-resize calculation could be extracted.
- **AppDelegate.swift: 717 lines** — This is the god object. It owns: menu bar setup, menu panel construction, menu panel positioning, menu panel dismiss logic, hotkey registration, capture orchestration, permission state management, settings presentation, alert presentation, activation policy management, capture prompt copying, folder opening/picking, screen recording remediation, and relaunch logic. At least 300 lines of menu panel code and 100+ lines of permission/identity handling should be elsewhere.
- **EditorWindowController.swift: 542 lines** — Reasonable for a window controller that builds its own toolbar, but ~100 lines of button factory methods could be shared or simplified.
- **PromptSettingsView.swift: 357 lines** — This is the settings panel, not just prompt settings (despite the filename). Contains About, Hotkey, General, and Prompt Settings tabs plus the panel presenter. The name is misleading.

### Dependency Diagram

```
VibelinerApp.swift
    └── AppDelegate.swift
            ├── AppState (ObservableObject)
            │   ├── CaptureStore.shared
            │   └── ScreenRecordingPermissionState
            ├── CaptureManager.shared
            │   └── AppRuntimeIdentity
            ├── EditorWindowController
            │   ├── AnnotationCanvas
            │   │   ├── Annotation (model)
            │   │   └── Constants
            │   ├── CaptureStore.shared
            │   └── Config.shared
            ├── MenuBarPopover (SwiftUI)
            │   └── AppState
            ├── PromptSettingsView (SwiftUI)
            │   ├── Config.shared
            │   ├── PromptBuilder
            │   └── AppRuntimeIdentity
            ├── Config.shared
            │   └── PromptBuilder
            └── AppRuntimeIdentity

CLI/VibeLinerCLI.swift
    ├── CaptureStore.shared
    └── Config.shared
```

**Layering assessment:** The dependency flow is generally clean and acyclic. `CaptureStore`, `CaptureManager`, `Config`, and `PromptBuilder` form a clean data/service layer. The view layer (`AnnotationCanvas`, `EditorWindowController`, `MenuBarPopover`, `PromptSettingsView`) consumes services without circular imports. The main problem is `AppDelegate` — it reaches into everything because it owns too many responsibilities.

### Annotation Extensibility — Rating: 3.5/5

**Good:**
- `Annotation` is a proper model struct with `AnnotationType` enum, point array, note, and number
- `AnnotationType` has three cases (`freehand`, `arrow`, `circle`) and adding a fourth is straightforward in the model
- Badge numbering and note text are decoupled from drawing logic
- Drawing dispatch uses a `switch` on `AnnotationType`, so new tools get a clear insertion point
- Hit-testing and badge rendering are separate from stroke drawing

**Needs work:**
- Adding a new tool requires changes in at least 5 places in `AnnotationCanvas.swift` alone: `drawAnnotation()`, mouse handlers for the new shape, hit-testing, and shape preview. Plus `EditorWindowController.swift` for the toolbar button, and `toolTag`/`toolForTag` mappings
- There is no annotation tool protocol — behavior is hardcoded per-type in switch statements. For v1 this is fine (3 tools), but adding tool #4 or #5 will start feeling painful
- The inline text editing system (showTextField, finalizeActiveTextField, resizeActiveEditor) is tightly coupled to the canvas view — ~350 lines of NSTextView subview management that will need careful surgery for any text-related feature changes

**What it would take to add a text callout box:** You would need to add a new `AnnotationType.textCallout` case, add drawing logic in `AnnotationCanvas`, add shape preview, add hit-testing, add a toolbar button in `EditorWindowController`, and update the tag mapping. ~6 touch points across 2 files. Not terrible, but not as clean as a tool-handler protocol would be.

### File/Capture Management Extensibility — Rating: 4/5

**Good:**
- `CaptureStore` is a clean single point of control for all file operations
- Folder naming, artifact filenames, and directory structure are centralized
- The `StorageStatus` model gives clean validation at every entry point
- `CaptureRecord` is a proper model with Codable conformance
- The CLI shares the same `CaptureStore` and `Config` instances as the app

**Needs work:**
- `CaptureStore` uses `print()` for some error paths instead of proper error propagation (e.g., `delete()` at L253, `list()` at L304)
- The slug derivation (`deriveSlug`) is limited — only uses the first annotation's note text
- No batch export support yet, but the architecture doesn't prevent it

**What it would take to add a capture browser:** You would add a new SwiftUI view that calls `CaptureStore.shared.list()` and presents results. The data layer is ready. Rating reflects that the foundation is solid.

### Prompt Template Extensibility — Rating: 4.5/5

**Good:**
- `PromptBuilder` is the single source of truth for all prompt generation
- The `{{SCREENSHOT_PATH}}` token system is well-designed and documented
- Two explicit contracts: saved (relative path) and clipboard (absolute path)
- `clipboardPrompt(from:screenshotURL:)` derives clipboard output from saved prompt — no duplication
- Config migration normalizes old templates automatically
- Annotation semantics summary is a single static string, not scattered

**Needs work:**
- `PromptBuilder` lives inside `Config.swift` — it should be its own file for clarity
- The batch preamble exists in the model but has no runtime code path yet

### Unnecessary Abstractions

- **`AppRuntimeIdentity`** (87 lines): This exists to detect whether the running app is the `dist/` copy vs DerivedData. It has one consumer pattern (checking `isSupportedRuntimeCopy` and generating remediation text). For a v1, this is over-engineered — the entire file could be 15 lines of utility functions. However, it was created to solve a real debugging problem documented in TECHNICAL_DECISIONS.md, so it's not baseless.
- **`UserFacingIssue`** struct: Has 5 properties and a `showsScreenRecordingSettingsAction` boolean that creates branching in the alert system. This could be simpler — the issue system feels designed for a future where there are many issue types, but right now there are only two: storage problems and screen recording problems.
- **`ScreenRecordingPermissionState`** enum with only 2 cases: `.authorized` and `.notGranted`. The original ticket work (VIB-57/VIB-63) removed richer states (`.relaunchRequired`, `.appCopyMismatch`) after discovering they caused false positives. The current simplification is correct, but the remaining boilerplate (computed properties for `setupDetail`, `issue`, `offersOpenSettingsShortcut`) is now heavier than the enum justifies.
- **`CaptureFileStatus`** private struct in CaptureManager: Has 2 properties (`exists`, `size`) and one computed property. This could be a tuple.

### Missing Abstractions

- **No menu abstraction.** The custom menu panel is built inline in `AppDelegate` (~200 lines of NSPanel construction, positioning, and dismiss logic). If switching to NSMenu, most of this goes away. If keeping the custom panel, it should at least be its own class.
- **PromptBuilder in Config.swift.** Two unrelated concerns (prompt generation and TOML config) share one file. This makes it harder to find and reason about prompt logic.
- **No settings coordinator.** Settings presentation is handled by `AppDelegate.showSettings()` calling `PromptSettingsPanelPresenter.show()`. The file is named `PromptSettingsView.swift` but contains all settings tabs. A rename at minimum; ideally the presenter moves out of the view file.

### Code the Next Agent Will Break

1. **Menu panel dismiss logic** (`AppDelegate.swift` L651-722). The event monitors, geometry-based hit testing, and interaction between local and global monitors are fragile. A future agent adding a submenu, popover, or any new interactive element inside the menu panel will likely break dismiss behavior. This is documented as a failed approach in TECHNICAL_DECISIONS.md — the fix was geometry-based hit testing, but the complexity remains.

2. **Inline text editing in AnnotationCanvas** (`AnnotationCanvas.swift` L637-829). The 200-line block that creates an NSScrollView → NSTextView → placeholder label → badge view hierarchy, manages focus with deferred `makeFirstResponder`, handles `textDidEndEditing` with async finalization, and resizes the editor on text changes is the most fragile interaction code in the app. Any change to note layout, badge positioning, or text field behavior will require understanding the full state machine.

3. **Activation policy dance** (`AppDelegate.swift` L725-755). The `beginInteractiveSession()`/`endInteractiveSession()` counting system and `restoreAccessoryModeIfIdle()` logic interact with multiple code paths (capture, settings, editor close, alerts). A future agent that adds a new window or interactive flow without properly bracketing it with begin/end calls will cause the app to get stuck in regular mode or drop back to accessory mode while a window is still visible.

### Verdict

**You can build features on this foundation, but two structural fixes should come first:**

1. **Replace the custom menu panel with native `NSMenu`.** This removes ~200 lines of fragile dismiss/positioning code from `AppDelegate`, makes the menu look native, and eliminates the most likely source of future regressions. The macshot reference app uses `NSMenu` with `NSMenuDelegate` for dynamic content — this is the correct pattern for a menu bar app.

2. **Extract responsibilities from `AppDelegate`.** At 852 lines, it's a god object. The minimum extraction: move menu construction to a dedicated class or switch to `NSMenu` (which solves this naturally), and move the permission/identity/remediation logic into a small coordinator.

Everything else — missing polish, spec deviations, minor naming issues — can be fixed alongside feature work.

---

## Category Findings

### Menu Bar Implementation (Task 2)

**Type: Custom `NSPanel` with hosted SwiftUI — NOT a native `NSMenu`.**

The menu bar uses a custom `MenuPanel` (private `NSPanel` subclass at `AppDelegate.swift` L149-152) that hosts a SwiftUI `MenuBarPopover` view via `NSHostingController` inside an `NSVisualEffectView`. This is constructed at `AppDelegate.swift` L543-597.

**Specific issues:**
- **Not native.** macOS system menus (Sound, Wi-Fi, Bluetooth) and apps like macshot use `NSMenu` with `NSMenuItem`. Vibeliner uses a borderless `NSPanel` with `.nonactivatingPanel` style mask, `.menu` material effect view, and 16px corner radius. This does not match any standard macOS menu pattern.
- **Custom dismiss logic required.** Because it's not an `NSMenu`, the panel requires local and global event monitors (`AppDelegate.swift` L651-677) with geometry-based hit testing (`AppDelegate.swift` L717-722) to handle outside clicks. This is the pattern documented as a failed approach in TECHNICAL_DECISIONS.md ("Dismissing the custom menu panel based on event window identity alone"), and the current geometry-based fix adds complexity.
- **No keyboard shortcut display.** Native `NSMenuItem` can display keyboard shortcuts automatically. The custom SwiftUI rows show the hotkey as trailing text but don't use the native shortcut display pattern.
- **No native separators.** Uses a custom SwiftUI `Rectangle` divider (`MenuBarPopover.swift` L131-136) instead of `NSMenuItem.separator()`.
- **Hardcoded width.** The panel content is fixed at 286pt width (`MenuBarPopover.swift` L112). Native menus auto-size.

**What it would take to switch to `NSMenu`:**
- Replace `MenuPanel` with `NSMenu` assigned to `statusItem.menu`
- Implement `NSMenuDelegate.menuNeedsUpdate(_:)` for dynamic recent captures
- Each menu row becomes an `NSMenuItem` with SF Symbol images
- Settings open from menu item actions instead of SwiftUI button closures
- The setup/issue cards would need to be either simplified menu items or moved to a first-run sheet
- Remove ~200 lines of panel construction, positioning, and dismiss logic from `AppDelegate`
- Remove the `MenuBarPopover.swift` SwiftUI view entirely (286 lines)
- Net reduction: ~400+ lines removed, ~80 lines of `NSMenu` construction added

### First-Run Setup and Permissions (Task 3)

**The implementation partially meets the spec but is overly complex.**

The product vision says: "On first launch, the menu bar popover shows whether Screen Recording is granted, whether the captures folder is writable, and whether Vibeliner is ready to capture."

**What actually happens:**
- Storage status is checked via `CaptureStore.prepareSaveDirectory(autoRepair: true)` on every `AppState.refresh()` call. If the captures folder doesn't exist, it's auto-created. This is good.
- Screen Recording state is checked via `CGPreflightScreenCaptureAccess()` but is **no longer shown in the menu** (`MenuBarPopover.swift` L61-63 — `showsSetupSection` only checks `storageStatus.isReady`, not screen recording). The menu only shows a setup section if the captures folder is unavailable.
- Screen Recording issues surface only after a failed capture attempt, as an inline issue card (`MenuBarPopover.swift` L90-93). This is the correct behavior per TECHNICAL_DECISIONS.md ("keep it advisory"), but a first-time user gets no proactive indication.
- The `requestScreenRecordingAccess()` flow at `AppDelegate.swift` L518-537 calls `CGRequestScreenCaptureAccess()` and handles the response, but there's no menu item that triggers this proactively.

**Comparison to macshot:** macshot has a dedicated `PermissionOnboardingController` that explicitly walks users through Screen Recording permission with step-by-step UI. Vibeliner has no equivalent onboarding — it relies on post-failure error cards.

**Assessment:** The permission model is technically sound (advisory state, authoritative capture results), but the first-run UX is weak. A new user sees a menu with "Capture now" and no indication of whether capture will work until they try it.

### Annotation Bar and Tool Performance (Task 4)

**The annotation tools are functional and correctly implement the product spec.**

**Toolbar design** (`EditorWindowController.swift` L102-203): The toolbar is a plain `NSView` strip with programmatically created `NSButton` instances. It includes: close (X), separator, freehand/arrow/circle tool buttons, separator, undo, trash, Save, Copy for LLM. This matches the spec: "Dark toolbar strip at top with: X close, tool buttons, undo, trash, Save, Copy for LLM."

**Tool implementation:**
- Freehand: Captures mouse points during drag, draws `NSBezierPath` strokes. Pin drop (single click) renders a small dot. Works correctly.
- Arrow: Drag from start to end with dashed preview during drag. Arrowhead rendering with proper angle math at `AnnotationCanvas.swift` L234-260.
- Circle: Drag from center to edge with dashed preview. Radius-based rendering.
- All tools auto-assign the next number and immediately open an inline text field.

**Badge and numbering:**
- Badges render as 24px red circles with white bold monospaced-digit numbers (`AnnotationCanvas.swift` L298-331).
- Numbers re-sequence on delete (`AnnotationCanvas.swift` L846-855): `for i in annotations.indices { annotations[i].number = i + 1 }`. Correct per spec.
- Double-digit numbers use smaller font (12pt vs 15pt). Optical kerning offset for "3" and 10+. Good attention to detail.

**Performance:** Drawing uses Core Graphics via `NSBezierPath` in the `draw(_:)` override. No off-screen buffering or layer-backed optimization, which means the entire view redraws on every `needsDisplay = true`. For a screenshot annotation tool with <20 annotations, this is fine. Freehand drawing appends points on `mouseDragged` and calls `needsDisplay = true` — no perceptible lag expected for reasonable stroke counts.

**Issues:**
- The freehand tool icon uses a custom `makeNumberBadgeIcon()` method (`EditorWindowController.swift` L572-605) that draws a circle with "#" inside. This is creative but doesn't match the SF Symbols used by the other tools — it looks hand-crafted rather than native.
- Tool arming: After placing an annotation, `isToolArmed` is set to `false` (`AnnotationCanvas.swift` L587). The user must click the tool button again or press 1/2/3 to arm the next annotation. This is a UX friction point — see UX Recommendations.

### Editor Window (Task 5)

**The editor is correctly implemented as a floating `NSPanel`.**

- **Type:** `EditorPanel` is a private `NSPanel` subclass (`EditorWindowController.swift` L9-12) with `canBecomeKey = true` and `canBecomeMain = true`.
- **Style:** Borderless (`.borderless`), resizable, floating (`level = .floating`, `isFloatingPanel = true`), `hidesOnDeactivate = false`. Dark appearance forced via `NSAppearance(named: .darkAqua)`.
- **Floats correctly:** `level = .floating` ensures it stays above normal windows.
- **Activation policy dance:** `beginInteractiveSession()` at `AppDelegate.swift` L725-730 switches to `.regular` and activates. `endInteractiveSession()` at L733-737 decrements a counter and calls `restoreAccessoryModeIfIdle()`. The editor's `onClose` callback triggers `endInteractiveSession()` at L407. This matches the pattern documented in TECHNICAL_DECISIONS.md.

**Action buttons:**
- Close (X): `closeEditor()` at L308-313 — performs save, then closes. Matches spec: "X is the only way to close (auto-saves before closing)."
- Save: `saveAction()` at L325-331 — saves and shows "Saved" toast.
- Copy for LLM: `copyForLLMAction()` at L334-353 — saves, copies clipboard prompt, shows "Copied" toast. Matches spec: "Copy for LLM = save + clipboard + Copied toast. Window stays open."
- Delete (trash): `deleteAction()` at L316-323 — deletes saved record if exists, closes window. Matches spec.
- Cmd+C routing: `installKeyEventMonitor()` at L469-495 checks if text editing is active; if not, routes to `copyForLLMAction()`. Matches spec: "Cmd+C (when no text field focused) = same as Copy for LLM."

**Issue:** The spec mentions three action buttons (Delete, Save, Copy for LLM), but the toolbar also has Close (X), undo, and tool buttons. The toolbar is functional but has 8 buttons total, which is a lot for a 40px strip.

### Capture Pipeline (Task 6)

**The capture pipeline is well-implemented and correctly follows TECHNICAL_DECISIONS.md.**

- **Invocation:** `CaptureManager.captureRegion()` at L30-86 creates a temp file, calls `/usr/sbin/screencapture -i -x <tempfile>`, waits for file materialization, classifies the result.
- **Outcome typing:** `CaptureOutcome` enum with `.success(NSImage)`, `.cancelled`, `.failure(CaptureFailure)`. Clean separation per TECHNICAL_DECISIONS.md.
- **Cancellation detection:** `isUserCancelled()` at L125-132 checks: exit code 1, empty stderr, no file. Correct.
- **File materialization wait:** `waitForCaptureFile()` at L110-123 polls every 50ms for up to 1 second. Reasonable.
- **Temp file cleanup:** `defer { try? FileManager.default.removeItem(at: captureURL) }` at L36-38. Correct.
- **Activation policy:** `startCapture()` at `AppDelegate.swift` L245-270 calls `restoreAccessoryModeIfIdle()` before launching capture (stays in accessory mode for native `screencapture` crosshairs), then dispatches capture with a 100ms delay. On success, calls `beginInteractiveSession()` before presenting the editor. Matches the pattern in TECHNICAL_DECISIONS.md.

**Issue:** The `classifyFailure()` method at `CaptureManager.swift` L134-227 is 93 lines of string matching against stderr content (`"declined tcc"`, `"could not create image from rect"`, etc.). This is correct but fragile — Apple could change stderr messages in future macOS versions. Worth noting but not actionable for v1.

### Output Format (Task 7)

**Output format matches the spec.**

- Each capture produces `screenshot.png`, `prompt.md`, and `meta.json` in a timestamped folder (`CaptureStore.save()` at L156-201).
- Folder naming: `YYYY-MM-dd_HHmmss_[slug]` with collision avoidance at L360-373. Matches spec.
- Saved `prompt.md` uses relative path `./screenshot.png` via `PromptBuilder.buildSavedPrompt()` at L48-56.
- Clipboard uses absolute path via `PromptBuilder.clipboardPrompt(from:screenshotURL:)` at L59-65.
- `{{SCREENSHOT_PATH}}` token is handled correctly: if present in template, replaced; if absent, a separate screenshot line is appended (`PromptBuilder.buildPrompt()` at L23-45).

**Issue:** `meta.json` doesn't include `id` or `folderURL` in its encoded output — `CaptureRecord.CodingKeys` at L12-14 only encodes `created`, `count`, `slug`, `sent`. The `id` is derived from the folder name on decode at L295. This is fine but means the `id` field in the struct is set to empty string during decode (`L32: id = ""`), which is confusing.

### UI Polish Scores (Task 8)

| Area | Score | Notes |
|------|-------|-------|
| Menu bar icon appearance | 3/5 | Uses `circle.dashed` SF Symbol — functional but not distinctive. No custom icon. |
| Menu item layout and native feel | 2/5 | Custom NSPanel with SwiftUI, not NSMenu. Visually custom, not native. Hover states work but don't match system menu behavior. |
| Editor window appearance | 4/5 | Clean borderless floating panel, dark theme, proper toolbar layout. Looks polished. |
| Annotation rendering quality | 4/5 | Strokes are clean, badges are well-rendered with optical adjustments, arrow heads look good. |
| First-run experience | 2/5 | No onboarding. Screen Recording status not shown proactively. User must fail a capture to discover permission issues. |
| Error handling and messages | 3/5 | Good typed error model with recovery suggestions. But errors only surface via inline cards or alerts — no persistent status indicator. |

### Project Instructions (Task 9)

**CLAUDE.md and AGENTS.md:**
- These two files are 90% identical. `CLAUDE.md` is for Claude Code, `AGENTS.md` is for Codex. The differences: branch prefix (`claude/` vs `codex/`), prompt comment header (`## Claude Code prompt` vs `## Codex prompt`), and some wording.
- **Contradiction:** `CLAUDE.md` L4 says "Do not spawn subagents or run tasks in parallel" under execution rules, which conflicts with general Claude Code capabilities. `AGENTS.md` has the same rule at L52.
- **Redundancy risk:** Having two near-identical files means edits to one must be replicated to the other. This has already drifted slightly — `AGENTS.md` says "Finish one ticket completely before starting the next" while `CLAUDE.md` says "Finish one ticket completely (build, verify, post comment, update status) before starting the next."
- **Recommendation:** Merge into a single `AGENTS.md` with a small section noting branch prefix differences per agent type.

**LINEAR_CONVENTIONS.md:**
- Clean and concise. No contradictions with other files.
- Missing: no guidance on how to handle audit/research tickets (no code changes, report output). This audit ticket required interpreting the conventions for a non-implementation task.

**Missing from instructions:**
- No guidance on how to handle the `dist/Vibeliner.app` copy step when code changes affect the running app behavior. An agent might build but forget that the `dist/` copy is the canonical test target.
- No mention of `docs/ANNOTATION_PROMPTING.md` in LINEAR_CONVENTIONS.md, even though `CLAUDE.md` and `AGENTS.md` both reference it.

---

## Critical Issues

1. **Menu bar is not a native `NSMenu`.** `AppDelegate.swift` L543-597 builds a custom `NSPanel` with `NSVisualEffectView` and hosted SwiftUI content. This requires ~200 lines of custom dismiss/positioning logic, doesn't look like a system menu, and is the most likely source of future interaction regressions. **Impact:** Every menu bar interaction is non-standard. **Fix:** Replace with `NSMenu`/`NSMenuItem` + `NSMenuDelegate`.

2. **`AppDelegate` is an 852-line god object.** It handles menu bar, hotkey, capture flow, editor presentation, settings presentation, permission state, alerts, activation policy, and identity checks. This makes it extremely fragile for future agents — any change to one subsystem risks breaking another. **Impact:** High regression risk on any AppDelegate change. **Fix:** Extract menu, permission/identity handling, and alert presentation into separate types.

3. **No first-run onboarding.** A new user who installs Vibeliner and clicks the menu bar icon sees "Capture now" and settings links but no indication of whether Screen Recording is granted. The first failure is confusing. **Impact:** Poor first-run experience. **Fix:** Add a one-time setup check that surfaces Screen Recording status in the menu or as a first-launch sheet.

## Major Issues

4. **`PromptBuilder` lives inside `Config.swift`.** Two unrelated concerns (prompt generation and TOML configuration) share one file at `Config.swift` L3-79. This makes prompt logic harder to find and reason about. **Fix:** Move `PromptBuilder` to its own file.

5. **`PromptSettingsView.swift` is misnamed.** It contains all settings (About, Hotkey, General, Prompt Settings) plus the `PromptSettingsPanelPresenter` and `SettingsTab` enum. The filename implies it's only prompt settings. **Fix:** Rename to `SettingsView.swift` or `SettingsPanelView.swift`.

6. **Tool de-arms after each annotation.** `AnnotationCanvas.swift` L587: `isToolArmed = false` after every `mouseUp`. The user must re-arm the tool for each annotation. For the primary use case (quickly placing multiple numbered pins), this adds friction. **Fix:** Keep the tool armed until the user explicitly changes tools or hits Escape.

7. **No annotation semantics summary line in exported prompt when annotations exist.** `PromptBuilder.buildPrompt()` at `Config.swift` L41-42 appends annotation lines but does not include the `annotationSemanticsSummary` string in the output. The summary is only in the default preamble template. If a user customizes their preamble and removes the summary, the numbered list has no context explaining what badges mean. **Fix:** Consider always including a brief annotation context line when annotations are present.

## Minor Issues

8. **`CaptureRecord.id` is empty string after decode.** `CaptureStore.swift` L32-33 sets `id = ""` and `folderURL = URL(fileURLWithPath: "/")` in `init(from:)`, then overwrites them at L294-299. This works but is confusing for anyone reading the model.

9. **`print()` used for non-critical errors.** `CaptureStore.swift` L253, L304 use `print()` for delete and list errors instead of proper error handling or logging.

10. **Hardcoded toolbar color.** `EditorWindowController.swift` L28: `toolbarColor = NSColor(red: 0.165, green: 0.165, blue: 0.173, alpha: 1.0)` and L29: `accentBlue = NSColor(...)` are not in `Constants.swift`. Similarly, `MenuBarPopover.swift` has inline color values.

11. **`CaptureFileStatus` could be simpler.** `CaptureManager.swift` L243-261 defines a struct with 2 stored properties and 1 computed. A tuple would suffice.

12. **`isTextEditingActive()` has a redundant check.** `EditorWindowController.swift` L498-504 calls `activeTextEditingView()` and returns `true` if non-nil, then returns `false`. This could be a one-liner: `return activeTextEditingView() != nil`.

---

## What's Good

1. **Typed capture outcomes.** The `CaptureOutcome` enum with `.success`, `.cancelled`, `.failure(CaptureFailure)` is exactly right. The distinction between cancellation and failure was a hard-won lesson documented in TECHNICAL_DECISIONS.md, and the implementation is clean.

2. **Centralized prompt generation.** `PromptBuilder` as the single source of truth for prompt assembly, with explicit saved vs. clipboard path contracts, is well-designed. The `{{SCREENSHOT_PATH}}` token system is clean.

3. **Annotation data model.** `Annotation` struct is simple, correct, and supports the current tool set without over-abstraction. The `translate(by:)` method for drag support is a good touch.

4. **CaptureStore as single point of control.** All file operations go through one class. The `StorageStatus` validation model catches problems early. The `prepareSaveDirectory(autoRepair:)` pattern is defensive and correct.

5. **Activation policy management.** The `beginInteractiveSession()`/`endInteractiveSession()` counting pattern is the right approach for an accessory app that needs temporary foreground activation. This matches the architecture documented in TECHNICAL_DECISIONS.md.

6. **Editor window implementation.** The borderless floating `NSPanel` with custom toolbar is correctly implemented and matches the product spec closely. The save/copy/delete flow is clean.

7. **Thorough TECHNICAL_DECISIONS.md.** This document is unusually detailed about what was tried, what failed, and why. It will save future agents significant debugging time. The failed approaches section is particularly valuable.

8. **Inline text editing with deferred focus.** The decision to defer `makeFirstResponder` to the next run loop (`AnnotationCanvas.swift` L735-744) to avoid AppKit layout re-entrancy is correct and well-documented in TECHNICAL_DECISIONS.md.

---

## UX Recommendations

### Capture-to-Clipboard Speed

The current critical path: hotkey → region select → tool button or keyboard shortcut → draw/click → type note → Enter → tool button again → draw/click → type note → Enter → Copy for LLM button (or Cmd+C). For 2 annotations, that's approximately: 1 keypress + 1 drag + 1 click + 1 type + 1 Enter + 1 click + 1 drag + 1 click + 1 type + 1 Enter + 1 click/keypress = **11 interactions**.

The freehand tool (which creates numbered pins on single click) must be armed before each use. The tool de-arms after placement. This adds one click per annotation.

macshot comparison: hotkey → select → draw tool stays armed → annotate → annotate → Cmd+C. ~7 interactions for 2 annotations.

### Menu Bar Information Hierarchy

Current menu order: Setup (conditional) → Issue (conditional) → Capture now / Copy latest / Recent captures → Prompt settings / General settings / Hotkey → About → Quit.

Frequency ranking: Capture (every use) > Copy latest (frequent) > Settings (occasional) > Recent captures (occasional) > About (rare) > Quit (rare).

The current order is reasonable. However, settings items take up 3 rows in the main menu. These should be a single "Preferences..." item that opens the settings panel, matching macOS conventions.

### Annotation UX for the LLM Use Case

The current tool palette (freehand, arrow, circle) is appropriate for the LLM use case. However:
- The freehand tool serves double duty as the "pin drop" tool (single click) and the scribble tool (drag). This is undiscoverable — new users won't know they can single-click to place a numbered pin.
- There's no visual distinction between the pin/badge tool and the freehand drawing tool, because they're the same tool.
- For the LLM use case, the most common annotation is "point at something and write a note." That's a single-click pin drop. Making this the default (no tool arming needed) would reduce friction significantly.

### Editor Window Ergonomics

- The editor centers on screen (`EditorPanel` calls `.center()` at L49). This means it may cover the user's running app. For a "look at my app, annotate, paste" workflow, side-by-side would be better.
- The editor resizes to fit the captured image (up to 80% of screen), which is good.
- The toolbar is at the top. For annotation, the user's attention is on the image. Top toolbar is correct (matches Apple Markup).

### Discoverability and Learnability

- A new user clicking the menu bar icon sees a menu that looks custom (not native).
- "Capture now" is the primary action — good placement.
- Keyboard shortcuts 1/2/3 for tools are not documented in the UI. Only discoverable by pressing keys.
- No tooltip or first-use hint explains the annotation workflow.

### Copy/Paste Confidence

- "Copied" toast appears for 2 seconds after Copy for LLM — good visual confirmation.
- The toast doesn't indicate what was copied (text prompt, not image).
- There's no indication of the screenshot path that was embedded.
- For the target use case (paste into Claude Code), the user needs to know that text is on the clipboard, not an image. The toast should say "Prompt copied" or similar.

### Concrete UX Recommendations

| # | Finding | Current Behavior | Recommended Change | Impact | Size |
|---|---------|-----------------|-------------------|--------|------|
| 1 | Menu is not native | Custom NSPanel with SwiftUI content | Replace with `NSMenu`/`NSMenuItem` | Native look and feel, eliminates dismiss bugs | M |
| 2 | Tool de-arms after each annotation | `isToolArmed = false` after mouseUp | Keep tool armed; de-arm on Escape or tool switch | ~50% fewer clicks for multi-annotation captures | XS |
| 3 | No default tool armed on editor open | User must click a tool button to start annotating | Auto-arm freehand (pin) tool when editor opens | One fewer click to start annotating | XS |
| 4 | Three settings rows in menu | Prompt settings, General settings, Hotkey each get a row | Single "Preferences..." row that opens settings panel | Matches macOS convention, shorter menu | XS |
| 5 | Toast says "Copied" | Generic "Copied" text | "Prompt copied to clipboard" | User knows what's on clipboard | XS |
| 6 | No first-run guidance | User must fail a capture to discover permission issues | Show Screen Recording status row in menu when not authorized | Prevents confusion on first use | S |
| 7 | Keyboard shortcuts undiscoverable | 1/2/3 switch tools, Cmd+Z undo, no UI indication | Add keyboard shortcut hints to toolbar button tooltips | Faster tool switching for power users | XS |
| 8 | No pin-drop tool distinction | Freehand tool handles both scribble and single-click pin | Rename freehand icon/tooltip to "Pin & Draw" or add separate pin tool | Clarifies the most common annotation action | XS |
| 9 | Editor always centers on screen | `panel.center()` on open | Position editor to the side of the captured region or on the opposite half of the screen | Keeps user's app visible for reference | S |
| 10 | Cmd+C hint missing | No visual indication that Cmd+C copies for LLM | Add "(⌘C)" suffix to "Copy for LLM" button label | Discoverability for the primary action | XS |

---

## Recommended Ticket Sequence

### Structural Foundation (do first)

| # | Title | Type | Size | Rationale |
|---|-------|------|------|-----------|
| 1 | Replace custom menu panel with native `NSMenu` | Infrastructure | M | Eliminates ~400 lines of fragile custom code, makes menu native, removes dismiss bugs. Blocks nothing but de-risks everything. |
| 2 | Extract `PromptBuilder` from `Config.swift` into its own file | Infrastructure | XS | One file move + import update. Reduces confusion when agents edit prompt logic. |
| 3 | Rename `PromptSettingsView.swift` to `SettingsView.swift` | Infrastructure | XS | File rename only. Matches actual content. |

### Spec Compliance (do second)

| # | Title | Type | Size | Rationale |
|---|-------|------|------|-----------|
| 4 | Add Screen Recording status to menu when not authorized | Feature | S | First-run UX gap. Show a row with "Screen Recording: Enable in Settings" when `CGPreflightScreenCaptureAccess()` returns false. |
| 5 | Keep annotation tools armed after placement | Feature | XS | Change `isToolArmed = false` to stay armed. De-arm on Escape, close, or explicit tool switch. |
| 6 | Auto-arm freehand tool when editor opens | Feature | XS | Set `canvas.isToolArmed = true` and `canvas.currentTool = .freehand` after editor setup. |
| 7 | Consolidate settings menu items into single "Preferences..." | Polish | XS | Replace 3 settings rows with 1 "Preferences..." row. Native macOS convention. |

### Polish (do alongside features)

| # | Title | Type | Size | Rationale |
|---|-------|------|------|-----------|
| 8 | Change toast from "Copied" to "Prompt copied" | Polish | XS | One string change. |
| 9 | Add keyboard shortcut hints to toolbar tooltips | Polish | XS | Set `.toolTip` on toolbar buttons. |
| 10 | Add "(⌘C)" to Copy for LLM button label | Polish | XS | One string change. |
| 11 | Move hardcoded colors to `Constants.swift` | Polish | XS | Consolidate toolbar and menu colors. |
| 12 | Replace `print()` error logging with `os.Logger` | Polish | XS | ~5 call sites in CaptureStore. |

### Story: Split AppDelegate (after menu refactor)

| # | Title | Type | Size | Rationale |
|---|-------|------|------|-----------|
| 13 | Story: Reduce AppDelegate to orchestration only | Infrastructure | M | After native menu lands (removes ~200 lines), extract permission/identity handling and alert presentation. Target: AppDelegate under 400 lines. |

### Backlog (nice to have)

| # | Title | Type | Size | Rationale |
|---|-------|------|------|-----------|
| 14 | Position editor window beside captured region | Feature | S | Better side-by-side workflow. Requires knowing the capture region coordinates. |
| 15 | Merge `CLAUDE.md` and `AGENTS.md` | Infrastructure | XS | Reduce duplication and drift risk. |
| 16 | Add annotation tool protocol for extensibility | Feature | M | Only when tool #4 is imminent. Not needed for v1. |
