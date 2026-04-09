# Archived Document

This file reflects the previous Settings window rebuild and the subsequent runtime repair pass.
It is not the current source of truth for shipped behavior.
Use it for historical context, debugging, and implementation handoff only.

# [archive] Settings Window Design

## Purpose

This document records the design process and implementation history of the native Settings window rebuild. It is written for an advanced LLM coder or engineer who needs to understand:

- what the Settings window looked like before the rebuild
- what the rebuild attempted to achieve
- what code-level architectural changes were made
- why the first runtime result failed
- what the repair pass changed and why

This is a historical design-and-implementation narrative, not a current product-definition document.

## Before The Rebuild

Before the rebuild, the Settings window was a working but increasingly brittle AppKit preferences window with three top-level tabs:

- `General`
- `Prompt`
- `About`

The main issues before the rebuild were:

- layout drift from the desired design
- repeated hardcoded layout constants and style values
- Prompt-tab structure that did not match the intended product hierarchy
- limited reuse across tabs
- low confidence that future sections or tabs could be added safely

Architecturally, the window was mostly a collection of independent custom AppKit views. Each tab owned its own layout decisions and styling patterns. This made changes expensive and error-prone.

## Target Design After The Rebuild

The rebuild was driven by an approved HTML prototype. The intended native result was:

- top-level `General / Prompt / About` tabs preserved
- `General` refactored into reusable sections
- `Prompt` redesigned into:
  - `Full Prompt Preview` at the top
  - framed `Edit Prompt Sections` below
  - left-aligned section title and right-aligned shared `Save`
  - centered segmented control:
    - `Preamble`
    - `Tools`
    - `Footer`
  - active content below the segmented control
  - per-subtab `Reset to default` below the active content
- `About` cleaned up into a simpler centered information tab
- shared styling moved into the design system

The architectural goal was not just visual polish. It was to turn Settings into a reusable, section-driven system that could accept future sections and future tabs without repeating frame math.

## Phase 1 — Initial Rebuild

**Timestamp:** `2026-04-04`

### Strategy

The first rebuild attempted to preserve the top-level AppKit shell while introducing a more composable internal settings architecture.

Key goals:

- make top-level tabs data-driven
- introduce shared settings UI primitives
- replace local one-off styling with token-driven styling
- refactor `General` into reusable sections
- redesign `Prompt` around the approved prototype
- make future sections and tabs easier to add

### Coding Changes Made In Phase 1

The first rebuild changed these areas:

#### `SettingsWindowController`

- introduced a small tab model for `General`, `Prompt`, and `About`
- centralized window shell responsibilities:
  - window creation
  - tab button creation
  - active-tab switching
  - content hosting

#### Shared Settings UI Layer

- introduced reusable settings helpers in the shared settings UI layer
- added primitives for:
  - section titles
  - body copy
  - field surfaces
  - preview surfaces
  - pill buttons
  - segmented control
  - reusable section containers

#### `GeneralTabView`

- refactored `General` into reusable sections instead of a single hand-authored layout pass
- introduced shared styling between:
  - hotkey keycaps
  - folder field
  - pill `Change` buttons

#### `PromptTabView`

- rebuilt `Prompt` to match the prototype structure
- introduced:
  - `Full Prompt Preview`
  - framed `Edit Prompt Sections`
  - shared `Save`
  - segmented `Preamble / Tools / Footer`
  - per-subtab `Reset to default`

#### `PromptPreviewView`

- reshaped the preview into a dedicated read-only prompt-preview section
- aligned it more closely with the approved Prompt hierarchy

#### `DesignTokens.swift`

- added settings-specific tokens for:
  - field surfaces
  - preview surfaces
  - pill styling
  - segmented control styling
  - frame radii and spacing

#### Documentation

- updated Settings docs and product docs to describe the intended post-rebuild UI

### Why Phase 1 Was Directionally Correct

The first rebuild had the right strategic goals:

- it used the prototype as visual source of truth
- it introduced shared settings primitives
- it moved styling toward design tokens
- it made the top-level shell more extensible
- it treated `Prompt` as a first-class information architecture problem rather than a loose collection of controls

From a product and long-term maintainability perspective, these were good decisions.

## Issues Observed After Phase 1

After the first rebuild, the code compiled and the Settings shell rendered, but the runtime window showed only the shell chrome and top-level tabs. The content for `General`, `Prompt`, and `About` appeared blank.

Observed behavior:

- window title rendered
- top-level tabs rendered
- active underline rendered
- inner content area appeared empty

This established that the rebuild existed in source, but the native AppKit runtime layout contract was broken.

## Why Phase 1 Failed At Runtime

The main problem was not the visual design. The problem was that the rebuild mixed incompatible layout assumptions.

### Failure 1: Zero-Frame Initialization

