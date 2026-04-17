# Vibeliner — Product Definition: Prompt Templates

**Status:** Locked
**Defined via:** Design session 2026-03-30

---

## Overview

Every capture generates a `prompt.txt` file and a clipboard-ready version of the same prompt. The prompt has three parts: a customizable preamble, an auto-generated annotation list, and a customizable footer. The preamble adapts based on which annotation tools were used.

## Prompt structure

```
[preamble]

[annotation list]

[footer]
```

The preamble and footer are user-customizable in settings. The annotation list is always auto-generated.

## Default preamble

The default preamble is instructional — it tells the LLM what it's looking at and what to do:

```
This is a screenshot of my running app. View it at {{SCREENSHOT_PATH}}

Numbered annotations mark visual issues to fix. Annotations use pins (specific points), arrows (pointing at or between elements), rectangles and circles (highlighted regions), and freehand marks (irregular areas). Each annotation has a number and a description.

Fix each issue:
```

### Smart preamble (tool-aware)

The second sentence of the preamble adapts based on which tool types were actually used in the capture. Only the tools present are mentioned:

| Tools used | Preamble sentence |
|---|---|
| Only pins | Numbered pins mark specific points with issues. |
| Pins + arrows | Numbered pins mark specific points and arrows point at or between elements. |
| Pins + rectangles | Numbered pins mark specific points and rectangles highlight regions. |
| All five tools | Annotations use pins (specific points), arrows (pointing at or between elements), rectangles and circles (highlighted regions), and freehand marks (irregular areas). |
| Only rectangles | Numbered rectangles highlight regions with issues. |
| etc. | (dynamically constructed from the tools present) |

If only one tool type is used, the sentence is simpler. If multiple types are used, they're listed. This keeps the prompt concise when the user only placed pins, and descriptive when they used a mix.

### About arrows

The preamble describes arrows as "pointing at or between elements" — deliberately neutral. An arrow could mean "this is the problem," "move this here," or "these two things are related." The user's note text on each annotation carries the specific intent, not the arrow itself.

## Default footer

```
Make the changes and verify they match the design.
```

The footer is a single instruction line. Users can customize it to anything: "Don't change any other files," "Run the build after making changes," "Ask me before proceeding," or delete it entirely.

## Annotation list format

Auto-generated from all annotations in sequential order:

```
1  padding too tight
2  this card needs more height
3  move this element left
4  font weight too heavy
```

Format: `{number}  {note text}` — two spaces between number and text. One annotation per line. No brackets, no tool type labels, no extra formatting.

The numbers match the badge numbers visible in the screenshot image.

Annotations with empty notes (no text entered) are still listed:

```
5  (no description)
```

## Full default prompt example

### Saved prompt.txt (relative path)

```
This is a screenshot of my running app. View it at ./screenshot.png

Numbered pins mark specific points and arrows point at or between elements. Each annotation has a number and a description.

Fix each issue:

1  padding too tight
2  wrong border radius
3  move this element left

Make the changes and verify they match the design.
```

### Clipboard prompt (absolute path, IDE mode)

```
This is a screenshot of my running app. View it at /Users/jon/Documents/vibeliner/2026-03-30_143022/screenshot.png

Numbered pins mark specific points and arrows point at or between elements. Each annotation has a number and a description.

Fix each issue:

1  padding too tight
2  wrong border radius
3  move this element left

Make the changes and verify they match the design.
```

### Clipboard prompt (App mode)

Same text as IDE mode, but the path line is omitted since the image will be pasted separately:

```
This is a screenshot of my running app.

Numbered pins mark specific points and arrows point at or between elements. Each annotation has a number and a description.

Fix each issue:

1  padding too tight
2  wrong border radius
3  move this element left

Make the changes and verify they match the design.
```

## Path handling

| Context | Path format |
|---|---|
| Saved `prompt.txt` | Relative: `./screenshot.png` |
| Clipboard (IDE mode) | Absolute: `/Users/jon/Documents/vibeliner/2026-03-30_143022/screenshot.png` |
| Clipboard (App mode) | No path — the image is pasted separately |

The `{{SCREENSHOT_PATH}}` token in the preamble is replaced with the appropriate path. In App mode, the entire sentence containing the token is removed (not just the token).

## Customization (in Settings)

### Preamble field

A multi-line text area in settings showing the preamble. The user can edit freely.

- The `{{SCREENSHOT_PATH}}` token can be placed anywhere
- If the token is omitted, Vibeliner auto-appends a screenshot path line after the preamble
- The smart tool-description sentence is auto-generated and inserted after the first sentence — the user doesn't edit this part directly (it adapts per-capture)
- A "Reset to default" button restores the original preamble

### Footer field

A single-line or multi-line text area showing the footer.

- Can be empty (no footer)
- No tokens needed — it's just freeform text appended after the annotation list
- A "Reset to default" button restores "Make the changes and verify they match the design."

### Preview

Settings shows a live preview of what the prompt will look like with the current preamble, a sample annotation list, and the current footer. This updates as the user types.

## Edge cases

### 1. No annotations
The prompt still generates with the preamble and footer, but the annotation list section says:

```
(No annotations)
```

### 2. Only one annotation
The annotation list is a single line. The smart preamble uses singular form: "A numbered pin marks a specific point."

### 3. Very long note text
Note text is included as-is, no truncation. If the note wraps to multiple lines in the pill (25+ characters), it appears as one line in the prompt.

### 4. Special characters in note text
Note text is included verbatim. No escaping, no markdown formatting. Plain text.

### 5. User deletes all preamble text
The prompt starts directly with the annotation list. The screenshot path is auto-appended as the first line since the `{{SCREENSHOT_PATH}}` token was removed.

### 6. Token in footer
The `{{SCREENSHOT_PATH}}` token is only processed in the preamble. If placed in the footer, it renders literally as `{{SCREENSHOT_PATH}}`.
