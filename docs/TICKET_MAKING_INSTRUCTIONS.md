# Vibeliner — Ticket-Making Instructions

Step-by-step process for investigating, writing, and pushing tickets that Claude Code or Codex can execute.

---

## The workflow

### Step 1: User describes the work
The user reports a bug, requests a feature, or describes an idea. This may come as:
- A description in chat ("the hotkey doesn't work when another app is focused")
- A Vibeliner screenshot (annotated image + prompt.md)
- A vague idea ("maybe we should support undo")

### Step 2: Search for duplicates
Before doing anything else, search existing issues:

```text
list_issues(project: "Vibeliner", query: "[relevant keywords]")
```

Check results:
- Backlog/Todo match -> Update the existing ticket instead of creating a new one
- Fix Failed match -> Write a retry prompt on the existing ticket with escalation
- Done match -> Verify the completed fix actually covers this scope. If not, create a new ticket referencing the Done one.
- No match -> Proceed to create a new ticket

### Step 3: Investigate context
Before writing the ticket:

1. Check [CLAUDE.md](/Users/jongrossman/Documents/vibeliner/V1/vibeliner/CLAUDE.md) and [AGENTS.md](/Users/jongrossman/Documents/vibeliner/V1/vibeliner/AGENTS.md) for project conventions and the current GitHub execution workflow.
2. Check [docs/TECHNICAL_DECISIONS.md](/Users/jongrossman/Documents/vibeliner/V1/vibeliner/docs/TECHNICAL_DECISIONS.md) for previously failed approaches on this area.
3. Check [docs/PRODUCT_VISION.md](/Users/jongrossman/Documents/vibeliner/V1/vibeliner/docs/PRODUCT_VISION.md) if the ticket involves user-facing behavior.
4. Check the relevant source files if the ticket modifies existing code so you understand current state.

### Step 4: Scope and group
Apply the one-ticket-per-subsystem rule:
- If the work touches multiple unrelated subsystems, create separate tickets.
- If 3+ related sub-issues emerge, create a Story with lettered children.
- If the scope is ambiguous and you cannot list 3 edge cases, it is an Idea, not a Feature. Park it at Backlog.

### Step 5: Write the ticket description
Use the description template from [docs/LINEAR_CONVENTIONS.md](/Users/jongrossman/Documents/vibeliner/V1/vibeliner/docs/LINEAR_CONVENTIONS.md):

```markdown
## What
[One sentence]

## Why
[User impact or dependency]

## Design
[How it works. Data structures, file paths, behavior.]

## Files
- `Vibeliner/[file].swift` — [what changes]

## Dependencies
- Requires [ticket reference]

## Edge cases
- [At least 2-3 specific edge cases]

## Not in scope
- [Explicit exclusions]
```

Push to Linear:

```text
save_issue(
  title: "[prefix]: [name]",
  team: "Vibe Liner",
  project: "Vibeliner",
  description: "[description markdown]",
  labels: ["Feature", "Size: M"],
  state: "Todo",
  priority: 3
)
```

For sub-issues, also set `parentId` to the Story's issue ID.

### Step 6: Write the prompt comment
Post the implementation prompt as a comment on the ticket.

Use:
- `## Claude Code prompt` when the ticket is intended for Claude Code
- `## Codex prompt` when the ticket is intended for Codex

Example:

```text
save_comment(
  issueId: "VIB-XX",
  body: "## Claude Code prompt\n\n**Context:** ...\n\n**Tasks:**\n1. ...\n\n**Verification:**\n- [ ] ... :\n"
)
```

Use the prompt comment template from [docs/LINEAR_CONVENTIONS.md](/Users/jongrossman/Documents/vibeliner/V1/vibeliner/docs/LINEAR_CONVENTIONS.md). Required sections:
- Context — what and why, with parent Story reference if relevant
- Reference — point to `PRODUCT_VISION.md`, `TECHNICAL_DECISIONS.md`, and the correct agent instruction file
- Tasks — numbered, specific, with exact file paths
- Constraints — architectural rules and what not to do
- Build & verify — the `xcodebuild` command
- GitHub workflow — branch, commit, push, and PR expectations
- Verification — binary pass/fail assertions ending with ` :`

Prompt comments should explicitly say that the ticket is not complete until the branch is built, committed, pushed, and the PR is opened or updated.

### Step 7: Move to Prompt Ready
After posting the prompt comment:

```text
save_issue(id: "VIB-XX", state: "Prompt Ready")
```

If this is the first child of a Story to reach Prompt Ready, also move the Story to In Progress:

```text
save_issue(id: "VIB-[story]", state: "In Progress")
```

### Step 8: User runs the prompt
The user copies the batch or individual prompt and pastes it into Claude Code or Codex. Linear does not execute prompts.

### Step 9: Agent executes and pushes the work
The executing agent should follow the repo instructions in [CLAUDE.md](/Users/jongrossman/Documents/vibeliner/V1/vibeliner/CLAUDE.md) or [AGENTS.md](/Users/jongrossman/Documents/vibeliner/V1/vibeliner/AGENTS.md):
- Create a feature branch, not `main`
- Implement the ticket
- Run the required build
- Post the verification comment on the Linear ticket
- Commit using the Linear ticket ID
- Push the branch to GitHub
- Open or update the pull request back to `main`

For normal code-changing runs, treat the task as incomplete until the build is verified and the branch is pushed, unless the user explicitly requests a local-only or no-git pass.

For batch Linear work, complete the full cycle for each ticket in order before starting the next ticket:
1. Implement
2. Build
3. Commit
4. Push
5. Open or update the PR
6. Verify and post the verification comment

Do not let an agent move on to the next ticket in the batch while the current ticket is still only local and unpushed.

### Step 10: User reports results
The user tests the implementation and tells you the result:

- "It works" -> Move ticket to Done. Check if parent Story has all children Done. If yes, move Story to Done too.
- "It partially works, but [issue]" -> Move to Needs Revision. Write a targeted follow-up prompt comment.
- "It failed — [description]" -> Move to Fix Failed. Apply retry escalation rules:
  - Attempt 2: Debug-first prompt
  - Attempt 3+: Fundamentally different approach
  - Log failure in `docs/TECHNICAL_DECISIONS.md`
  - Write new prompt comment, move to Prompt Ready
- "This was fixed by another ticket" -> Move to Resolved Elsewhere, add label `Resolved Elsewhere`
- "This is a duplicate of VIB-XX" -> Move to Duplicate and set `duplicateOf`

---

## GitHub execution contract

Vibeliner now uses GitHub as the default execution flow for implementation work.

- Canonical remote: `https://github.com/janaj2g-hub/vibeliner.git`
- Do not implement tickets directly on `main`
- Codex branch naming: `codex/<ticket-id>-short-slug`
- Claude Code branch naming: `claude/<ticket-id>-short-slug`
- Include the Linear ticket ID in branch names, commit messages, and PR titles whenever possible
- Never force-push `main` or rewrite shared history
- Only skip commit and push when the user explicitly asks for a local-only or no-git pass

Recommended prompt language for execution tickets:

```markdown
**GitHub workflow:**
1. Create a feature branch for this ticket.
2. Implement the changes.
3. Run `xcodebuild -project Vibeliner.xcodeproj -scheme Vibeliner build`.
4. Post the verification comment on the Linear ticket.
5. Commit with the ticket ID in the message.
6. Push the branch to `origin`.
7. Open or update the pull request to `main`.
8. Treat the ticket as incomplete until the push succeeds and the PR is current.
```

---

## Flagging high-risk tickets

Some tickets are likely to need multiple attempts. Flag these in the description with:

```markdown
## Risk
**High risk.** [Why this is hard.]

**Fallback approach:** [Alternative if primary approach fails.]
```

For Vibeliner, the two highest-risk areas are:
1. Screen region selection and native capture handoff from the menu bar app. Keep v1 on file-based `screencapture -i`; do not switch to ScreenCaptureKit as a fallback.
2. Annotation canvas freehand drawing and inline text editing. This is core AppKit/editor work and has no cheap fallback.

---

## Prompt iteration after failure

When writing attempt 2+ prompts:

1. Start the comment with `## Claude Code prompt (attempt N)` or `## Codex prompt (attempt N)`.
2. Summarize what failed and why.
3. For attempt 2, add explicit debug steps before any code changes.
4. For attempt 3+, describe the new approach and why it differs from previous attempts.
5. Reference the failed approach logged in [docs/TECHNICAL_DECISIONS.md](/Users/jongrossman/Documents/vibeliner/V1/vibeliner/docs/TECHNICAL_DECISIONS.md).

Example:

```markdown
## Claude Code prompt (attempt 2)

**Previous attempt failed:** The NSView mouseDown event was not being called because the window's contentView was intercepting events.

**Debug first:**
1. Add temporary instrumentation to `AnnotationCanvas.mouseDown(with:)`.
2. Log the active window and responder chain to verify where events are landing.
3. Build and run, attempt to draw, and inspect the observed behavior.

**Then fix:**
1. [Specific fix based on debug findings]
```
