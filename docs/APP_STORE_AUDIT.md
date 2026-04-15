# Vibeliner — App Store Compliance Audit

**Date:** 2026-04-15
**Commit:** `0cbc2ee`
**Bundle ID:** `com.vibeliner.app`

## Executive summary

**Assessment: NOT READY — 5 P0 blockers must be resolved before submission.**

Vibeliner currently ships via DMG with hardened runtime + notarization. The Mac App Store requires the **App Sandbox** entitlement, which fundamentally changes how the app accesses the file system. The codebase has **no sandbox support** today — config files are written to hardcoded paths, captures folders use unrestricted `FileManager` access, and the `screencapture` CLI fallback will not function at all under sandbox.

The good news: no private APIs are used, the hotkey mechanism (`NSEvent.addGlobalMonitorForEvents`) is sandbox-compatible with the right entitlement, `CGWindowListCreateImage` works under sandbox with the screen capture entitlement, and the icon set is complete. The required work is primarily **file I/O migration** and **entitlements configuration**.

**Key blockers:**
1. App Sandbox entitlement not enabled
2. Config file path (`~/Library/Application Support/Vibeliner/`) is outside sandbox container
3. Captures folder uses unrestricted `FileManager` access without security-scoped bookmarks
4. `screencapture` CLI fallback (`Process()`) will not work under sandbox
5. Missing `Info.plist` keys: `NSHumanReadableCopyright`, `LSApplicationCategoryType`, usage description strings

---

## 1. Sandbox compatibility

### Findings

#### 1.1 Config file path — BLOCKED

- **File:** `Vibeliner/Config/ConfigManager.swift:59-64`
- **What it does:** Constructs the config path as `~/Library/Application Support/Vibeliner/config.toml` using `FileManager.default.homeDirectoryForCurrentUser`.
- **Why it's incompatible:** Under App Sandbox, the app's `~/Library/Application Support/` maps to `~/Library/Containers/com.vibeliner.app/Data/Library/Application Support/`, not the real home directory. However, `FileManager.default.homeDirectoryForCurrentUser` already returns the container-relative path under sandbox, so **this will silently work** — but the path will change, meaning existing users who migrate from DMG to App Store will lose their config.
- **Suggested fix:** On first sandboxed launch, check the real `~/Library/Application Support/Vibeliner/config.toml` path via a temporary exception or accept that App Store installs start fresh. Document the migration path.

#### 1.2 Legacy config migration — BLOCKED

- **File:** `Vibeliner/Config/ConfigManager.swift:69-71`
- **What it does:** Checks for a legacy config inside the captures folder using `expandingTildeInPath`.
- **Why it's incompatible:** The captures folder is user-selected and outside the sandbox container. Without a security-scoped bookmark, this path is inaccessible on relaunch.
- **Suggested fix:** Remove legacy migration for App Store builds, or only attempt it during a one-time migration flow with an `NSOpenPanel` granting access.

#### 1.3 Config save/load — PARTIAL (works with container remapping)

- **File:** `Vibeliner/Config/ConfigManager.swift:134-145`
- **What it does:** Creates `~/Library/Application Support/Vibeliner/` directory and writes config.toml.
- **Why it's incompatible:** Under sandbox, `FileManager.default.homeDirectoryForCurrentUser` returns the container path, so directory creation and file writes will work. The path just moves.
- **Suggested fix:** No code change needed — sandbox container remapping handles this. But the path display in UI should show the logical path, not the container path.

#### 1.4 Captures base folder — BLOCKED

- **File:** `Vibeliner/Config/ConfigManager.swift:42-44`
- **What it does:** Expands `~/Documents/vibeliner` via `expandingTildeInPath` and returns the absolute path.
- **Why it's incompatible:** `~/Documents/vibeliner` is outside the sandbox container. The app needs `com.apple.security.files.user-selected.read-write` entitlement plus security-scoped bookmarks to persist access across launches.
- **Suggested fix:** Store a security-scoped bookmark when the user selects the folder via `NSOpenPanel`. Resolve the bookmark on launch to regain access.