The shell created tab views at `.zero`, then hosted them later. That is only safe if every tab is fully size-agnostic during setup.

That was not consistently true.

### Failure 2: Frame-Based `AboutTabView`

`AboutTabView` still positioned content using `frame.width` and `frame.height` during setup. When created at `.zero`, this produced invalid layout.

### Failure 3: Fragile Prompt Scroll / Document Sizing

`PromptTabView` used an `NSScrollView.documentView` arrangement that treated the document container more like a normal Auto Layout host than AppKit reliably guarantees. This made the Prompt content’s visible extent fragile.

### Failure 4: Weak Section Sizing Contract

The reusable section-wrapper approach was architecturally useful, but the wrapper views did not provide a strong enough fitting-size contract for stack-based hosting in every case.

### Core Architectural Lesson

The first rebuild improved the design-system direction, but it did not unify the runtime layout model. It mixed:

- frame-based layout
- Auto Layout stack composition
- scroll/document sizing

without one explicit lifecycle contract.

## Phase 2 — Runtime Layout Repair

**Timestamp:** `2026-04-05`

### Strategy

The repair pass preserved the design direction from Phase 1, but changed the runtime implementation rule:

> All settings content must be safe under zero-frame initialization and must use a deterministic Auto Layout sizing contract.

This pass focused on runtime stability first, not new visual invention.

### Coding Changes Made In Phase 2

#### `SettingsWindowController`

- kept the data-driven top-level tab model
- changed content hosting to pin the active tab view to the content container with constraints instead of relying on frame assignment as the effective layout mechanism

#### Shared Settings UI Layer

- strengthened reusable section composition so section containers expose a more reliable size to parent stacks
- moved section layout toward direct stack-based composition rather than weak wrapper sizing

#### `GeneralTabView`

- kept the section-driven architecture
- adopted the stronger section-sizing path from the shared settings layer
- ensured `General` could remain extensible without collapsing arranged content

#### `PromptTabView`

- removed the fragile root scroll/document-view hosting pattern used for the whole Prompt tab
- moved Prompt back to a direct constrained root stack
- preserved the approved structure:
  - `Full Prompt Preview`
  - framed `Edit Prompt Sections`
  - title-left / save-right header
  - centered segmented `Preamble / Tools / Footer`
  - active content region
  - per-subtab `Reset to default`

#### `AboutTabView`

- replaced frame-based layout with constraint-driven vertical composition
- made `About` safe under zero-frame initialization and window resizing

#### Documentation

- updated the live Settings docs to record that the shipped native implementation is section-driven and runtime-safe under zero-frame initialization
- preserved this archive to explain why the repair pass was required

### Why Phase 2 Was Necessary

Phase 2 was necessary because the first rebuild solved for design-system intent but not for AppKit runtime behavior.

The repair pass did not reject the first rebuild’s goals. It preserved the good ideas:

- reusable settings primitives
- top-level tab model
- prompt redesign
- token-driven styling
- extensibility by composition

It replaced only the flawed runtime assumptions.

## Before / After Architecture Summary

### Before Any Rebuild

- mostly custom per-tab AppKit layout
- duplicated style logic
- limited reuse
- fragile future-edit story

### After Phase 1

- better product structure
- reusable settings primitives
- better Prompt information architecture
- improved token usage
- but mixed runtime layout models

### After Phase 2

- top-level shell remains data-driven
- tabs are intended to be zero-frame-safe
- layout is normalized around Auto Layout
- section composition is stronger
- future sections and future tabs remain feasible without returning to manual frame math

## What Future LLM Coders Should Preserve

These ideas from the rebuild should be preserved:

- prototype-driven visual source of truth
- data-driven top-level settings tabs
- reusable settings UI primitives
- token-driven settings styling
- section-based composition
- Prompt structure with:
  - `Full Prompt Preview`
  - framed `Edit Prompt Sections`
  - segmented `Preamble / Tools / Footer`
  - shared `Save`
  - per-subtab `Reset to default`

## What Future LLM Coders Should Avoid

Do not reintroduce:

- frame-based tab layout that depends on `frame.width` or `frame.height` during init
- mixed shell-hosting assumptions where tab views are created before they can safely lay themselves out
- fragile `NSScrollView.documentView` sizing unless the document extent is explicitly owned and tested
- wrapper views with weak or implicit fitting-size behavior in stack-based layouts

## Final Takeaway

The Settings rebuild was not a failed idea. It was a good design-system and architecture move that was implemented with an unstable native runtime layout contract.

Phase 1, on `2026-04-04`, introduced the right long-term direction.

Phase 2, on `2026-04-05`, repaired the runtime contract so the native AppKit implementation could actually render that design safely.

Any future work should keep the Phase 1 design goals and Phase 2 runtime rules together.
