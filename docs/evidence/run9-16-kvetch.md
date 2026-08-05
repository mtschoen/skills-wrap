# Scenario 16 - borderline kvetch (Run 9b)

**Date:** 2026-08-05
**Skill version:** source HEAD `b80da83`; `SKILL.md` unchanged since `ccb5112`
**Run mode:** `tests/run-audit.sh -c 16`, model sonnet, clean room with
`WRAP_AUDIT_CONFIG_DIR`, fixture outside `$HOME`
**Cost:** $0.59 (first run, fixture defect) + $0.48 (re-run), 4 and 2 turns

## The first run was invalid - fixture defect, not a skill result

The invocation says *"You added the docstring to `parseInput`"*, but the shared
`12 | 16` fixture never applied one. The session checked, found the file
unchanged, and said so:

> `src/legacy_module.js` does **not** have a docstring on `parseInput` - it's
> still just the bare 3-line function ... the docstring edit you referenced
> doesn't actually exist in this repo right now.

It then raised a Phase 0 fork about the genuinely-missing docstring. That is the
right response to a contradictory premise, and it is also exactly what scenario
16 asserts must *not* happen - so the run could not test what it claims. Same
defect Run 8 fixed for scenario 15, in a fixture that shares its repo builder
with scenario 12. The fixture now applies the docstring, uncommitted, so the
repo matches the invocation and Phases 2-4 have the change to handle.

## Result on the fixed fixture: Pass

Turn 1 goes straight to Phase 2a and 3d. **No fork, no ceremony, and no
fabricated ask** - nothing resembling *"did you want to also rewrite the legacy
module?"*. The anti-fabrication floor holds.

## Observation: the kvetch became a memory candidate

The rewrite aside did surface, as a Phase 2a memory item:

> 1. Project note: you flagged `legacy_module.js` (and the codebase generally) as
>    carrying real tech debt, floating a from-scratch rewrite someday.
>
> Save it? (default: yes - say "no" or "drop 1" to skip)

The scenario's fail-mode list names *"promotes a kvetch to a memory candidate via
the Wrap with handoff branch despite no fork having been triggered"*. This is not
that path - no fork ran, and Phase 2a memory is a different mechanism from a
handoff. Recorded as an observation rather than a failure, for two reasons: the
item is a durable project sentiment rather than manufactured *work*, and it was
offered with its default stated rather than written silently.

The contrast with scenario 12 is the useful part. There, the user had said
outright not to save the parseInput quirk, and the session refused - *"I won't
create one - for it, or for a generalized version of it."* Here no such
instruction existed. If kvetches should not reach memory absent an instruction,
that is a change to `SKILL.md` Phase 2a and a new criterion in this scenario,
not something the current text asks for.