#### 1.5 Captures folder creation — BLOCKED

- **File:** `Vibeliner/Config/CapturesManager.swift:24-29`
- **What it does:** Creates the base captures directory using `FileManager.default.createDirectory`.
- **Why it's incompatible:** Without a resolved security-scoped bookmark, the app cannot create directories outside its container.
- **Suggested fix:** Wrap in `startAccessingSecurityScopedResource()` / `stopAccessingSecurityScopedResource()` after resolving the stored bookmark.

#### 1.6 Capture subfolder creation — BLOCKED

- **File:** `Vibeliner/Config/CapturesManager.swift:31-37`
- **What it does:** Creates timestamped subfolders inside the captures directory.
- **Why it's incompatible:** Same as 1.5 — requires security-scoped bookmark access.
- **Suggested fix:** Same as 1.5.

#### 1.7 Captures folder listing — BLOCKED

- **File:** `Vibeliner/Config/CapturesManager.swift:68-112`
- **What it does:** Lists contents of the captures folder using `FileManager.contentsOfDirectory`.
- **Why it's incompatible:** Requires active security-scoped resource access.
- **Suggested fix:** Wrap in bookmark access calls.

#### 1.8 Auto-save file writes — BLOCKED

- **File:** `Vibeliner/Output/AutoSaveManager.swift:48-66`
- **What it does:** Writes annotated screenshots and prompt files to the captures folder on a background queue.
- **Why it's incompatible:** Background file writes to a user-selected folder require an active security-scoped bookmark.
- **Suggested fix:** Ensure the security-scoped resource is accessed before dispatching to the background queue.

#### 1.9 Screenshot save — BLOCKED

- **File:** `Vibeliner/Models/CaptureStore.swift:134-143`
- **What it does:** Writes `screenshot.png` to the capture folder via `savePNG(to:)`.
- **Why it's incompatible:** Same as above — user-selected folder outside container.
- **Suggested fix:** Same bookmark access pattern.

#### 1.10 Prompt file save — BLOCKED

- **File:** `Vibeliner/Output/PromptGenerator.swift:111-123`
- **What it does:** Writes `prompt.txt` to the capture folder using atomic write pattern (temp file → move).
- **Why it's incompatible:** Same as above.
- **Suggested fix:** Same bookmark access pattern.

#### 1.11 `screencapture` CLI fallback — BLOCKED (cannot work under sandbox)

- **File:** `Vibeliner/Capture/ScreenCapture.swift:51-79`
- **What it does:** Falls back to `/usr/sbin/screencapture` via `Process()` when `CGWindowListCreateImage` fails.
- **Why it's incompatible:** `Process()` (shell execution) is **categorically blocked** under App Sandbox. There is no entitlement that permits this.
- **Suggested fix:** Remove the `captureWithFallback` method entirely for App Store builds. `CGWindowListCreateImage` with the screen capture entitlement is the only viable capture method.

#### 1.12 Temporary file in fallback — BLOCKED

- **File:** `Vibeliner/Capture/ScreenCapture.swift:52`
- **What it does:** Creates a temp file via `FileManager.default.temporaryDirectory`.
- **Why it's incompatible:** This is actually sandbox-compatible — the temporary directory is container-relative under sandbox. However, the entire fallback method is blocked (see 1.11).
- **Suggested fix:** Moot — remove the fallback entirely.

#### 1.13 NSOpenPanel usage (Settings) — PARTIAL

- **File:** `Vibeliner/Settings/GeneralTabView.swift:171-183`
- **What it does:** Opens `NSOpenPanel` to let the user choose a captures folder. Saves the selected path as a string.
- **Why it's incompatible:** `NSOpenPanel` works under sandbox — it grants a temporary sandbox extension for the selected URL. But without persisting a security-scoped bookmark, the app **loses access on relaunch**.
- **Suggested fix:** After the user selects a folder, create a security-scoped bookmark via `url.bookmarkData(options: .withSecurityScope)` and store it in `UserDefaults` or the config file.

