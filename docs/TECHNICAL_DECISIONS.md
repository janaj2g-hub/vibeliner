# Vibeliner — Technical Decisions

Log of architectural decisions and failed approaches. Claude Code, Codex, and future LLMs should read this before making product or stability changes.

---

## Decisions

### 2026-03-30: Replace custom NSPanel menu with native NSMenu
**Decision:** The menu bar dropdown is now a standard `NSMenu` with `NSMenuItem` items and `NSMenuDelegate` for dynamic content. The custom `MenuPanel` (NSPanel subclass) and `MenuBarPopover` (SwiftUI view) have been deleted.

**Why:** The codebase audit identified the custom menu panel as the #1 fragile area in the codebase. It required ~200 lines of custom dismiss logic (local and global event monitors with geometry-based hit testing), ~100 lines of panel construction (NSHostingController, NSVisualEffectView, corner radius, positioning), and had a documented history of interaction regressions (see "Dismissing the custom menu panel based on event window identity alone" in Failed Approaches). Native `NSMenu` handles all of this automatically.

**What was removed:**
- `MenuBarPopover.swift` (286 lines) — SwiftUI menu content view
- `MenuPanel` private NSPanel subclass in AppDelegate
- All panel construction, positioning, and sizing code
- Local and global event monitors for dismiss with geometry-based hit testing
- `AppSetupSummary` struct and `ObservableObject` conformance on `AppState` (only consumed by the deleted SwiftUI menu)

**What replaced it:**
- `buildMenu() -> NSMenu` with static items: Capture Now, Preferences..., About, Quit
- `NSMenuDelegate.menuNeedsUpdate(_:)` for dynamic content: Recent Captures submenu and Screen Recording advisory status
- Tagged dynamic items that are stripped and rebuilt on each menu open

**Net impact:** ~500 lines removed, ~80 lines of NSMenu construction added. The menu now looks and behaves like a native macOS status menu.

**Why this matters for future LLMs:** Do not reintroduce a custom panel for the menu bar dropdown. The native `NSMenu` pattern handles dismiss, keyboard navigation, accessibility, and appearance automatically. If dynamic content needs to go beyond what `NSMenuItem` can display, consider using `NSMenuItem.view` for custom views inside individual items rather than replacing the entire menu with a custom panel.

**Revisit when:** The menu needs rich interactive content (e.g., inline capture preview, drag-and-drop) that cannot be expressed as `NSMenuItem` items or custom views within them.

### 2026-03-29: Always copy the built app into a repo-local `dist` folder after every app build
**Decision:** The shared `Vibeliner` scheme now includes a build post-action that copies the final built bundle into `dist/Vibeliner.app` inside the repo on every successful app build.

**Why:** Running Vibeliner outside Xcode is important for testing menu bar behavior, permission prompts, and general macOS integration. The default Xcode output lives in DerivedData, which is correct for Xcode but inconvenient for normal use and confusing for non-Xcode workflows. The user wanted a repo-local app bundle that is always refreshed by the build itself, without requiring a manual terminal copy step after every LLM-driven implementation pass.

This solves a real workflow problem:
- LLM runs already build before handing work back.
- The user should be able to open a stable repo-local `.app` directly from Finder.
- We should not require "find DerivedData" or "run `cp -R ...`" after every push or verification pass.

**What changed:**
- The shared `Vibeliner` scheme now has a `Copy App To Repo Dist` build post-action.
- The script copies `$(TARGET_BUILD_DIR)/$(FULL_PRODUCT_NAME)` to `$(SRCROOT)/dist/$(FULL_PRODUCT_NAME)` using `ditto`.
- After copying, the script re-signs the repo-local bundle so `dist/Vibeliner.app` is launchable outside Xcode.
- The destination is recreated on each build so the repo-local app reflects the latest successful build.
- The script runs after the build completes, so the automation works whether the build is started from Xcode or `xcodebuild` without racing the final packaging and signing steps.

**Source-control contract:** `dist/` is a local convenience artifact, not source code. It is intentionally ignored in `.gitignore` so normal commits and GitHub pushes do not pick up the built `.app` bundle. Future LLMs should not remove this ignore rule unless the product deliberately decides to ship checked-in binaries.

**Trade-off:** Builds now perform one additional copy step, which slightly increases build time and writes a large local bundle into the repo workspace. This is acceptable because the main benefit is predictable app launching outside Xcode.

