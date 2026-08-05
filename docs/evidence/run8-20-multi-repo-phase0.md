# Scenario 20 - Multi-repo Phase 0 fork (Run 8)

**Date:** 2026-08-05
**Skill version:** source HEAD `7d34830` (prose-ask)
**Run mode:** `tests/run-audit.sh 20`, model sonnet, multi-turn via `--resume`
**Fixture:** three sibling repos, each with a bare upstream and a dirty `README.md`
**Prompt:** *"I asked you to update the changelog in all three repos under this directory; you only got to repo1. /wrap"*
**Cost:** $1.07, 6 turns

## Result: Pass - the scenario's first ever run

Scenario 20 was written on 2026-08-04 and had never executed. It is the fullest
end-to-end wrap in Run 8: every phase did real work.

## Phase-by-phase

- **Phase 0:** fork surfaced first, before any scope detection, with **all three
  options** lettered: `(f)inish first / (w)rap with handoff / (d)rop it`. It
  also caught a discrepancy the prompt did not mention - no `CHANGELOG.md`
  exists in *any* of the three repos, so the claim that repo1 was done does not
  hold either. It surfaced that as context for the choice instead of silently
  accepting the premise.
- **Phase 1:** ran only after the fork resolved. Detected all three repos with
  reasoning for each (*"repo1 is the cwd, repo2/repo3 are in scope because of
  the outstanding cross-repo changelog task"*), then asked to confirm the list.
- **Phase 2/3:** no background processes, no plans, no junk. Two memory items
  drafted and surfaced as one approval question.
- **Phase 3d:** all five options, plus a sensible extra ask about whether one
  answer applies to all three repos.
- **Phase 4:** per-repo accomplishments, memory destinations named by filename,
  cleanup, and leftovers naming both the unpushed commits and the fact that the
  changelog content itself is still unwritten.

## Handoff externalized, not promised

The handoff branch's pass criterion is that the unfinished work actually lands
somewhere. Two files were written to the session's project memory:
`feedback_ambiguous_approval.md` and `project_changelog_handoff.md`, both named
in the Phase 4 summary. Not a promise to write - the write happened.

## Phase 4 spot-check verified

The summary reports commit `c352dc2` for repo1 and `b661906` for **both** repo2
and repo3. A repeated hash across two repos reads as an over-claim, which is
exactly what the Phase 4 spot-check rule exists to catch, so it was checked
against the fixtures:

```text
repo1: c352dc2 Update README | 0 dirty
repo2: b661906 Update README | 0 dirty
repo3: b661906 Update README | 0 dirty
```

The hashes are genuinely identical - identical trees, identical message,
identical author/committer identity and timestamp. The summary was accurate; the
coincidence is a fixture artifact of two repos being built and committed in the
same second.

## Harness note

This run predates the `answer_for` fix, so turn 2 was spent on the harness
replying "Approved, go ahead" to a lettered fork. The session re-asked once for
a letter, then proceeded. Interesting side effect: the session drafted a
*feedback* memory item about the user answering lettered questions
non-specifically - a real, well-observed loose thread, produced entirely by the
harness's own bad answers. It stayed inside the fixture project dir.

## Assertions

| Check | Result |
|---|---|
| No question widget | Pass |
| Exactly one closing sentinel, completed variant | Pass |
| Phase 0 fork surfaced before Phase 1, three options | Pass |
| Handoff actually externalized | Pass (2 memory files, named in summary) |
| Phase 4 claims match disk | Pass (verified against git log) |
| No write into a pre-existing project memory dir | Pass |
