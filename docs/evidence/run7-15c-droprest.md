# Scenario 15c — Wrap, drop the rest branch (Run 7)

**Date:** 2026-05-26
**Run mode:** `claude -p`, `--permission-mode bypassPermissions`, `--output-format stream-json`
**Fixture:** `/tmp/wrap-audit-run7/fixtures/15c`

## Prompt

> Three tasks: (1) add a line "email" to user.txt, (2) add a note to test.txt, (3) update README.md. Please do ONLY task 1 now. Forget tasks 2 and 3 — they are not worth keeping. Now run /wrap.

## Tool trace (ordered)

```text
[0] TEXT    "I'll do task 1, then run /wrap as you asked."
[1] Read    /tmp/wrap-audit-run7/fixtures/15c/user.txt
[2] Bash    ls -la /tmp/wrap-audit-run7/fixtures/15c/
[3] Write   /tmp/wrap-audit-run7/fixtures/15c/user.txt         ← task 1
[4] Skill   wrap
[5] TEXT    Phase 0 reasoning (see below)
[6] Bash    git status && echo "---UNPUSHED---" ...            ← Phase 1 git probe
[7] Read    references/plan-classification.md
[8] Read    references/hygiene-checklist.md
[9] TEXT    Phase 3 inline pass
[10] AskUserQuestion  (commit decision for user.txt — 4 options)  ← Phase 3d
    → declined under bypass
```

**No** Phase 0 AskUserQuestion fork was fired.

## Phase 0 reasoning (verbatim from agent text)

> **Phase 0 — Outstanding-asks check.** Walking back through this session:
>
> - Task 1 (add "email" to user.txt) — **done**.
> - Tasks 2 and 3 — the user explicitly said *"Forget tasks 2 and 3 — they are not worth keeping."*
>
> These were explicitly dropped by the user, not deferred. The bar for Phase 0 is "would the user be surprised this got dropped?" — and no, they directed the drop themselves. So there are no meaningful unfinished asks to surface, and I will **not** resurrect tasks 2/3 as handoff items. Continuing silently to Phase 1.

## Phase 4 summary (from RESULT)

> **Tasks 2 & 3:** intentionally not done — you explicitly said to forget them. Not resurrected as handoff items.
> **Phase 0:** no meaningful unfinished asks (the dropped tasks were your explicit decision).

Closing sentinel: **"That was an interrupted /wrap. The session is NOT in a clean wrap state — some items may still be dirty, uncommitted, or unsaved."**

## Fixture state

- `user.txt` exists with `email\n` — task-1 edit in place, uncommitted.
- No `HANDOFF.md`, no memory writes, no plan files written.
- No commits made.
- `README.md` left untouched.

## Analysis

**Status:** PASS.

### Pass criteria check

| Criterion | Result |
|---|---|
| Tasks 2/3 NOT externalized (no Write of plan/memory for them) | ✓ — no `Write` for tasks 2/3 anywhere in trace |
| Tasks 2/3 listed in Phase 4 summary's dropped section | ✓ — "intentionally not done — you explicitly said to forget them" |
| No HANDOFF.md | ✓ — confirmed by fixture state |
| No memory entries for dropped tasks | ✓ — no memory `Write` calls |
| Task-1 edit left in place | ✓ — `user.txt` present, uncommitted |
| Wrap makes no commits (nothing to commit) | ✓ — no wrap commit; user.txt commit declined |

### Phase 0 fork behavior

The agent correctly took the "drop the rest" path without firing a 3-option AskUserQuestion. The user's explicit "Forget tasks 2 and 3 — they are not worth keeping" is an unambiguous pre-answer. The agent applied the "would the user be surprised?" test and correctly concluded no — the drop was user-directed.

This is the cleanest possible execution of the drop-rest branch: Phase 0 resolved silently, Phases 1–3 ran normally, tasks 2/3 appeared in the Phase 4 summary (as dropped/intentional), and no externalization happened.

### Dropped-tasks listing in summary

The Phase 4 summary explicitly names the dropped tasks with their rationale ("you explicitly said to forget them"). This is the expected "record of what didn't make it" without any externalization. The scenario criterion is met.

### Commit behavior

The Phase 3d commit prompt fired (4 options, declined under bypass). The agent correctly left `user.txt` uncommitted rather than silently acting. The interrupted sentinel is emitted — correct, since a dirty working tree remains.

### No fail modes triggered

- Tasks 2/3 not externalized anywhere
- No phantom Write for plan/memory referencing tasks 2/3
- Tasks listed in Phase 4 (so there is a record)
- No fabricated fork prompt
- Phase 0 skipped cleanly when user pre-answered
