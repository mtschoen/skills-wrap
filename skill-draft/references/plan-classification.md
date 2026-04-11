# Plan Classification

How to classify plan files during Phase 2b (plans sweep), and the safety rule that must precede any deletion.

## Where to look

Scan every repo in scope for plan-like files under any of these paths:

- `docs/superpowers/specs/*.md`
- `docs/superpowers/plans/*.md`
- `docs/specs/*.md` / `docs/plans/*.md`
- `PLAN.md` / `TODO.md` at repo root
- `.plans/*.md` if the directory exists
- Any in-conversation draft the agent remembers creating but not saving

## Classification states

For each file found, determine its state:

| State | Evidence to look for | Example |
|---|---|---|
| **Completed** | Code referenced in the plan is merged/pushed. Checkboxes all ticked. Commit history includes the plan's closing work. | A plan for "add auth module" where `src/auth/` exists and tests are green. |
| **Superseded** | A newer plan covers the same ground, or the approach was reversed. | Two plans on the same topic with overlapping file lists; keep the newer one. |
| **Abandoned** | No progress for weeks. Mentioned in past conversations as "not doing that anymore." No code changes against it. | A plan last touched 6 weeks ago with no commits tying back to it. |
| **In progress** | Active work. Uncommitted changes sit against files the plan names. Recent commits tie back. | Dirty tree + plan referenced by the current session's work. |
| **Draft / not started** | Created but no work against it yet. Intentional deferral, not abandonment. | A plan file exists; git log shows only the creation commit. |

## The "extract loose threads first" safety rule

**Before any plan file is deleted or archived, the agent must scan its content for loose threads and externalize them first.** This rule is non-negotiable and is the main reason wrap is trusted to delete files at all.

### What counts as a loose thread

Any sentence or bullet in the plan that expresses:

- An unresolved question ("do we need X?", "unclear how Y handles Z")
- A future intention ("we should fix that later", "come back to this once Q lands")
- A warning or pitfall ("watch out for W", "don't forget that…")
- An idea or option that wasn't taken but might be revisited ("alternative: …", "could also …")
- A cross-reference to an incomplete area of the project ("this depends on the auth rewrite")

### Where loose threads go

- Unresolved questions + future intentions that are user-preference-shaped → memory (feedback or reference type)
- Warnings or pitfalls tied to a specific file/function → inline code comment OR `CLAUDE.md` note
- Alternatives considered → commit message trailer on the deletion commit, so git history preserves them
- Cross-references to other work → a new smaller plan file OR GitHub issue, never left dangling

### Order of operations

1. Read the plan file in full.
2. Emit candidate loose threads as a list, with proposed destinations.
3. Get user approval on the whole list (batch).
4. Execute the externalization (write the memory, edit CLAUDE.md, open the issue, etc.).
5. **Only now** delete or archive the source plan.

If the loose-thread extraction is rejected or fails, the source plan stays. Skipping step 3 or 4 is a bug.

## Actions per state (post-extraction)

| State | Action |
|---|---|
| **Completed + tracked in git** | Delete outright (`rm` + commit). Git history preserves the file for recovery. |
| **Completed + untracked** | Ask with bias-to-delete. Show path + first few lines + "delete? [Y/n]". |
| **Superseded** | Delete. Commit message notes which plan superseded it. |
| **Abandoned** | Archive — move to `<plan-dir>/archive/` (create if needed), not delete. Add a one-line note to the file's frontmatter: `status: abandoned, YYYY-MM-DD`. |
| **In progress** | Keep untouched. Optionally add a status frontmatter tag if the plan doesn't already have one. |
| **Draft / not started** | Keep. This is intentional deferral, not cruft. |
