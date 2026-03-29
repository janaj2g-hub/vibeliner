# Vibeliner — Technical Decisions

Log of architectural decisions and failed approaches. Claude Code, Codex, and future LLMs should read this before making product or stability changes.

---

## Decisions

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

### 2026-03-28: Treat Vibeliner as an accessory app by default, but temporarily promote it to a regular app for interactive OS flows
**Decision:** The app still launches as a menu bar accessory (`LSUIElement` + accessory activation policy), but it now promotes itself to a regular active app while interactive OS-owned flows are happening:
- Screen Recording permission prompt
- native capture invocation
- editor window presentation
- prompt settings panel presentation

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
- Before permission prompts, capture, editor presentation, or settings presentation, the app switches to `.regular` and activates.
- When those flows end, the app drops back to `.accessory`.
- The editor panel is now a borderless floating panel, but no longer a non-activating panel.

**Why this matters for future LLMs:** If native macOS UI starts failing mysteriously from the menu bar again, check activation policy and responder state first. For v1, "behave like a menu bar app all the time" is less important than "be a well-behaved active macOS app during interactive OS handoff."

**Trade-off:** During active capture/editor/settings flows, the app may behave more like a normal app than a purely invisible menu bar extra. This is intentional. Stability and OS compatibility won over absolute background purity.

**Revisit when:** We have strong evidence that macOS no longer requires this promotion pattern for `screencapture`, or if we migrate to a different capture technology.

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