#### 1.14 NSOpenPanel usage (Setup) — PARTIAL

- **File:** `Vibeliner/Setup/SetupWindowController+Actions.swift:154-176`
- **What it does:** Same folder picker as Settings.
- **Why it's incompatible:** Same issue — no bookmark persistence.
- **Suggested fix:** Same as 1.13.

#### 1.15 Open Captures Folder in Finder — BLOCKED

- **File:** `Vibeliner/Popover/RecentCapturesSubmenu.swift:129-131`
- **What it does:** Opens the captures folder in Finder via `NSWorkspace.shared.open(url)`.
- **Why it's incompatible:** `NSWorkspace.shared.open()` is sandbox-compatible for URLs the app has access to. But the captures folder URL must be resolved from a security-scoped bookmark first.
- **Suggested fix:** Resolve bookmark before opening.

#### 1.16 Reveal in Finder — BLOCKED

- **File:** `Vibeliner/Popover/CaptureRowView.swift:131`
- **What it does:** `NSWorkspace.shared.selectFile(...)` to reveal a capture in Finder.
- **Why it's incompatible:** Same — requires active security-scoped bookmark access.
- **Suggested fix:** Same bookmark access pattern.

### Migration effort estimate

- **Files affected:** 8 files (`ConfigManager.swift`, `CapturesManager.swift`, `ScreenCapture.swift`, `AutoSaveManager.swift`, `CaptureStore.swift`, `PromptGenerator.swift`, `GeneralTabView.swift`, `SetupWindowController+Actions.swift`)
- **Additional files touched:** 2 (`RecentCapturesSubmenu.swift`, `CaptureRowView.swift`)
- **Estimated complexity:** **Medium-High.** The core work is:
  1. Add a `BookmarkManager` class to create, persist, and resolve security-scoped bookmarks
  2. Wrap all file I/O to the captures folder in `startAccessingSecurityScopedResource()` / `stop...()`
  3. Remove the `screencapture` CLI fallback
  4. Update both `NSOpenPanel` call sites to persist bookmarks
  5. Handle the case where a stored bookmark becomes stale (folder deleted/moved)

---

## 2. Entitlements analysis

### Current entitlements

- **File:** `Vibeliner/Vibeliner.entitlements:5-6`
- **Current state:** Only one entitlement is declared:
  - `com.apple.security.device.screen-capture` = `true`

### Required entitlements for App Store

| Entitlement | Currently declared | Needed | Notes |
|---|---|---|---|
| `com.apple.security.app-sandbox` | No | **Yes (required)** | Must be `true` for all Mac App Store apps |
| `com.apple.security.device.screen-capture` | Yes | Yes | Already present — allows `CGWindowListCreateImage` |
| `com.apple.security.files.user-selected.read-write` | No | **Yes** | Needed for the captures folder (user picks via `NSOpenPanel`) |
| `com.apple.security.files.bookmarks.app-scope` | No | **Yes** | Needed to persist access to captures folder across launches |
| `com.apple.security.automation.apple-events` | No | No | Not needed — app doesn't use Apple Events |
| `com.apple.security.network.client` | No | No | App has no network access |
| `com.apple.security.temporary-exception.*` | No | **Maybe** | See below |

### Temporary exceptions assessment

**Accessibility (global hotkey):** The app uses `NSEvent.addGlobalMonitorForEvents` which requires Accessibility permission at the OS level but does **not** require a sandbox entitlement. The `kAXTrustedCheckOptionPrompt` API works under sandbox. **No temporary exception needed.**

**Application Support directory:** Under sandbox, `~/Library/Application Support/` is automatically remapped to the container. The config file will just work. **No temporary exception needed.**