**Known limitation:** This automation depends on the shared `Vibeliner` scheme. If someone builds the raw target without using the shared scheme, `dist/Vibeliner.app` will not refresh.

**Important behavior note:** Xcode's Run button still launches the DerivedData app bundle, not `dist/Vibeliner.app`. The repo-local `dist` app is for manual launch outside Xcode after the build completes.

**Why this matters for future LLMs:** If you are debugging "works in Xcode, behaves differently outside Xcode," use `dist/Vibeliner.app` as the canonical local app bundle for manual smoke testing. Do not assume the user wants to hunt through DerivedData.

**Revisit when:** The project adopts a dedicated packaging/release process or a separate staging app path that replaces `dist/`.

### 2026-03-28: Keep native macOS capture UX, but switch to file-based `screencapture -i`
**Decision:** Vibeliner still uses the `screencapture` CLI for v1 region selection, but the capture pipeline now writes directly to a temporary file and loads that file into the app. We do not use clipboard handoff for the main capture path.

**Why:** The product goal is still "native macOS capture UX with minimal custom code." `screencapture` provides the system region-selection interaction without requiring a custom overlay or ScreenCaptureKit migration. During the stability pass we found that the product's real export contract depends on having a real file-backed screenshot early in the pipeline:
- Save and Copy for LLM must produce a real capture folder.
- Prompt generation must reference an actual screenshot path.
- Export behavior must be deterministic even when clipboard state changes.
- The app must distinguish "user cancelled selection" from "capture failed."

**What changed:**
- `CaptureManager` now shells out to `/usr/sbin/screencapture -i -x <tempfile>`.
- The code waits for a file to exist, loads it as `NSImage`, and then treats that as the source image for the editor/export flow.
- We no longer treat "no image returned" as a single ambiguous state. Capture now returns a typed result: success, cancelled, or failure.

**Trade-off:** We keep the simplicity and native UX of `screencapture`, but we accept that Vibeliner has less control over the selection flow than a custom capture stack would provide.

**Revisit when:** We need custom selection affordances, multiple regions, live dimension overlays, or tighter control over multi-display behavior.

### 2026-03-28: Treat Vibeliner as an accessory app by default, but temporarily promote it to a regular app only for Vibeliner-owned windows
**Decision:** The app still launches as a menu bar accessory (`LSUIElement` + accessory activation policy), but it only promotes itself to a regular active app when it needs to present Vibeliner-owned UI:
- editor window presentation
- prompt settings / general settings presentation
- user-facing alerts that require an app-modal response

It returns to accessory mode once those flows are finished.

**Why:** The earlier implementation kept the app in accessory/non-activating mode all the time, then tried to launch native capture and editing from that context. That was fragile. The strongest symptom was capture failing with:

`screencapture stderr: could not create image from rect`

The old app lifecycle had several compounding problems:
- the app forcibly activated itself on launch even though it was meant to behave like a polite menu bar utility
- capture was launched from a pure accessory state with no explicit readiness model
- the editor used a `.nonactivatingPanel`, which made focus and responder behavior more fragile than necessary
- setup and permission state were invisible unless the developer inspected console logs

**What changed:**
- `AppDelegate` now tracks interactive sessions with `beginInteractiveSession()` / `endInteractiveSession()`.
- The app stays accessory by default for normal menu bar behavior.
- Native `screencapture` selection now starts from the accessory/menu-bar state instead of forcing a foreground regular-app transition first.
- The app switches to `.regular` only after a real capture succeeds and it needs to present the editor, or when it needs to present settings / alerts.
- When those Vibeliner-owned flows end, the app drops back to `.accessory`.
- The editor panel is now a borderless floating panel, but no longer a non-activating panel.

**Why this matters for future LLMs:** If native macOS UI starts failing mysteriously from the menu bar again, check activation policy and responder state first. For v1, the key distinction is: Vibeliner-owned windows may need regular-app activation, but Apple-owned `screencapture` selection should not be preemptively wrapped in extra activation-policy churn unless the real capture flow proves it is necessary.

**Trade-off:** During active capture/editor/settings flows, the app may behave more like a normal app than a purely invisible menu bar extra. This is intentional. Stability and OS compatibility won over absolute background purity.

**Revisit when:** We have strong evidence that `screencapture` itself requires a different lifecycle contract, or if we migrate to a different capture technology.

