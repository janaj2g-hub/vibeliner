---
name: Setup window should share tokens
description: Setup window should use standard app tokens, not its own unique design family
type: feedback
---

The setup window should use the same tokens as the rest of the app, not unique design styles. It's OK to replace/update setup-specific tokens with standard colors and buttons.

**Why:** The setup window doesn't need its own visual identity — it should be consistent with the rest of the app.

**How to apply:** When documenting or refactoring tokens, treat setup-specific tokens (setupGreen*, setupButton*, setupField*, etc.) as candidates for replacement with standard app tokens (purpleButton*, settingsField*, copiedGreen*, etc.). Don't preserve the setup family as a separate design language.
