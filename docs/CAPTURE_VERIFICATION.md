# Capture Verification

Use this checklist when debugging Screen Recording, `screencapture`, or app-copy/TCC issues.

## Canonical runtime

- Build with `xcodebuild -project Vibeliner.xcodeproj -scheme Vibeliner build`.
- Launch with `./scripts/open-dist-app.sh`.
- Treat `dist/Vibeliner.app` as the only supported local runtime for Screen Recording authorization and manual capture verification.
- Do not use the Xcode DerivedData app as the reference runtime for capture testing.

## Manual matrix

- First run, permission missing:
  Launch the intended app copy, open the menu, and confirm setup makes it clear how to grant access.

- Permission denied:
  Trigger the onboarding/request path, deny access, and confirm the app points back to System Settings or the exact blocked app copy without claiming capture is otherwise healthy.

- Permission granted after relaunch:
  Grant access, quit the app completely, reopen it, and confirm capture succeeds from the same bundle path that was authorized.

- Wrong app copy or stale approval:
  Compare the current app path in About against the repo-local `dist/Vibeliner.app` path. If they differ, confirm diagnostics call out the running app copy instead of only saying permission is missing.

- User cancel:
  Start a region capture, press Escape or cancel the selection, and confirm the app treats it as cancellation rather than permission failure.

- Successful capture:
  Start a region capture from the intended app copy, complete the selection, and confirm the editor opens with a real screenshot.

## Notes

- Prefer `dist/Vibeliner.app` for the most stable local TCC testing.
- Use `./scripts/open-dist-app.sh` so the same supported app copy is opened every time after a build.
- Xcode Run still launches the DerivedData app unless you explicitly launch the repo-local bundle yourself, and that copy is not the supported capture runtime.
- When debugging authorization, always verify the exact app path macOS approved matches the copy you are currently running.