### 2026-03-28: Make setup/readiness explicit and user-visible instead of console-driven
**Decision:** First-run and recovery state are now first-class app state, not side effects. The menu bar popover shows:
- Screen Recording permission status
- captures folder status
- whether the app is ready to capture
- the latest user-facing issue, if any

**Why:** The app previously felt broken on clean install because several required conditions were only implied:
- `~/.vibeliner` and the captures directory might not exist yet
- the configured save directory might be invalid or unwritable
- Screen Recording might be missing
- capture failures only showed up in console output
- "Open captures folder" could silently do nothing

That created a "works for the developer, feels broken for a user" problem.

**What changed:**
- `CaptureStore.prepareSaveDirectory(autoRepair:)` now creates directories when safe, checks that the save path is actually a directory, and verifies writability with a probe file.
- `CaptureStore.openCapturesFolder()` now shares that same validation path and reveals the folder in Finder.
- `AppState` builds a `setupSummary` from Screen Recording status plus storage status.
- `MenuBarPopover` renders setup cards and issue cards from shared app state.
- Errors now show both in the popover and, for important failures, in alerts with remediation text.

**Trade-off:** There is more explicit state in `AppDelegate`, but the product is much more diagnosable and deterministic.

**Revisit when:** Settings evolve into a larger preferences surface and setup state deserves a dedicated controller/service.

### 2026-03-29: Use one explicit Screen Recording permission state model, but keep it advisory
**Decision:** Vibeliner still keeps one shared `ScreenRecordingPermissionState` for setup and user-facing diagnosis, but it is advisory state only. It must not be treated as the final authority for whether a live `screencapture` attempt is allowed to run.

**Why:** The previous implementation mixed:
- `CGPreflightScreenCaptureAccess()` for setup readiness
- direct request attempts in capture gating
- stderr heuristics in `CaptureManager`
- separate issue titles and remediation strings

That made it easy for the setup card, hotkey flow, and failure alerts to disagree about what was wrong. The follow-up lesson from `VIB-63` was that the shared model was useful, but we initially gave it too much power.

**What changed:**
- `ScreenRecordingPermissionState` is now the source of truth for Screen Recording state.
- `AppState.makeSetupSummary(...)` now derives setup readiness from that model.
- `ensureReadyForCapture()` now only hard-blocks on storage failure.
- The live capture path may refresh advisory Screen Recording state for the menu, but it does not use that state as a pre-capture veto.
- `CaptureManager.classifyFailure(...)` may map actual `screencapture` stderr back into the shared permission state when the failure surface truly supports that diagnosis.

**Trade-off:** The model is intentionally simpler than the earlier richer heuristic version. We give up some eager explanatory copy in exchange for fewer false positives and less settings-loop churn.

**What we learned after shipping it:** The shared state model is helpful for setup UI, but it cannot explain away the child-process capture pipeline by itself. `CGPreflightScreenCaptureAccess()` only tells us whether the current process appears to have access at that moment. It does not replace the real outcome of `/usr/sbin/screencapture -i -x <file>`, and it should not be used to manufacture richer narratives like "wrong app copy" before a real blocked capture proves that story.

**Revisit when:** We add a dedicated permissions coordinator or learn a more reliable system signal for distinguishing stale-process vs. wrong-bundle authorization.

### 2026-03-29: Treat `screencapture` results and file materialization as the real capture authority
**Decision:** For v1, the real capture authority is the outcome of the `screencapture` child process plus the resulting screenshot file. Setup state is advisory; capture state is authoritative.

**Why:** `VIB-57` drifted toward a permission-state-first architecture. That was the wrong mental model for this product. Vibeliner does not perform the protected screen capture itself. It shells out to Apple’s `screencapture` tool, which owns:
- the native crosshair selection UI
- the actual screen-read operation
- the file write that Vibeliner later loads

That means future LLMs should treat the capture pipeline in this order:
1. launch `screencapture`
2. wait for the tool to exit
3. wait briefly for the output file to materialize
4. classify from exit code, stderr, and file state

Not in this order:
1. run `CGPreflightScreenCaptureAccess()`
2. infer an exact cause
3. gate capture before the real tool runs

