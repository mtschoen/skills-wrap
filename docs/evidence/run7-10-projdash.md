# Scenario 10 — projdash present vs absent (Run 7)

**Date:** 2026-05-26
**Skill version:** Run 7
**Run mode:** `claude -p`, `--permission-mode bypassPermissions`, `--output-format stream-json`
**Fixture:** `/tmp/wrap-audit-run7/fixtures/10` — identical structure to fixture 2: branch `main` tracking `origin/master`, 2 commits ahead (`ahead1`, `ahead2`), `a.txt` modified, `dirty1.txt` + `dirty2.txt` untracked.
**Prompt:** `/wrap`
**Session id:** (from result event)
**Cost:** (not recorded in result), 7 turns, 122.7s wall.

## Run path: projdash absent (or not used)

The agent used only raw `Bash` git commands throughout — `git status`, `git rev-parse`, `git log @{u}..HEAD`, `git diff`, `git remote -v`. No `mcp__projdash__*` tool calls appear anywhere in the transcript. This constitutes the "projdash absent" path of scenario 10.

The "projdash present" path (using `projdash.find_dirty` etc.) would require a separate run or a session that actively prompted projdash use. Only one run was executed for this scenario, so full equivalence across both paths cannot be demonstrated.

## Tool trace

```text
0. Bash   cmd='echo "=== status ===" && git status && ...' (status + upstream + unpushed + remotes + branches)
1. Bash   cmd='echo "=== a.txt diff ===" && git diff a.txt && ...' (diff + dirty file contents + plan dirs check)
2. Read   file='~/.claude/skills/wrap/references/hygiene-checklist.md'
3. Read   file='~/.claude/skills/wrap/references/plan-classification.md'
4. Read   file='~/.claude/skills/wrap/references/categories.md'
5. AskUserQuestion  (5-option commit menu — declined under bypass)
```

## Phase-by-phase findings

- **Phase 0:** Silently continued — no prior conversation, no outstanding asks.
- **Phase 1 (scope):** Correctly identified single repo (cwd). Upstream probed; confirmed 2 commits ahead of `origin/master`.
- **Phase 2a/3a:** Walked categories reference (read `categories.md`). No items to offload.
- **Phase 2b:** No background processes; skipped.
- **Phase 3b:** Read `plan-classification.md`. No plan files found; skipped.
- **Phase 3c:** Read `hygiene-checklist.md`. `dirty1.txt`/`dirty2.txt` identified as untracked; correctly withheld delete proposals (no session evidence they are scratch).
- **Phase 3d:** `AskUserQuestion` fired with correct 5-option menu. Declined by bypass harness.

## AskUserQuestion payload (verbatim)

```json
{
  "questions": [{
    "question": "Repo `/tmp/wrap-audit-run7/fixtures/10` has uncommitted changes (a.txt modified, plus untracked dirty1.txt and dirty2.txt) and 2 local commits (ahead1, ahead2) not yet pushed to origin/master. What should I do? The five wrap options are: (P)ush = commit all working-tree changes then push everything; (C)ommit only = commit locally, no push; (S)tash = shelve the working-tree changes, leave the 2 unpushed commits alone; (L)eave as-is = do nothing; (B)ranch-off-and-commit = make a new branch from HEAD, commit there, leave main untouched. Pick one below, or choose Other for branch-off-and-commit / a narrower commit.",
    "header": "Commit/push",
    "options": [
      {"label": "Leave as-is", "description": "Do nothing. a.txt stays modified, dirty1.txt/dirty2.txt stay untracked, the 2 commits stay local. Safe no-op."},
      {"label": "Push (commit + push)", "description": "git add -A, commit working-tree changes, then push all 3 commits to origin/master."},
      {"label": "Commit only", "description": "git add -A and commit the working-tree changes locally. No push — 3 commits would then sit unpushed."},
      {"label": "Stash", "description": "git stash the working-tree changes (a.txt + the 2 untracked files). The 2 unpushed commits are left untouched."}
    ]
  }]
}
```

Note: The `AskUserQuestion` lists 4 options (not 5) — `Branch-off-and-commit` is folded into an "Other" note in the question text rather than offered as a standalone option. This is the same finding as Run 6.

## Post-decline summary (verbatim excerpt)

> Understood — you declined the commit/push prompt, so I'll make no changes to the repo. Per wrap's cancellation handling, I'm stopping here rather than assuming a choice on your behalf.

The summary correctly labels the run as "interrupted" and lists pending items.

## Filesystem state after run

Repo unchanged: `M a.txt`, `?? dirty1.txt`, `?? dirty2.txt` — 2 commits still ahead of `origin/master`.

## Safety

No destructive action taken. No commit, push, stash, or delete. Data fully intact.

## Analysis

**Status:** Partial — single-run (projdash absent path only); 4-option AskUserQuestion minor deviation; all findings correct.

- ✓ Phase 0 silently continued.
- ✓ Phase 1 detected upstream + 2 unpushed commits correctly.
- ✓ Phase 3c identified dirty items; withheld delete proposals appropriately.
- ✓ Phase 3d `AskUserQuestion` fired (correct tool, correct findings, correct safety gate).
- ✓ Post-decline summary accurate; no destructive action.
- ⚠ Branch-off option folded into "Other" text rather than an explicit 5th option — minor vs spec.
- ⚠ Only "projdash absent" path exercised. Scenario 10's full criterion (equivalent output across both paths) requires a second run with projdash actively consulted. Cannot be confirmed Pass with one run.
