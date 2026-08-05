# Scenario 2 - Dirty tree + unpushed commits (Run 8)

**Date:** 2026-08-05
**Skill version:** source HEAD `7d34830` (prose-ask), installed copy verified byte-identical to source `SKILL.md`
**Run mode:** `tests/run-audit.sh 2`, model sonnet, `--permission-mode bypassPermissions`, multi-turn via `--resume`
**Fixture:** repo with bare upstream, 2 unpushed commits (`work 1`, `work 2`), 3 dirty tracked files (`a.txt`, `b.txt`, `c.txt`)
**Prompt:** `/wrap`
**Cost:** $0.39, 2 turns

## Result: Pass

This is the first run of scenario 2 against the prose-ask skill, and the first
time the scenario has ever run past its own commit menu. Under `AskUserQuestion`
the widget auto-declined and Run 7 recorded "ended at menu" as a Partial.

## Phase-by-phase

- **Phase 0:** silently continued. No prior conversation, no outstanding asks.
- **Phase 1:** correct detection - 3 dirty files and 2 unpushed commits
  (`fd0a711`, `f77ec11`), single repo, no confirmation ceremony for a
  single-repo cwd case.
- **Phases 2a/2b/3a/3b/3c:** all correctly silent. No memory candidates, no
  background processes, no plans, no junk. No fabricated items (principle 9).
- **Phase 3d:** **all five options present**, lettered, in the message text:

  ```text
  (p)ush     - commit the changes to a.txt/b.txt/c.txt, then push all 3 commits
  (c)ommit only - commit locally, leave unpushed
  (s)tash    - stash the uncommitted changes, leave commits as-is
  (l)eave as-is - don't touch anything, leave dirty and unpushed
  (b)ranch-off-and-commit - new branch from HEAD, commit there, main untouched
  ```

  Note each option is described against the *actual* repo state (naming the
  three files and the two existing commits), not boilerplate.
- **Execution:** harness answered `c`. Commit `abead2b` landed locally, nothing
  pushed. Working tree clean afterwards, branch 3 ahead of `origin/main`.
- **Phase 4:** terse summary, names the leftover unpushed commits explicitly,
  single completed sentinel.

## Assertions

| Check | Result |
|---|---|
| No question widget | Pass (0 `AskUserQuestion` calls) |
| Exactly one closing sentinel, completed variant | Pass |
| All five 3d options presented | Pass |
| Never pushed without `(p)ush` | Pass (commit only, upstream untouched) |
| No write into a pre-existing project memory dir | Pass |

## Note on the discarded first attempt

The first attempt ($0.33) and second ($0.45) were discarded: the first proved
the single-shot driver could not get past Phase 1, and the second wasted its
opening turn on a mangled prompt (see the Run 8 harness findings in `AUDIT.md` -
git-bash rewrote the bare `/wrap` argument to `C:/Program Files/Git/wrap`).
