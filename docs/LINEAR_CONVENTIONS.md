# Vibeliner — Linear Conventions

Reference document for ticket types, naming, labels, sizing, and prompt formatting.
See the Claude.ai project system instructions for workflow rules.

## Ticket types

- **Story** — parent ticket, no prompt. Title: `Story: [name]`
- **Feature** — scoped implementation. Title: `feat: [what]`
- **Bug** — something broken. Title: `fix: [what]`
- **Idea** — unscoped, needs 3+ edge cases. Title: `Idea: [concept]`
- **Infrastructure** — build/tooling. Title: `infra: [what]`
- **Polish** — visual/UX refinement. Title: `polish: [what]`

## Sizing

| Size | Files | Scope |
|---|---|---|
| XS | 1–2 | Config key, constant, stub |
| S | 2–4 | New method, wire a button |
| M | 4–8 | New module, new controller |
| L | 8–15 | Complex feature |
| XL | 15+ | Must break into sub-issues |

## Sub-issue naming

`[StoryNumber][Letter]: [name]` — e.g., `1A: Menu bar app shell`

Letters indicate build order.
