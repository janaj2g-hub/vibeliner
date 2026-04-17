# Vibeliner — App Review Notes

## How to test

1. Grant Screen Recording permission: System Settings > Privacy & Security > Screen Recording > enable Vibeliner
2. Grant Accessibility permission: System Settings > Privacy & Security > Accessibility > enable Vibeliner
3. Press Cmd+Shift+6 to capture a screen region
4. Draw a selection rectangle on screen
5. The editor opens — use the toolbar tools (Pin, Arrow, etc.) to add annotation markers
6. Press Cmd+C to copy the annotated prompt to your clipboard
7. The captures folder (set during setup) contains the saved screenshot.png and prompt.txt

## Why Screen Recording is needed

Vibeliner captures a user-selected region of the screen (not the full screen or other windows) using CGWindowListCreateImage. It does not record video, does not capture continuously, and does not transmit screenshots over the network. All captured images are stored locally in a user-chosen folder.

## Why Accessibility is needed

Accessibility permission is required for the global capture hotkey (Cmd+Shift+6). Without it, the hotkey only works when Vibeliner is the frontmost app. The app checks Accessibility status during its setup flow and guides the user to System Settings.

## Data practices

The app stores all data locally. It has no network access and does not transmit any data. No analytics, tracking, or telemetry. No user accounts. No third-party services.
