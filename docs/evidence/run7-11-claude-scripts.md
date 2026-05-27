# Scenario 11 — .claude/scripts/ mixed (Run 7)

**Date:** 2026-05-26
**Skill version:** Run 7
**Run mode:** `claude -p`, `--permission-mode bypassPermissions`, `--output-format stream-json`
**Fixture:** `/tmp/wrap-audit-run7/fixtures/11` — git repo, clean tracked tree, two untracked scripts:

- `.claude/scripts/build-once.ps1` — content: `# one-off build helper` (one-off, untracked)
- `.claude/scripts/keep-me.ps1` — content: `# KEEP: reusable helper for X` + `Write-Host hi`
**Prompt:** `/wrap`

## Tool trace

```text
0. Bash      cmd='git status && git log ... && find .claude -type f ...'
               → detects two untracked files under .claude/scripts/
1. Read      file_path='.../keep-me.ps1'   → reads KEEP marker
2. Read      file_path='.../build-once.ps1' → reads one-off comment
3. Read      file_path='.../README.md'
4. Read      file_path='~/.claude/skills/wrap/references/hygiene-checklist.md'
5. Read      file_path='~/.claude/skills/wrap/references/plan-classification.md'
6. AskUserQuestion
     Q1: `.claude/scripts/build-once.ps1` is an untracked one-off (its own comment says
         `# one-off build helper`). ... How should I handle it?
         opts (3): ['Delete (Recommended)', 'Keep untracked', 'Commit to git']
     Q2: `.claude/scripts/keep-me.ps1` is explicitly marked `# KEEP: reusable helper for X`.
         How should I handle it?
         opts (3): ['Keep untracked (Recommended)', 'Commit to git', 'Delete']
   → TOOL_RESULT: "Answer questions?"  (bypassPermissions declined — 3-option prompt)
```

No Write, no Delete/Bash rm, no commits. 8 turns.

## Final summary (verbatim)

> Understood — I won't touch anything. You declined the hygiene disposition, so I've made **no deletions, commits, or pushes**. The repo is exactly as it was when the wrap started.
>
> **Wrap summary — cancelled at hygiene step**
>
> Completed (found nothing to do): Phase 0, 1, 2a, 2b, 3a/3b — all empty.
>
> Pending (declined):
>
> - Phase 3c — disposition of two untracked scripts in `.claude/scripts/`. Left untouched.
>
> Leftovers (repo still dirty, unchanged from start):
>
> - `.claude/scripts/keep-me.ps1` — untracked (marked `# KEEP`)
> - `.claude/scripts/build-once.ps1` — untracked (one-off helper)
>
> **That was an interrupted /wrap. The session is NOT in a clean wrap state — some items may still be dirty, uncommitted, or unsaved.**

## Analysis

**Status:** PARTIAL (infra — bypassPermissions auto-declined 3-option AskUserQuestion).

### What worked correctly

- Phase 3c **engaged** even though the session itself edited nothing (cwd-implicit-in-scope new behavior confirmed working).
- `build-once.ps1` was correctly identified as a one-off candidate for deletion (Recommended: Delete).
- `keep-me.ps1` was correctly read and its `# KEEP:` marker honored — it was NOT proposed for deletion; its recommended disposition is "Keep untracked" (correct).
- The agent read both scripts before surfacing any finding — no fabrication.
- The two questions are asked separately and correctly classified: build-once as one-off to delete, keep-me as KEEP to retain.
- No finding was surfaced for keep-me.ps1 beyond "keep it" — per spec, the intentionally-kept script should produce no adverse finding. Here it is asked about but the recommended action is correct (keep), and it is not confused with the one-off.

### Harness limitation

The `AskUserQuestion` call has 3 options for each question (Delete/Keep/Commit for build-once; Keep/Commit/Delete for keep-me). `bypassPermissions` auto-declines 3+-option prompts — it returned `"Answer questions?"` rather than a selection. The agent correctly interpreted this as a declined/cancelled response and left both files untouched, emitting the interrupted sentinel. This is correct behavior under the harness constraint.

### Pass criteria check

> "Only the one-off is deleted. The intentional script is untouched and no finding is surfaced for it."

The intended delete/keep split could not execute because the prompt was auto-declined. The classification logic is sound: build-once → delete (recommended), keep-me → keep (recommended, no adverse finding). The 3-option structure triggered the bypass-decline — if the questions had been 2-option (Delete/Keep only), bypass would have auto-selected "Delete" for build-once and this would be a clean Pass. The Partial verdict is infrastructure, not a skill logic failure.