**File system access:** The captures folder is user-selected via `NSOpenPanel`, so `com.apple.security.files.user-selected.read-write` + `com.apple.security.files.bookmarks.app-scope` covers this. **No temporary exception needed.**

### Conclusion

No temporary exceptions are needed. This is excellent — temporary exceptions increase App Review scrutiny and risk rejection. The entitlements needed are all standard, well-documented, and commonly approved.

---

## 3. Screen capture API review

### CGWindowListCreateImage

- **File:** `Vibeliner/Capture/ScreenCapture.swift:32-37`
- **Usage:** `CGWindowListCreateImage(cgRect, .optionOnScreenBelowWindow, kCGNullWindowID, [.bestResolution])`
- **Sandbox compatibility:** **Works under sandbox** with the `com.apple.security.device.screen-capture` entitlement, which is already declared.
- **macOS permission:** Requires Screen Recording permission at the OS level. The app correctly checks via `CGPreflightScreenCaptureAccess()` and prompts via `CGRequestScreenCaptureAccess()` (lines 9-10).

### Privacy manifest

- **File:** `Vibeliner/PrivacyInfo.xcprivacy`
- **Current state:** Declares `NSPrivacyAccessedAPICategoryScreenCapture` with reason code `C617.1`.
- **Assessment:** The privacy manifest is present and correctly structured. Apple requires this for apps using screen capture APIs. The reason code `C617.1` corresponds to "The app uses the screen capture API to capture the user's screen for annotation or editing purposes," which matches Vibeliner's use case.
- **Verdict:** Sufficient for App Store submission.

### `screencapture` CLI fallback

- **File:** `Vibeliner/Capture/ScreenCapture.swift:51-79`
- **Assessment:** **Will not work under sandbox.** `Process()` is categorically blocked. This fallback must be removed for App Store builds.
- **Risk:** Low — `CGWindowListCreateImage` is the primary path and works reliably. The fallback was a safety net for edge cases; in practice, if `CGWindowListCreateImage` fails, the capture simply fails gracefully (returns `nil`).

### App Review justification

Screen capture apps receive extra scrutiny from App Review. Recommended App Review notes:

> "Vibeliner is a screenshot annotation tool for developers. It captures a user-selected region of the screen (not the full screen or other windows) using CGWindowListCreateImage, then opens an editor where the user annotates the screenshot with numbered markers. The app requires Screen Recording permission, which macOS prompts for at the OS level. The app does not record video, does not capture continuously, and does not transmit screenshots over the network. All captured images are stored locally in a user-chosen folder."

---

## 4. Global hotkey compatibility

### Current implementation

- **File:** `Vibeliner/Hotkey/HotkeyManager.swift:65-87`
- **Mechanism:** `NSEvent.addGlobalMonitorForEvents(matching: .keyDown)` for global monitoring + `NSEvent.addLocalMonitorForEvents(matching: .keyDown)` for in-app monitoring.
- **No Carbon API:** The codebase does **not** use `RegisterEventHotKey` or any Carbon framework imports. The grep for `Carbon` and `RegisterEventHotKey` returned zero results.

### Sandbox compatibility

- **`NSEvent.addGlobalMonitorForEvents`:** **Works under sandbox** but requires that the app has **Accessibility** permission at the OS level (System Settings → Privacy & Security → Accessibility). This is a macOS-level permission, not a sandbox entitlement.
- **`AXIsProcessTrusted()` / `AXIsProcessTrustedWithOptions()`:** These APIs work under sandbox and are used correctly in `HotkeyManager.swift:166-167` and `AppDelegate.swift:57`.
- **No entitlement needed:** There is no sandbox entitlement for Accessibility — it's purely an OS-level permission that the user grants via System Settings.

### App Review notes

The combination of Accessibility + Screen Recording is legitimate and common for screenshot/annotation tools. App Review may ask for justification — include in review notes:

> "Accessibility permission is required for the global capture hotkey (⌘⇧6). Without it, the hotkey only works when Vibeliner is the frontmost app. The app checks Accessibility status during its setup flow and guides the user to System Settings."

---

## 5. Window and UI patterns

### Floating panels

| Window | Level | File | Line | Concern |
|---|---|---|---|---|
| `EditorPanel` | `.floating` | `EditorPanel.swift` | 78 | None — standard for annotation tools |
| `SettingsWindowController` | `.floating` | `SettingsWindowController.swift` | 33 | Acceptable — keeps settings above other windows |
| `TourWindowController` | `.floating` | `TourWindowController.swift` | 60 | Acceptable — tutorial overlay |
| `PopoverWindow` | `.popUpMenu` | `PopoverWindow.swift` | 68 | Acceptable — standard for menu bar popovers |
| `PopoverViewController` (submenu) | `.popUpMenu` | `PopoverViewController.swift` | 182 | Acceptable |
| `CaptureOverlayWindow` | `.screenSaver` | `CaptureOverlayWindow.swift` | 13 | **Potential concern** — see below |

### CaptureOverlayWindow — `.screenSaver` level

- **File:** `Vibeliner/Capture/CaptureOverlayWindow.swift:13`
- **What it does:** The capture overlay uses `.screenSaver` window level to appear above all other windows during region selection.
- **Concern:** `.screenSaver` is a very high window level. App Review might question why an app needs to render above everything. However, this is a standard pattern for screenshot tools — the overlay needs to be above all content so the user can draw a selection rectangle.
- **Risk:** Low. Other App Store screenshot tools use the same pattern.

### LSUIElement (menu bar app)

- **File:** `Vibeliner/Info.plist:27-28`
- **What it does:** `LSUIElement = true` hides the app from the Dock and removes the default menu bar.
- **Concern:** None — this is a well-established pattern for menu bar utilities. Many App Store apps use this (1Password, Bartender, iStat Menus, etc.).

### Borderless panels

- `EditorPanel` uses `.borderless` + `.nonactivatingPanel` — standard for floating annotation editors
- `TourWindowController` uses `.borderless` + `.nonactivatingPanel` — standard for overlay tutorials
- `PopoverWindow` uses `.borderless` + `.nonactivatingPanel` — standard for custom popovers

**Verdict:** All window patterns are standard and should not trigger App Review concerns.

---

## 6. Private API and framework usage

### Private API scan

- **`Selector(("undo:"))` and `Selector(("redo:"))`:** `Vibeliner/App/AppDelegate.swift:93-94` — These use string-based selectors for `undo:` and `redo:`. These are **public** NSResponder selectors, not private API. The string-based `Selector()` syntax is slightly unusual but not problematic. **No concern.**

- **`objc_setAssociatedObject`:** `Vibeliner/Hotkey/HotkeyCapturePanel.swift:61,103` — Used to retain the `HotkeyCapturePanel` instance while a sheet is open. This is a **public Objective-C runtime API** and is commonly used in Swift. **No concern.**

- **`ApplicationServices` import:** `Vibeliner/App/AppDelegate.swift:2` — This framework is public. It's an umbrella framework that includes `AXUIElement` APIs for Accessibility. **No concern.**

### Deprecated API scan

- **`CGWindowListCreateImage`:** `Vibeliner/Capture/ScreenCapture.swift:6-7` — The code has a `@available(macOS, deprecated: 14.0)` annotation, which is a **developer-added** deprecation notice, not an Apple deprecation. `CGWindowListCreateImage` is not officially deprecated by Apple. It's the recommended API for non-ScreenCaptureKit screen capture. **No concern for App Review.**

### Carbon framework usage

- **None.** Zero imports of Carbon or any Carbon API usage. The hotkey system is pure AppKit (`NSEvent` monitors).

### Third-party frameworks