**What changed:**
- `CaptureManager` no longer uses `CGPreflightScreenCaptureAccess()` to classify post-selection failures.
- `CaptureManager` waits briefly for delayed file materialization before deciding the capture failed.
- `could not create image from rect` is treated as a real capture failure, not silently collapsed into setup-state copy.
- The app remains in accessory/menu-bar mode during the native selection handoff and activates only when Vibeliner-owned UI needs to appear.
- Blocked-capture UX is derived from real capture outcomes, while setup UI stays compact and advisory.

**MacShot comparison:** MacShot is useful for onboarding tone and for seeing one way a polished menu bar screenshot app behaves, but it is not a drop-in capture reference for v1. MacShot uses ScreenCaptureKit plus its own overlay-selection stack. Vibeliner intentionally stays on file-based `screencapture -i`, so the correct ownership boundary is different. Future LLMs should study MacShot’s permission/onboarding posture, not copy its capture implementation or assume its lifecycle proves how `screencapture` should behave.

**Why this matters for future LLMs:** Do not reintroduce the category error that cost time here. A developer account or cleaned-up signing can stabilize app identity and TCC, but it is not the architectural explanation for the v1 bug. The right architecture is still "advisory setup, authoritative capture result."

**Revisit when:** Vibeliner stops using `screencapture` for v1 capture or introduces its own capture overlay.

### 2026-03-28: Centralize prompt generation and define two explicit screenshot-path contracts
**Decision:** All prompt generation is now centralized in `PromptBuilder`. There are two deliberately different outputs:

1. Saved `prompt.md`
   Uses a folder-relative screenshot reference: `./screenshot.png`

2. Clipboard "Copy for LLM" prompt
   Uses an absolute screenshot path so the prompt still works when pasted from an arbitrary Claude Code or Cursor working directory

**Why:** Before the stability pass:
- prompt generation logic existed in multiple places
- `Copy for LLM` could generate prompt text independently of what was written to `prompt.md`
- preamble settings were stored literally, but there was no shared injection rule for screenshot paths
- saved/exported behavior was already drifting

This is exactly the kind of product contract drift that future LLMs will accidentally worsen unless the rules are explicit.

**What changed:**
- `PromptBuilder` is the single source of truth.
- It introduces a supported token: `{{SCREENSHOT_PATH}}`
- Config migration normalizes older preambles that hardcoded `./screenshot.png`
- If the token is omitted, Vibeliner automatically appends a separate screenshot line so path insertion is never magical but still safe
- `CaptureStore.save` and `CaptureStore.update` both write prompts via `PromptBuilder`
- `CaptureStore.clipboardPrompt(for:)` derives the clipboard-safe version from the saved prompt
- CLI prompt-copy behavior now uses the same clipboard contract as the app

**Why this matters for future LLMs:** If you touch prompt generation, do not reintroduce "one format for save, another format for copy, and a third format in CLI." The current design intentionally keeps one saved source of truth and derives the clipboard-safe variant from it.

**Trade-off:** The product now has slightly more explicit semantics around prompt templates, but the behavior is understandable, documented, and testable.

**Revisit when:** We support true batch exports, multiple screenshot references in one prompt, or other downstream tools with richer attachment semantics.

### 2026-03-28: Separate capture cancellation from actual capture failure
**Decision:** Capture now returns `CaptureOutcome.success`, `.cancelled`, or `.failure(CaptureFailure)`.

**Why:** The old pipeline returned `nil` for all non-success outcomes, which collapsed together:
- user hit Escape or cancelled region selection
- permission problems
- lifecycle/activation problems
- output file missing
- output file unreadable

That made it impossible to produce OS-friendly behavior. Cancellation should feel harmless; actual failures should be visible and actionable.

**What changed:**
- `CaptureManager` classifies stderr and file-output conditions
- `could not create image from rect` is treated as a real failure, not a cancel
- permission-related errors surface Screen Recording remediation
- no-file/no-stderr exits are treated as cancellation
- `AppDelegate` handles each outcome differently:
  - success -> open editor
  - cancelled -> quietly end the session
  - failure -> surface user-facing remediation

**Trade-off:** Slightly more capture-specific error logic, but much better UX and much easier future debugging.

### 2026-03-28: Keep the editor visually tool-like, but make its focus behavior more macOS-friendly
**Decision:** The editor remains a borderless floating `NSPanel`, but the implementation now prioritizes reliable focus and responder behavior over "never activate anything."

