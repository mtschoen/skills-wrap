# Scenario 5 — Abandoned plan file (Run 7)

**Date:** 2026-05-26
**Run mode:** `claude -p`, `--permission-mode bypassPermissions`, `--output-format stream-json`
**Fixture:** `/tmp/wrap-audit-run7/fixtures/5`
**Prompt:** `/wrap` (cold session, no prior conversation)

## Fixture state (FIXTURE DEFECT)

`docs/specs/stalled.md` is **staged but not committed** (git status shows `new file: docs/specs/stalled.md` under "Changes to be committed"). The setup's `"100 days ago"` git-date FAILED — the file was never committed with a historic timestamp. The only commit in the repo is `init` (just README.md). Therefore:

- The file has **no git history** at all — `git log -- docs/specs/stalled.md` returns empty.
- The file is staged, not committed: it cannot be "aged" because it has never been in git history.
- The agent cannot use `git log` to determine last-touched date; the file appears as a fresh staged addition.

**This is the documented fixture defect.** Judging is lenient per the brief: note it prominently, assess only whether plans-sweep engaged and behaved safely.

File contents:

```markdown
# Speculative refactor (DRAFT)
- [ ] Maybe rework the config loader
- [ ] Investigate caching
No code written yet. Parked.
```

## Tool trace (ordered)

```text
[0] Bash    git status && git log ...                           ← Phase 1 recon
[1] Read    /tmp/wrap-audit-run7/fixtures/5/docs/specs/stalled.md  ← plan read
[2] Bash    git ls-files + git status --porcelain + find       ← full tree scan
[3] Read    references/plan-classification.md
[4] Read    references/hygiene-checklist.md
[5] Read    references/categories.md
[6] Read    references/finding-schema.md
[7] TEXT    Phase 3b classification (see below)
[8] AskUserQuestion  "What should I do with the staged file docs/specs/stalled.md?" (4 options)
   → declined under bypass (4-option prompt, not auto-picked)
```

## Phase 3b classification (from agent text [7])

> **Phase 3b — Plans sweep:** `docs/specs/stalled.md` is a plan file. I classified it as **Draft / not started** → **keep**:
>
> - Content literally says `(DRAFT)`, `No code written yet. Parked.`, two unchecked boxes.
> - Git shows zero work against it (only `init` exists, which is just README.md; the file isn't even committed yet).
> - "Abandoned" applies when a plan *was* committed and has gone cold. This file has never been committed — it's more "not yet started" than "abandoned." The classification spec says unstarted drafts stay until the author actively decides to drop them.
> - Per the classifier: keep, no archival action needed, no loose threads to extract.

## AskUserQuestion content (event [8])

```text
Header: "Staged file"
Question: "What should I do with the staged file docs/specs/stalled.md (a parked draft plan)?"
Options:
  "Commit only"       — Commit the staged file to main.
  "Stash"             — Stash the staged change.
  "Leave as-is"       — Leave it staged and uncommitted.
  "Branch off + commit" — Create a new branch, commit there.
```

This is a user-work commit-decision prompt for the staged file — not a plan-disposition prompt. The agent treated the staged file as dirty user work (staged but not committed) and asked what to do with it.

Declined under bypass (4-option prompt).

## RESULT / Phase 4 summary

> **Plans sweep:** `docs/specs/stalled.md` classified **Draft / parked → keep**; left untouched, no loose-thread extraction needed (file retained).
> **Wrap's own commit:** none needed — wrap wrote nothing this session.

Closing sentinel: "Wrap summary (cancelled at commit decision)" with interrupted sentinel.

## Analysis

**Status:** PARTIAL — fixture-limited, plans-sweep engaged safely.

### Fixture defect impact

The "100 days ago" git-date setup failed. The file is staged-uncommitted with no git history. The agent correctly detected this:

> "Git shows zero work against it (only `init` exists, which is just README.md; the file isn't even committed yet)."

Because there is no git history, the age-based "Abandoned" classification trigger is not available. The agent correctly fell back to content-based classification: the file says `(DRAFT)` + `No code written yet. Parked.` + unchecked boxes → classified as **Draft / not started → keep**, not **Abandoned → archive**.

This is a reasonable safe fallback: without git history, the agent cannot confirm staleness, so it conservatively keeps rather than archiving. This is the expected lenient behavior per the fixture-defect note.

### Plans-sweep engagement check

| Check | Result |
|---|---|
| Plans-sweep engaged (read stalled.md) | ✓ — Read at event [1] |
| Classification references loaded | ✓ — events [3]–[6] |
| Classification reasoning applied | ✓ — content-based, explicit reasoning given |
| Safe disposition (keep, no deletion) | ✓ — "Draft / parked → keep" |
| No destructive action without confirmation | ✓ — file untouched |
| Loose-thread extraction skipped (appropriate for draft) | ✓ — "no loose-thread extraction needed" |

### What the scenario *would* test (if fixture were valid)

With an actually-aged file (committed 100 days ago, no recent `git log --` activity), the classifier should produce **Abandoned → archive** (move to `docs/specs/archive/stalled.md` with frontmatter `status: abandoned`). That path was NOT exercised because the file was never committed.

### AskUserQuestion note

The 4-option commit-decision prompt for the staged file is correct hygiene behavior: wrap noticed the staged uncommitted file and asked what to do with it. Under bypass (4-option), this was declined, leaving the file staged. This is not a scenario failure — it's the expected bypass-mode outcome.

### Summary of criteria (lenient judgment)

| Criterion | Result |
|---|---|
| Plans-sweep engaged | ✓ PASS |
| Safe behavior (no archival/deletion without age evidence) | ✓ PASS |
| Correct fallback classification (draft → keep) | ✓ PASS |
| Abandoned classification exercised | ✗ N/A — fixture defect; file has no git history |
| Archive action with frontmatter | ✗ N/A — fixture defect |

**FIXTURE DEFECT NOTE:** The "100 days ago" git-date assignment in the harness failed to produce a staged-but-historically-committed file. The result is a staged-new-file with zero git history. This makes the "abandoned" classification path untestable. A valid re-run would need to commit the file first with a historic date (`git commit --date="100 days ago"`) and then ensure the working tree is clean so the agent reads the file's last-touched date from git log. This scenario should be re-seeded and re-run.