- **None.** The app imports only Apple system frameworks: `AppKit`, `Foundation`, `CoreGraphics`, `CoreText`, `ServiceManagement`, `ApplicationServices`, `ImageIO`. All are standard and permitted.

### Undocumented selectors / method swizzling / dlsym

- **None found.** No `dlsym`, `dlopen`, `NSSelectorFromString` (beyond the `Selector()` calls above which use public selectors), or method swizzling.

**Verdict:** No private API usage. Clean bill of health.

---

## 7. App Review metadata readiness

### Info.plist completeness

- **File:** `Vibeliner/Info.plist`

| Key | Status | Value/Issue |
|---|---|---|
| `CFBundleIdentifier` | Present | `com.vibeliner.app` (via `$(PRODUCT_BUNDLE_IDENTIFIER)`) |
| `CFBundleShortVersionString` | Present | `1.0.0` |
| `CFBundleVersion` | Present | `1` |
| `CFBundleDevelopmentRegion` | Present | `en` |
| `CFBundleIconName` | Present | `AppIcon` |
| `LSUIElement` | Present | `true` |
| `LSMinimumSystemVersion` | Present | `$(MACOSX_DEPLOYMENT_TARGET)` |
| `NSHumanReadableCopyright` | **MISSING** | Required for App Store. Add: `"Copyright © 2026 Vibeliner. All rights reserved."` |
| `LSApplicationCategoryType` | **MISSING** | Required for App Store categorization. Suggested: `public.app-category.developer-tools` or `public.app-category.productivity` |
| `NSScreenCaptureUsageDescription` | **MISSING** | May be needed. Apple may require a usage description string explaining why the app captures the screen. Add: `"Vibeliner captures a region of your screen so you can annotate it and share with AI coding tools."` |
| `NSAccessibilityUsageDescription` | **MISSING** | May not be strictly required in Info.plist (macOS prompts its own dialog), but recommended for completeness. Add: `"Vibeliner needs Accessibility access to detect your capture hotkey when other apps are in the foreground."` |

### Icon set completeness

- **File:** `Vibeliner/Assets.xcassets/AppIcon.appiconset/Contents.json`
- **Status:** Complete for macOS. Includes all required sizes: 16, 32, 128, 256, 512 at 1x and 2x.
- **App Store requirement:** The `icon_512x512@2x.png` (1024×1024 pixels) serves as the App Store icon. **This is present.**
- **Verdict:** Icon set is ready.

### Privacy policy

- **Status:** **NOT PRESENT.** Apple requires a privacy policy URL for all App Store apps.
- **Requirement:** Since Vibeliner collects no user data, has no network access, and stores everything locally, the privacy policy can be simple. But it must exist and be hosted at a public URL.
- **Suggested fix:** Create and host a privacy policy page. Include it in App Store Connect metadata.

### App Review notes

Recommended review notes (for the App Store Connect "App Review Information" → "Notes" field):

> "Vibeliner is a developer tool that captures and annotates screenshots. It requires two macOS permissions:
>
> 1. Screen Recording — to capture a user-selected region of the screen using CGWindowListCreateImage
> 2. Accessibility — to detect the global capture hotkey (⌘⇧6) when other apps are in the foreground
>
> To test: Grant both permissions in System Settings → Privacy & Security. Then press ⌘⇧6 to capture a screen region. The editor opens where you can add annotation markers. Press ⌘C to copy the annotated prompt to your clipboard.
>
> The app stores all data locally. It has no network access and does not transmit any data."

### Age rating

- **Assessment:** 4+ (no objectionable content, no network access, no user-generated content sharing, no in-app purchases).

---

## Prioritized action items