**Why:** The vision still calls for a lightweight, markup-like editor. The problem was not the borderless tool-window aesthetic; it was the combination of:
- non-activating panel behavior
- synchronous responder swaps
- implicit save/copy behavior with console-only failures

**What changed:**
- The editor panel is still borderless and floating, preserving the product feel.
- Save, Copy for LLM, and close-all-autosave now run through one save path.
- Save failures are routed back to shared user-facing app error handling instead of `print`.
- `Cmd+C` still routes to Copy for LLM when inline text is not being edited.
- The X button still auto-saves then closes, but only if save succeeds.

**Trade-off:** Slightly more editor-controller plumbing, but fewer fragile ordering assumptions.

### 2026-03-28: Defer inline note focus/finalization to the next run loop to avoid AppKit layout re-entrancy
**Decision:** Inline note field presentation and some note-finalization work are deferred asynchronously on the main queue instead of happening synchronously during mouse/editing callbacks.

**Why:** The app emitted:

`It's not legal to call -layoutSubtreeIfNeeded on a view which is already being laid out.`

The most suspicious pattern was synchronous creation/removal of `NSTextField` subviews combined with immediate `makeFirstResponder` calls while AppKit was already resolving layout and responder updates.

**What changed:**
- Newly created inline note fields are shown on the next main-queue turn
- `makeFirstResponder` for the inline field is deferred
- `controlTextDidEndEditing` now finalizes asynchronously instead of immediately re-entering view mutation

**Trade-off:** The note field opens one run-loop turn later, which is not perceptible to the user but is safer for AppKit.

**Revisit when:** If the warning still appears in manual UI testing, the next place to inspect is any remaining responder churn during mouse events or menu-driven edit actions.

### 2026-03-28: Make the captures folder a real product dependency, not an incidental side effect
**Decision:** `~/.vibeliner` and the configured captures directory are now treated as required runtime infrastructure. The app proactively repairs them on launch when safe.

**Why:** The product flow assumes a saved folder structure exists, but the original implementation only created folders opportunistically during save. That made first-run actions like "Open captures folder" fail or no-op, and it made the app feel incomplete outside Xcode.

**What changed:**
- launch-time storage bootstrap
- writable-directory validation
- automatic creation of missing default directories
- shared error path when the configured directory is invalid or points to a file

**Why this matters for future LLMs:** Any feature that depends on capture persistence should go through `CaptureStore` rather than ad hoc `FileManager` calls. The bootstrap/validation behavior is part of the product now.

---

## Failed approaches

### 2026-03-29: Copying `dist/Vibeliner.app` from a target build phase
**Ticket / workstream:** Local app packaging workflow

**Approach:** Add a shell-script build phase directly to the `Vibeliner` target that copied `$(TARGET_BUILD_DIR)/$(FULL_PRODUCT_NAME)` into `dist/`.

**Failure:** The script could run before the final app bundle was fully packaged and signed, which made the repo-local bundle stale or incomplete. It also forced a target-level script-sandbox exception just to write the nested `.app` bundle into the repo.

**Lesson:** For repo-local app packaging, copy from a scheme post-action that runs after the final build output exists. Do not assume a target build phase sees the finished app product.

### 2026-03-28: Treating every non-success capture as "cancelled"
**Ticket / workstream:** Product-stability and OS-integration hardening

**Approach:** The original code returned `nil` from capture for any non-success case, printed stderr to console, and otherwise let the UI proceed without explicit recovery state.

**Failure:** This hid the difference between:
- user cancellation
- permission problems
- broken app activation/lifecycle
- failed file output

As a result, the product looked broken in normal use and only explained itself in Xcode logs.

**Lesson:** Native OS handoff points need typed results and user-facing remediation. Console-driven UX is not acceptable for core workflow failures.

### 2026-03-28: Keeping the app purely accessory/non-activating during interactive capture and edit flows
**Ticket / workstream:** Product-stability and OS-integration hardening

**Approach:** Launch as an accessory app, keep the editor as a non-activating panel, and call `screencapture` from that context.

**Failure:** This produced fragile focus/activation behavior and appears to have contributed to the `could not create image from rect` failure mode.

**Lesson:** For v1, Vibeliner should be accessory by default, but it must temporarily behave like a normal active app when macOS is handing control to or from interactive system UI.

### 2026-03-29: Escalating Screen Recording state too early in the setup and hotkey flow
**Ticket / workstream:** VIB-57 Screen Recording permission-flow cleanup

