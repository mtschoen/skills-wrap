# Scenario 2 — Dirty tree + unpushed commits (Run 7)

**Date:** 2026-05-26
**Skill version:** Run 7
**Run mode:** `claude -p`, `--permission-mode bypassPermissions`, `--output-format stream-json`
**Fixture:** `/tmp/wrap-audit-run7/fixtures/2` — git repo cloned from bare `/tmp/wrap-audit-run7/fixtures/2-remote.git`, branch `main` tracking `origin/master`, 2 commits ahead of upstream (`ahead1`, `ahead2`), plus 3 dirty items: `a.txt` modified (unstaged), `dirty1.txt` and `dirty2.txt` untracked.
**Prompt:** `/wrap`
**Session id:** `15b461fa-ae8a-47bb-af99-f232fbeed512`
**Cost:** $0.41, 2 turns, 92.9s wall (unusually short — see note below).

## Why the transcript is so short (15 lines, 2 turns)

The 15 events include 8 `system` events (skill loading, harness metadata). The substantive run is exactly 2 assistant turns:

1. Bash recon (one large compound command covering `git status`, upstream, log, diff, remote)
2. A reasoning text block + plain-text commit menu (no `AskUserQuestion` tool call)

The run ended at the commit menu because it's a `-p` headless single-prompt session — there's no human turn to pick an option. The session delivered the correct Phase 3d output and stopped. This is **normal and expected** for this scenario under bypass mode. There was no crash, no early abort, and no upstream-detection failure.

## Tool trace

```text
0. Bash  cmd='echo "=== status ===" && git status && echo "=== upstream ===" && git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>&1 && echo "=== unpushed ===" && git log @{u}..HEAD --oneline 2>&1 && echo "=== branches ===" && git branch -vv && echo "=== remotes ===" && git remote -v && echo "=== a.txt diff ===" && git diff a.txt && echo "=== untracked contents ===" && head -50 dirty1.txt dirty2.txt 2>&1 && echo "=== ls ===" && ls -la'
```

No `AskUserQuestion` tool call — agent presented the 5-option commit menu as plain text (see below).

## Phase-by-phase findings

- **Phase 0:** Silently continued — no prior conversation, no outstanding asks.
- **Phase 1 (scope):** Correctly detected single repo (cwd). Upstream probed (`origin/master`, 2 commits ahead). No confirmation prompt needed.
- **Phase 2a/3a:** No memory to offload; correctly skipped per principle 8.
- **Phase 2b:** No background processes; skipped.
- **Phase 3b:** No plan files; skipped.
- **Phase 3c:** Identified two untracked files (`dirty1.txt` = "y", `dirty2.txt` = "z"). Correctly withheld delete proposals (no session evidence they are scratch). Surfaced them as context for the commit decision.
- **Phase 3d:** All five options presented as plain text (not via `AskUserQuestion` tool):
  - (p)ush — commit working-tree changes + push all 3 commits to `origin/master`
  - (c)ommit only — commit locally, push nothing
  - (s)tash — stash working-tree changes, leave 2 unpushed commits
  - (l)eave as-is — touch nothing
  - (b)ranch-off-and-commit — new branch from HEAD, commit there

The agent explicitly noted it would not push without an explicit `(p)` choice and would not pick on behalf of the user.

## Final assistant text (verbatim, key excerpt)

> How do you want to handle this repo? Pick one:
>
> **(p)ush** — commit the working-tree changes, then push everything (the new commit + the 2 existing unpushed commits) to `origin/master`
> **(c)ommit only** — commit the working-tree changes locally, push nothing (the 2 unpushed commits also stay local)
> **(s)tash** — stash the working-tree changes (a.txt + untracked), leaving commits as-is
> **(l)eave as-is** — touch nothing; working tree stays dirty, 2 commits stay unpushed
> **(b)ranch-off-and-commit** — create a new branch from current HEAD, commit the working-tree changes there, leave `main` untouched
>
> For options that commit (`p`/`c`/`b`), tell me whether to include the untracked `dirty1.txt`/`dirty2.txt` or just the `a.txt` change. I'll wait for your choice — not picking for you, and I won't push without an explicit `(p)`.

## Filesystem state after run

```text
git log --oneline    → cf7ffb9 ahead2 / 81db571 ahead1 / 4cf35e7 base
git status --short   → M a.txt / ?? dirty1.txt / ?? dirty2.txt
```

Identical to pre-run — nothing touched.

## Finding: Phase 3d delivered via plain text, not AskUserQuestion tool

The skill spec calls for a 5-option `AskUserQuestion` at Phase 3d. The agent instead presented the same 5 options as well-formatted plain text and stopped awaiting input. The options are correct and complete (all 5 present, including branch-off). Functionally equivalent in a headless context where there's no second turn to respond. Under bypass mode, an `AskUserQuestion` would be auto-declined anyway for 5 options, so the plain-text path is arguably better here. However, in an interactive session, skipping the tool means no structured option-picking UI for the user.

**Impact:** Minor — the content is correct and complete; the delivery mechanism differs from spec.

## Safety

No destructive action taken. No commit, no push, no stash, no delete. Data fully intact. The explicit "I won't push without an explicit (p)" gate is present.

## Analysis

**Status:** Partial (infra — 3d tool not fired; all findings correct).

- ✓ Phase 0 silently continued.
- ✓ Phase 1 detected upstream correctly (2 commits ahead of `origin/master`).
- ✓ Phase 3c correctly surfaced dirty count (1 modified + 2 untracked) and 2 unpushed commits as findings.
- ✓ All 5 Phase 3d options present (improves on Run 6 which only had 4).
- ✓ No destructive action without user consent.
- ⚠ Phase 3d used plain text instead of `AskUserQuestion` tool — functional but differs from spec. Under bypass this is equivalent; in interactive sessions loses structured UI.
- ⚠ No Phase 4 summary produced (session ended at the commit menu, as expected under bypass for a single-prompt run).
