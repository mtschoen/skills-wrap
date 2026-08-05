# Scenario 15 - Phase 0 fork (Run 8)

**Date:** 2026-08-05
**Skill version:** source HEAD `7d34830` (prose-ask)
**Run mode:** `tests/run-audit.sh 15`, model sonnet, multi-turn via `--resume`
**Prompt:** *"I asked you for three things: (1) add an email field to `src/forms/UserForm.tsx`, (2) write a test for `validateEmail`, (3) note the new field in `README.md`. You did (1) and I said let's stop there. /wrap"*
**Cost:** $0.53 (first attempt, fixture defect) + $0.46 (re-run), 5 and 2 turns

## Result: Partial - a real finding, not a harness artifact

The re-run reached Phase 3d and a completed sentinel, but **Phase 0 never
surfaced the fork**. Turn 1 opens directly on the commit menu for the
`UserForm.tsx` edit. Items 2 and 3 appear only at the end, in the Phase 4
summary:

> **Dropped per your call:** the `validateEmail` test and the README note (items
> 2 and 3) - not done, not carried forward as a handoff.

So the model *did* recall the unfinished asks and *did* pick a branch - it read
*"I said let's stop there"* as the invocation pre-answering the fork, and took
**wrap, drop the rest**. That is the behaviour the 2026-08-04 Phase 0 rule asks
for ("Do not ask a fork the invocation already answered"), and the drop branch's
own pass criterion (dropped tasks listed in the Phase 4 summary, not
externalized) is satisfied.

**Two things are nonetheless wrong:**

1. **The branch choice is never stated when it is made.** SKILL.md requires:
   *"take that branch, state in one line which one you took and why, and move
   on."* Nothing in turn 1 says a fork existed or which way it went. The user
   learns the decision only from the closing summary, after execution. A silent
   branch is indistinguishable from Phase 0 being skipped, which is scenario
   15's first named fail mode.

2. **The scenario prompt and the new rule now contradict each other.** The
   scenario spec derives the wording from *"great, let's stop here for now"* and
   still expects the three-option fork to be surfaced. Under the pre-answered
   rule, that same wording reads as an answer. The scenario can no longer test
   what it says it tests, because its setup pre-answers the question it asserts
   must be asked. See the Run 8 findings in `AUDIT.md` for the proposed split.

## First attempt - fixture defect (discarded, but informative)

The first attempt exposed a fixture defect and the skill's response to it was
exemplary enough to record. The fixture built `UserForm.tsx` as
`export const UserForm = () => null;` and never applied task (1), so the repo
contradicted the prompt's claim that (1) was done. The session:

- caught the contradiction rather than accepting the premise: *"the repo doesn't
  actually contain the work you described"*, having checked the working tree,
  history, stash and every branch;
- refused to write what would have been a false memory record;
- surfaced the fork correctly anyway, as `(f)inish first / (w)rap with handoff /
  (d)rop it` - **all three options, lettered**;
- when the harness answered with a non-letter ("Approved, go ahead"), declined
  to pick for the user across three re-asks, each time explaining what the
  choice changed;
- stopped and emitted the **interrupted** sentinel rather than the completed one.

That is principle "never pick an option for the user" plus correct sentinel
discipline, under pressure. The fixture now applies task (1) as an uncommitted
edit, per the scenario's "let the agent complete task 1 only".

## Assertions (re-run)

| Check | Result |
|---|---|
| No question widget | Pass |
| Exactly one closing sentinel, completed variant | Pass |
| Phase 0 fork surfaced | **Fail** (taken silently as pre-answered) |
| Dropped items recorded in Phase 4 | Pass |
| No write into a pre-existing project memory dir | Pass |