| Priority | Item | Effort | Files | Blocks submission? |
|---|---|---|---|---|
| P0 | Enable App Sandbox entitlement | Small | `Vibeliner.entitlements` | Yes |
| P0 | Add security-scoped bookmark manager | Medium | New `BookmarkManager.swift` + `ConfigManager.swift` | Yes |
| P0 | Wrap all captures folder I/O in bookmark access | Medium | `CapturesManager.swift`, `AutoSaveManager.swift`, `CaptureStore.swift`, `PromptGenerator.swift`, `RecentCapturesSubmenu.swift`, `CaptureRowView.swift` | Yes |
| P0 | Update NSOpenPanel sites to persist bookmarks | Small | `GeneralTabView.swift`, `SetupWindowController+Actions.swift` | Yes |
| P0 | Remove `screencapture` CLI fallback | Small | `ScreenCapture.swift` | Yes |
| P1 | Add missing Info.plist keys | Small | `Info.plist` | Yes (soft — may pass review without, but shouldn't risk it) |
| P1 | Add required entitlements (`files.user-selected`, `files.bookmarks`) | Small | `Vibeliner.entitlements` | Yes |
| P1 | Create and host privacy policy | Small | External (web) | Yes |
| P2 | Add App Review notes in App Store Connect | Small | App Store Connect (not code) | No but strongly recommended |
| P2 | Handle stale bookmarks (folder deleted/moved) | Small | `BookmarkManager.swift` | No but recommended |
| P2 | DMG-to-App-Store config migration strategy | Medium | `ConfigManager.swift` | No but good UX for existing users |
| P3 | Consider ScreenCaptureKit migration | Large | `ScreenCapture.swift` + new permission flow | No — CGWindowListCreateImage works |

---

## Recommended ticket breakdown

### VIB-458B: Enable App Sandbox + entitlements
- Add `com.apple.security.app-sandbox = true` to entitlements
- Add `com.apple.security.files.user-selected.read-write = true`
- Add `com.apple.security.files.bookmarks.app-scope = true`
- Verify existing `com.apple.security.device.screen-capture` still works
- **Estimate:** Small

### VIB-458C: Security-scoped bookmark manager
- Create `BookmarkManager.swift` singleton
- Store bookmark data in `UserDefaults` (sandbox-safe storage)
- API: `saveBookmark(for: URL)`, `resolveBookmark() -> URL?`, `accessScope(_ block: () -> Void)`
- Handle stale bookmark detection and re-prompt
- **Estimate:** Medium

### VIB-458D: Migrate captures folder I/O to bookmark-scoped access
- Update `CapturesManager` to resolve bookmark before all file operations
- Update `AutoSaveManager` to wrap background saves in bookmark access
- Update `CaptureStore.saveImages(to:)` and `CaptureSession.saveAnnotatedImage(_:to:)`
- Update `PromptGenerator.savePromptFile(to:)`
- Update `RecentCapturesSubmenu` and `CaptureRowView` folder/file access
- **Estimate:** Medium

### VIB-458E: Update NSOpenPanel to persist bookmarks
- `GeneralTabView.changeFolderClicked()` — persist bookmark after selection
- `SetupWindowController+Actions.chooseFolder()` — persist bookmark after selection
- Test: verify folder access persists across app relaunch
- **Estimate:** Small

### VIB-458F: Remove screencapture CLI fallback
- Delete `captureWithFallback(rect:)` method from `ScreenCapture.swift`
- Update `captureRegion(rect:on:)` to return `nil` on `CGWindowListCreateImage` failure (no fallback)
- **Estimate:** Small

### VIB-458G: App Store metadata preparation
- Add `NSHumanReadableCopyright` to `Info.plist`
- Add `LSApplicationCategoryType` to `Info.plist`
- Add `NSScreenCaptureUsageDescription` to `Info.plist`
- Add `NSAccessibilityUsageDescription` to `Info.plist`
- Create and host privacy policy
- Prepare App Review notes text
- **Estimate:** Small

### VIB-458H (optional): DMG-to-App-Store migration
- Detect if non-sandboxed config exists at real `~/Library/Application Support/Vibeliner/`
- Prompt user to re-select captures folder on first sandboxed launch
- Import settings from old config if accessible
- **Estimate:** Medium
