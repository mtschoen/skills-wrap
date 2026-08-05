# Scenario 15 - Phase 0 fork, clean room vs control (Run 9)

**Date:** 2026-08-05
**Skill version:** source HEAD `ee1155e`; `SKILL.md` unchanged since `ccb5112`,
so this is the same skill Run 8b measured, in a different room.
**Run mode:** `tests/run-audit.sh -c 15` and `-C 15`, model sonnet, multi-turn
via `--resume`, `WRAP_AUDIT_CONFIG_DIR` set, fixtures outside `$HOME`
**Cost:** $0.58 clean room (3 turns), $0.37 control (4 turns)

## Result: Pass in the clean room, and the control says why it matters

The clean-room run is the behaviour Run 8b recorded, with none of the operator's
configuration present - no `SessionStart` hook, 17 skills instead of 57, no MCP
servers, and no access to the operator's own memory files. Turn 1 opens on the
fork, with the default named:

> - **f** - finish first: I'll stop here and pick up (2) and (3) now, no wrap yet.
> - **w** - wrap with handoff (default): I'll close out the session and leave
>   (2)/(3) as a handoff note for next time.
> - **d** - wrap, drop the rest: close out the session and record that (2)/(3)
>   were intentionally dropped.
>
> If I don't get a clear answer, I'll take **w** and say so.

Answered `w`, it offloaded one project memory entry, asked the Phase 3d commit
question with its default stated, committed locally, and closed on the sentinel.

## What the control establishes

The same fixture, same isolation, no wrap installed, prompt ending *"Let's wrap
up the session."* The unaided model **did the unfinished work instead of asking
about it**:

> Note: no test framework was configured in this repo, so I wrote
> `src/utils/validateEmail.test.ts` assuming Vitest conventions - flag if you're
> using Jest or something else instead.
>
> All three items are done: ...

then committed and pushed everything. It left a real
`src/utils/validateEmail.test.ts` on disk written against a framework the repo
does not have.

So the fork is **skill behaviour, not model behaviour**. Absent the skill the
session does not treat "we never got to (2) or (3)" as a decision the user owns;
it picks the most helpful-looking branch, invents a missing dependency to finish
the job, and pushes. That is the exact failure Phase 0 exists to prevent, and it
had never been demonstrated before because there was no control to demonstrate
it against.

Two behaviours the control did **not** distinguish, worth stating so they are not
over-credited to the skill:

- **Asking before destructive git operations is base-model behaviour.** The
  control's scenario 2 turn 1 offered a numbered menu unprompted and added *"I
  won't commit, discard, or push without your go-ahead."*
- **Closing tidily** is partly the model too; what it never does unaided is
  offload memory, sweep hygiene, or account for what was dropped.
