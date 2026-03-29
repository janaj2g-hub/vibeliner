# Vibeliner — Annotation Prompting Contract

Source of truth for how Vibeliner describes annotated screenshots to downstream LLMs.

Future coding runs should read this document before changing:
- prompt defaults
- prompt export logic
- screenshot-path insertion
- annotation semantics
- prompt settings copy

## Goals

Vibeliner prompt text should do three things well:

1. Tell the model what artifact it is receiving.
2. Explain what each annotation type means.
3. Stay concise enough that repeated use does not waste tokens.

The screenshot is the primary visual source of truth. Prompt text exists to frame that screenshot, not to restate every visible detail.

## Screenshot contract

Vibeliner exports a real screenshot file and a text prompt that references it.

- Saved `prompt.md` files may use a folder-relative screenshot reference such as `./screenshot.png`.
- Copied prompt text must resolve that screenshot reference to a concrete absolute path so the prompt still works when pasted from an arbitrary Claude Code or Cursor working directory.
- The supported insertion token is `{{SCREENSHOT_PATH}}`.
- If a user prompt template omits `{{SCREENSHOT_PATH}}`, Vibeliner should append a separate screenshot-reference line rather than silently dropping the path.

This path behavior is part of the product contract and should not drift across app and CLI code paths.

## Annotation vocabulary

### Numbered badges

Numbered badges mark the user's explicit discussion points.

- A badge identifies one issue, question, or requested change.
- Badge numbers provide stable ordering for the accompanying text notes.
- Downstream prompts should describe badges as the user's intentional focus points, not just generic decoration.

### Attached note text

Attached note text is the human-readable description for a numbered badge.

- If a badge has note text, that text should be treated as the primary explanation of the issue.
- If a badge exists without note text yet, the model should still inspect the marked area, but prompt text should not invent a missing explanation.
- Exported prompts should not imply that every badge always has a complete note.

### Arrows

Arrows identify an exact UI target or direction of attention.

- Use arrows when the user wants the model to inspect a specific control, edge, gap, icon, or alignment point.
- Prompt text should describe arrows as pointing to the exact target region.
- Arrows are supporting location aids; they do not replace the screenshot itself.

### Circles

Circles highlight a region or cluster of pixels to inspect.

- Use circles when the user wants the model to look at a broader area rather than a single point.
- Prompt text should describe circles as highlighted regions of interest.
- Circles may appear with or without additional note text.

## Screenshots with no annotations

Some screenshots may be exported without annotations.

- Prompt text should still describe the screenshot as the primary source of truth.
- The prompt should not claim that numbered badges, arrows, or circles are present when they are not.
- The no-annotation case should remain concise and should not fall back to a verbose generic image-analysis prompt.

## Prompt-writing rules

Default prompt text should follow these rules:

1. Lead with the screenshot artifact.
2. Explain annotation types in one compact block, not scattered repeated sentences.
3. Distinguish between explicit user-marked issues and unannotated background context.
4. Prefer short structured prose over long narrative setup.
5. Avoid vendor-specific wording unless a concrete downstream tool requires it.

Good default framing usually communicates:
- there is a screenshot
- red overlays are intentional annotations
- numbered badges correspond to issues or discussion points
- note text explains those points when present
- arrows and circles narrow attention to exact targets or regions

## Token budget guidance

Prompt text should help the model without becoming the main payload.

- Do not restate the same annotation rules in multiple paragraphs.
- Do not describe obvious screenshot mechanics in detail every time.
- Do not add speculative instructions about image reasoning that the product does not rely on.
- Prefer one concise semantic block over several overlapping explanation blocks.

The screenshot and numbered notes carry most of the information. The prompt contract should only add enough framing to reduce ambiguity.

## Runtime and docs responsibilities

Keep responsibilities split cleanly:

- This document defines the contract and terminology.
- Runtime prompt builders should implement that contract consistently.
- Prompt settings UI should explain how the path token and annotation semantics work without hiding behavior behind magic.

If runtime prompt wording changes, update this document first or in the same change.

## Extending the contract

If Vibeliner adds a new annotation type later:

1. Add a new section to this document describing what the new marker means.
2. Define how it relates to numbered badges and note text.
3. Update runtime prompt generation in one shared source of truth.
4. Update prompt settings/help text only where user understanding would otherwise break.

Do not introduce a new annotation type in code without documenting its LLM-facing semantics here.
