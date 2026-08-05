# Scenario 21 - pre-answered fork, clean room (Run 9)

**Date:** 2026-08-05
**Skill version:** source HEAD `ee1155e`; `SKILL.md` unchanged since `ccb5112`
**Run mode:** `tests/run-audit.sh -c 21`, model sonnet, 2 turns,
`WRAP_AUDIT_CONFIG_DIR` set, fixture outside `$HOME`
**Cost:** $0.34

## Result: Partial, and identical to Run 8b - which is the finding

The invocation answers the fork itself (*"You finished (1). Wrap it up and drop
the rest."*). The clean-room run behaves exactly as Run 8b's did:

- **The fork was not re-asked.** Turn 1 goes straight to scope, memory offload
  (nothing worth externalizing) and the Phase 3d commit question.
- **The branch was honoured.** The summary reads *"**Dropped, not handed off**
  (per your instruction): writing a test for `validateEmail`; noting the new
  field in `README.md`"*. No handoff artifact exists in the repo, and the run
  wrote **no memory file at all** - the scratch corpus has entries for scenarios
  15 and 20 and none for 21. A handoff that had been quietly written to memory
  instead of the repo would have shown up there.
- **The branch is still announced only in the summary, after acting.** Now 0 of
  4 runs, across two formulations of the rule.

The clean room is what makes that last line worth recording. The rule's failure
had a plausible environmental explanation - the operator's `SessionStart` hook
and forty-odd competing skills crowding a soft instruction. With all of that
removed, and with the operator's own memory files out of reach, the behaviour is
unchanged. It is the skill's own instruction not binding, not interference.

**This does not change the standing decision** (AUDIT.md, Run 8b): the rule stays
a soft criterion, and is not to be written a third time without a mechanism that
lands it. What the clean room adds is that a third attempt at *wording* now has
one fewer excuse available.

## Harness note - the check was wrong, not the run

This scenario first reported `FAIL wrong-branch (handed off work the user said to
drop)`. It had not. The check matched `handoff (note|plan|file)` anywhere in the
trace, and the session had quoted the fork's own option text back while asking:

> ...it gets externalized as a handoff plan file or memory entry rather than
> being lost.

The check now looks for a handoff artifact on disk instead of a phrase in prose.
This is the same family as the Run 8 harness defects: a text match over a trace
that contains the skill's own vocabulary measures the skill's text, not the
session's behaviour.