**Approach:** Use the new `ScreenRecordingPermissionState` model not just for diagnosis, but also for pre-capture gating and the "return from Settings" refresh path. This included:
- converting a plain return from System Settings into `afterPermissionRequestAttempt()`
- preserving guessed `relaunchRequired` / `appCopyMismatch` states in `ensureReadyForCapture()`
- treating `could not create image from rect` as a permission-style error even after the native crosshair flow had started

**Failure:** This overfit the model to a workflow it could not reliably observe. The app started doing all of the following:
- reopening Settings from the hotkey path even when Screen Recording was already enabled
- showing permission-style remediation after a real post-selection capture failure
- conflating "user returned from Settings" with "we proved this running app copy is blocked after a grant"

That made the UX look coherent on paper, but wrong in practice. It also delayed discovery of the real underlying capture failure by re-routing users into permission remediation that no longer matched reality.

**Lesson:** Keep the permission state model diagnostic-first. The app may use `CGPreflightScreenCaptureAccess()` to inform setup UI and blocked-state copy, but only an actual failed capture attempt should escalate to relaunch/app-copy mismatch guidance. Do not let heuristic states become a hard pre-capture gate.

### 2026-03-29: Dismissing the custom menu panel based on event window identity alone
**Ticket / workstream:** Post-VIB-57 menu regression repair

**Approach:** The custom menu panel used local and global mouse monitors, and the local dismiss logic closed the panel whenever the incoming mouse event's window was not `menuPanel`.

**Failure:** That assumption was too weak for the custom panel + hosted SwiftUI view stack. Some clicks that should have been treated as in-panel interactions were effectively treated as outside clicks, which caused:
- row actions to die before the button action completed
- Quit and other menu actions to appear broken
- hover feedback to feel inconsistent or disappear

The panel looked present, but user interaction inside it was no longer trustworthy.

**Lesson:** For custom menu-panel dismissal, use real screen-space hit testing against the panel frame, not window-identity shortcuts. If the menu is a custom `NSPanel` rather than a native `NSMenu`, outside-click handling must be explicit and geometry-based.

### 2026-03-29: Screen Recording failures can come from app identity, not just permission state
**Ticket / workstream:** Capture reliability and macOS TCC debugging

**Context:** The hotkey successfully switched to the native region-selection crosshairs, but release still ended in a Screen Recording-style failure after the user completed the selection. This proved that the earliest permission gate was not the whole problem.

**What we observed:**
- `screencapture` launched normally and displayed the crosshairs.
- The actual failure happened after region selection.
- System logs showed:
  - `The user declined TCCs for application, window, display capture`
  - `capture error could not create image from rect`
- The app was initially ad hoc signed, which showed up as `Signature=adhoc` and `TeamIdentifier=not set`.
- The repo-local bundle was therefore not a stable TCC identity across rebuilds.

**Why this mattered:** Screen Recording permission is tied to app identity, not just the visible bundle name. A menu bar app can appear to “have permission” in System Settings while still failing at capture time if macOS sees the current bundle as a different signing identity or a stale local build product.

**What changed during the investigation:**
- The app bundle identifier was aligned between:
  - `PRODUCT_BUNDLE_IDENTIFIER` in the Xcode project
  - `CFBundleIdentifier` in `Info.plist`
- The repo-local bundle was rebuilt as an Apple Development-signed app instead of ad hoc signed.
- Old Screen Recording approval records were reset for both the previous bundle id and the new one so the next launch would re-register the correct identity.

**Why this matters for future LLMs:** If Screen Recording still fails after the user grants permission, do not assume the fix is only in permission UI copy. Check the actual codesign identity, bundle identifier, and whether the app copy being launched is the same bundle macOS has approved.

**Trade-off:** This adds one more setup dependency for local testing, but it is the most realistic way to make TCC behavior stable on macOS while keeping the app outside Xcode.

**Revisit when:** We have a fully signed distribution path or a more deterministic local signing setup for the repo-local app bundle.

### 2026-03-29: The capture gate must not manufacture permission states before a real failure
**Ticket / workstream:** VIB-57 Screen Recording permission-flow cleanup

**Context:** The newer `ScreenRecordingPermissionState` model initially got used too early in the capture lifecycle.

