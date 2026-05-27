# Scenario 4 — Completed plan file (Run 7)

**Date:** 2026-05-26
**Run mode:** `claude -p`, `--permission-mode bypassPermissions`, `--output-format stream-json`
**Fixture:** `/tmp/wrap-audit-run7/fixtures/4`
**Prompt:** `/wrap` (cold session, no prior conversation)

## Fixture state

`docs/specs/old-plan.md` (git-tracked):

```markdown
# Feature X — implementation plan (COMPLETED)
- [x] Implement parseX in src/x.py
- [x] Wire X into the pipeline
- [x] Add tests (all green)
All work merged and shipped.
```

Repo: clean working tree, 3 tracked files (`README.md`, `x.py`, `docs/specs/old-plan.md`), no upstream. Commit message: "completed feature + plan".

## Tool trace (ordered)

```text
[0] Bash    git status && git log ...                           ← Phase 1 recon
[1] Bash    git ls-files (fallback — first command exited non-zero)
[2] Bash    git ls-files + find (clean list)
[3] Read    /tmp/wrap-audit-run7/fixtures/4/docs/specs/old-plan.md  ← plan read
[4] Read    /tmp/wrap-audit-run7/fixtures/4/README.md
[5] Read    /tmp/wrap-audit-run7/fixtures/4/x.py
[6] Read    references/plan-classification.md
[7] Read    references/hygiene-checklist.md
[8] Read    references/categories.md
[9] TEXT    Phase 3b classification (see below)
[10] AskUserQuestion  "Delete it?" / "Keep it as-is"  ← 2-option prompt
    → auto-picks "Delete it" (first option, bypass 2-option behavior)
    → BUT agent reported it as "dismissed" and used interrupted sentinel
```

Wait — I need to re-examine event [10] behavior. The AskUserQuestion output showed the agent text said "The question was dismissed rather than answered." Let me re-verify.

## Phase 3b classification (from agent text [9])

> **Phase 3b (plans sweep):** One finding — `docs/specs/old-plan.md`:
>
> - **State: Completed.** Explicitly titled "(COMPLETED)", all three checkboxes ticked, "All work merged and shipped." The closing work is in commit `b0a1b94`, and `parse_x` exists in `x.py`.
> - **Loose-thread scan: none.** No open questions, future ideas, or ambiguous items.
> - **Classification: DELETE** (per plan-classification.md: completed + all work merged = delete; git history preserves the file).

## AskUserQuestion content (event [10])

```text
Question: "Phase 3b found one completed plan: docs/specs/old-plan.md — titled '(COMPLETED)', all boxes
ticked, 'All work merged and shipped' (closing work is in commit b0a1b94; parse_x exists in x.py). No
loose threads to extract. The wrap plan-classifier says completed + git-tracked plans should be deleted
(git history preserves them; keeping as 'documentation' is flagged as a conservative override to avoid).
Delete it?"

Options:
  "Delete it"   — rm docs/specs/old-plan.md and auto-commit as wrap hygiene. Recoverable from git history.
  "Keep it as-is" — Leave the completed plan file in place.
```

This is a **2-option** AskUserQuestion. Under bypassPermissions, 2-option prompts are auto-picked (first option = "Delete it").

## Agent behavior after AskUserQuestion

Despite being a 2-option prompt (expected to auto-pick "Delete it" under bypass), the agent text reports:

> The question was dismissed rather than answered. Per wrap's failure-handling rule, a denied `AskUserQuestion` counts as a user cancel — I stop here and report partial state with the interrupted sentinel.

**Finding:** The auto-pick did NOT happen. The agent treated the prompt as dismissed/denied and used the interrupted sentinel instead of proceeding with deletion. This is unexpected under the 2-option bypass rule documented in Run 6 (which says 2-option prompts auto-pick the first option).

## RESULT / Phase 4 summary

> **Pending (not done — cancelled):**
>
> - Plan deletion for `docs/specs/old-plan.md` — the commit-wrapped deletion was pending approval; cancel signal received; no file was deleted.

Closing sentinel: "That was an interrupted /wrap..." (interrupted, not completion sentinel).

## Fixture state after run

`docs/specs/old-plan.md` still exists — NOT deleted.

## Analysis

**Status:** PARTIAL.

### What passed

| Criterion | Result |
|---|---|
| Phase 3b correctly classifies plan as Completed | ✓ — "State: Completed", "Classification: DELETE" |
| Correct classification (DELETE not archive/keep) | ✓ — correctly identified as delete, not conservative keep |
| Loose-thread scan ran before classification | ✓ — "Loose-thread scan: none" |
| No false archival | ✓ — did not archive to `docs/specs/archive/` |
| AskUserQuestion offered Delete first (correct default) | ✓ — "Delete it" is option 1 |

### What is Partial / DRIFT

Under bypassPermissions with a **2-option** AskUserQuestion, the harness auto-picks the first option. The expectation (per Run 6 evidence) is that a 2-option prompt auto-picks "Delete it", causing the deletion and wrap-commit to execute. This would have been a full Pass for scenario 4 (plan deleted, committed).

Instead, the agent treated the response as a cancel/dismiss and did NOT proceed with deletion. The `old-plan.md` file remains in the fixture.

**Possible** explanations:

1. The 2-option auto-pick behavior is not fully reliable across all invocations — the agent's fallback behavior when it doesn't receive a clear signal is to treat it as a cancel.
2. The AskUserQuestion had a "header" field or other formatting difference that caused the bypass logic to behave differently.
3. The bypass auto-pick happened but the agent misread the returned value as a decline.

**DRIFT flag:** The plan file was NOT deleted despite correct classification. This is the scenario's core deliverable (deletion + wrap commit). A conservative-keep would be equally flagged; here the agent explicitly intended to delete but stopped when the prompt was treated as cancelled. The net result is the same: file persists. Flag as PARTIAL with DRIFT.

**Safety note:** The conservative behavior (not deleting without explicit approval) is safe — it never destroys content without user confirmation. The spec flags "conservative-keep/archive as DRIFT worth noting" (our instructions), which applies here.

### Sentinel

Interrupted sentinel correctly emitted (not completion sentinel) since a pending action was unresolved. This is correct behavior.

### Summary of criteria

| Criterion | Result |
|---|---|
| Completed classification correct | ✓ PASS |
| DELETE action prescribed (not archive/keep) | ✓ PASS |
| Deletion executed + wrap commit | ✗ PARTIAL — AskUserQuestion treated as cancelled, deletion not executed |
| Git log shows deletion in hygiene commit | ✗ PARTIAL — commit did not land |
| Conservative-keep/archive avoided | ✓ (agent chose delete path, just didn't execute) |
