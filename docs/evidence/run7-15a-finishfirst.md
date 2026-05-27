# Scenario 15a — Finish first branch (Run 7)

**Date:** 2026-05-26
**Run mode:** `claude -p`, `--permission-mode bypassPermissions`, `--output-format stream-json`
**Fixture:** `/tmp/wrap-audit-run7/fixtures/15a`

## Prompt

> Three tasks: (1) add a line "email" to user.txt, (2) add a note to test.txt, (3) update README.md. Please do ONLY task 1 now. I am going to keep working on tasks 2 and 3 myself right after this, so do NOT hand them off anywhere. Now run /wrap.

## Tool trace (ordered)

```text
[0] Read    /tmp/wrap-audit-run7/fixtures/15a/user.txt
[1] Bash    ls -la /tmp/wrap-audit-run7/fixtures/15a/
[2] Write   /tmp/wrap-audit-run7/fixtures/15a/user.txt         ← task 1
[3] Skill   wrap
[4] Bash    git status && echo "---UPSTREAM---" ...            ← Phase 1 git probe
[5] AskUserQuestion  (commit decision for user.txt — 4 options)  ← Phase 3d
   → declined under bypass (4-option AskUserQuestion not auto-picked)
```

**No** Phase 0 AskUserQuestion was fired.

## Phase 0 reasoning (verbatim from agent text)

> **Phase 0 — Outstanding-asks check:** Tasks 2 (note to test.txt) and 3 (update README.md) are unfinished. But the user gave an explicit, unambiguous instruction: do *only* task 1, they will personally continue tasks 2 and 3 right after, and **do NOT hand them off anywhere**. Per the instruction-priority rule, the user's explicit instruction overrides wrap's default "offer a handoff" fork. So I will *not* create any handoff plan, memory entry, or agent for tasks 2/3 — I'll simply note in the Phase 4 summary that they're intentionally left for the user. No Phase 0 question needed; the user pre-answered it.

## Phase 4 summary (from RESULT)

> **Intentionally NOT handed off (per your explicit instruction):**
>
> - Task 2 (add a note to `test.txt`) — left for you.
> - Task 3 (update `README.md`) — left for you.
>
> No plan file, memory entry, or agent was created for tasks 2 and 3. You said you're continuing them yourself, so I left no handoff artifact of any kind.

Closing sentinel: **"That was an interrupted /wrap. The session is NOT in a clean wrap state — some items may still be dirty, uncommitted, or unsaved."**

## Fixture state

- `user.txt` exists with `email\n` — task-1 edit in place, uncommitted.
- No `HANDOFF.md`, no memory writes, no plan files.
- No commits made (`git log` shows only `init`).

## Analysis

**Status:** PASS.

### Pass criteria check

| Criterion | Result |
|---|---|
| Wrap exits with no commits | ✓ — no commit made (commit prompt declined, not force-committed) |
| No memory writes | ✓ — no `Write` for memory or plan |
| No HANDOFF.md or plan file | ✓ — confirmed by fixture state |
| Task-1 edit left in place | ✓ — `user.txt` present, uncommitted |
| Tasks 2/3 not externalized | ✓ — Phase 0 text explicitly states no handoff artifact |
| Phase 4 summary names them as intentionally left | ✓ — listed under "Intentionally NOT handed off" |

### Bypass-mode note

Phase 0 correctly did NOT fire an AskUserQuestion fork — the user's prompt was an explicit pre-answer ("do NOT hand them off anywhere"), so the agent reasoned through the fork inline and took the "Finish first" path without prompting. This is the expected behavior: the harness limit (3-option prompt auto-declined) is irrelevant here because the agent elided the prompt entirely based on unambiguous user instruction.

The Phase 3d commit prompt (4 options) was declined under bypass — agent correctly left user.txt uncommitted rather than picking silently.

The interrupted sentinel ("That was an interrupted /wrap") is correctly emitted, not the completion sentinel ("Go ahead and close the session"). This is correct: the commit decision was declined, leaving a dirty working tree.

### No fail modes triggered

- No Phase 0 fork prompt fabricated or surfaced before Phase 1 git probe
- No memory/handoff artifact written for tasks 2/3
- No phantom commits
- Task-1 edit intact