**What we observed:**
- The menu and setup UI could show a useful diagnosis.
- But `ensureReadyForCapture()` and the return-from-Settings path were able to turn that diagnosis into a hard pre-capture gate.
- That caused the hotkey to reopen Settings even when the user had already granted access.

**What changed:**
- `notGranted` is now advisory for setup state and should not block the native capture path by itself.
- Only a real capture failure should escalate into more specific blocked-after-grant messaging.
- Returning from Settings now refreshes state instead of inventing `relaunchRequired` / `appCopyMismatch` before the next capture attempt.

**Why this matters for future LLMs:** `CGPreflightScreenCaptureAccess()` is useful for UI state, but it is not enough to replace the actual behavior of `screencapture`. Treat preflight as diagnosis, not final proof.

### 2026-03-29: Screen Recording preflight can stay false even when System Settings shows Vibeliner as enabled
**Ticket / workstream:** Post-VIB-78 capture debugging and live machine verification

**Context:** After the earlier permission-flow cleanup, the app was launched from the repo-local `dist/Vibeliner.app`, macOS System Settings showed `Vibeliner` enabled in Screen & System Audio Recording, and capture still did not work. The menu continued to imply that Screen Recording was missing.

**What actually happened:**
- The machine-level permission was real. The user could see `Vibeliner` enabled in System Settings.
- `CGPreflightScreenCaptureAccess()` still behaved like a false negative for the running process.
- The app had drifted back into treating that preflight result as truth in two places:
  - the capture-readiness path had briefly used it as a hard blocker
  - the menu setup UI still used it to show Screen Recording as unresolved
- That created a misleading product state:
  - the OS said the app was enabled
  - the app UI said permission was missing
  - the real capture path was harder to trust because the menu looked unauthorised before a real attempt

**What changed:**
- `ensureReadyForCapture()` no longer blocks solely because `CGPreflightScreenCaptureAccess()` reports `false`.
- The top-level menu no longer shows a Screen Recording setup row based only on preflight state.
- `CaptureManager` now treats `screencapture` plus screenshot-file materialization as the real authority and logs the full runtime diagnostic summary for permission-like failures.
- If macOS denies the capture while the app still appears enabled, the app now reports a mismatch-style runtime failure instead of collapsing everything into the generic "permission needed" copy.

**Why this worked:** The failing architecture was not "permission is missing." It was "the app trusted advisory preflight too much." Once the app stopped presenting preflight as authoritative and returned control to the real `screencapture` result, capture worked again on the affected machine.

**Why this matters for future LLMs:** If the user shows you System Settings with Vibeliner enabled, believe that evidence. Do not re-explain Screen Recording basics or push the user back into permission setup loops unless a fresh `screencapture` attempt proves macOS is still blocking the capture. UI setup state and live capture authority are different things.

### 2026-03-29: The custom menu must dismiss on geometry, not window identity
**Ticket / workstream:** Post-VIB-57 menu regression repair

**Context:** After several menu refactors, the dropdown started behaving like buttons were dead and hover states were broken.

**Root cause:** The custom `NSPanel` dismissal monitor was using a too-simple event-window check. In a hosted SwiftUI/AppKit stack, that caused clicks that should have stayed inside the menu to be treated as outside clicks.

**What changed:**
- The menu now dismisses only when the click is actually outside the menu frame in screen coordinates.
- This restored row actions, hover feedback, and Quit from the menu.

**Why this matters for future LLMs:** When replacing `NSMenu` with a custom `NSPanel`, don't rely on `event.window !== menuPanel` as an outside-click test. Use frame-based hit testing and preserve row interaction first.

### 2026-03-29: The bundle id and plist must always match the signed app
**Ticket / workstream:** Local signing and repo-local app identity cleanup

**Context:** Xcode rebuilt the repo-local app successfully, but emitted a warning because the project bundle id and the Info.plist bundle id were different.

**What changed:**
- `Vibeliner.xcodeproj/project.pbxproj` now uses `com.jongrossman.vibeliner`.
- `Vibeliner/Info.plist` now uses `$(PRODUCT_BUNDLE_IDENTIFIER)` instead of hardcoding a second identifier.
- The repo-local app bundle was rebuilt after the change.

**Why this matters for future LLMs:** Do not leave the plist and target disagreeing about bundle identity. Even if the app launches, the mismatch makes signing and TCC debugging much harder to reason about.

**Revisit when:** We change the developer account or decide to ship under a different bundle namespace.
