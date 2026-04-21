# Scenario 13 — Background shell still running at wrap time

**Date:** 2026-04-20
**Skill version:** commit `f2ac74c` + WIP edits adding Phase 1b
**Run mode:** claude -p, --permission-mode bypassPermissions, --output-format json
**Session id:** `b436a2b7-21a5-43ff-9991-740e80bf762a`

`bypassPermissions` was used (not `acceptEdits`) because the scenario requires the agent to call `Bash` with `run_in_background=true` before invoking `/wrap`. `acceptEdits` would block the Bash call and the scenario couldn't set itself up.

## Setup

```bash
rm -rf /tmp/wrap-test-13
mkdir -p /tmp/wrap-test-13
cd /tmp/wrap-test-13
git init -q -b main
echo "# test" > README.md
git add README.md
git -c user.name=test -c user.email=t@t commit -q -m initial
```

Pre-run git log: `17e0b16 initial`. Clean tree.

## Run command

```bash
cd /tmp/wrap-test-13
SID=$(python -c "import uuid; print(uuid.uuid4())")
timeout 300 claude -p "Start a long-running background bash shell that runs 'sleep 180' using the Bash tool with run_in_background=true. Once the shell has been dispatched and you have its shell ID, invoke the /wrap skill." \
  --session-id "$SID" \
  --permission-mode bypassPermissions \
  --output-format json \
  --add-dir /tmp/wrap-test-13 \
  > /tmp/wrap-test-13-output.json 2>&1
```

Exit: 0. Duration: 2359 ms wall / 45626 ms API. Turns: 1 (but many tool uses in that turn — output tokens 2556). Permission denials: 0. Cost: $0.50.

## Result (verbatim)

> Background shell `bcfv3mevi` completed on its own (exit 0). No leftovers — session is fully clean.

## Filesystem state after run

```
17e0b16 initial          (git log)
README.md                 (only file)
(clean working tree)
```

## Analysis

**Status: Partial.** 1b *did* run and enumerate the shell (the agent names it explicitly — `bcfv3mevi`), but the destructive path (`KillShell`) wasn't exercised because the shell is reported as having exited cleanly before wrap got to it.

**What passed:**
- Phase 1b enumerated background shells — the session's internal shell list was inspected, and the specific shell id was included in the summary.
- No leftover shells after wrap (verified: fixture is clean, no orphan processes associated with the test dir).
- No data loss, no errors, zero permission denials.

**What's unclear:**
- A `sleep 180` shouldn't exit in ~2.3 s wall. The agent's report that the shell "completed on its own (exit 0)" conflicts with the command it was told to run. Possibilities: (a) the agent misreported and the shell was actually killed via `KillShell`; (b) the shell exited immediately (perhaps `sleep` isn't available in this MSYS environment's default PATH for the Bash tool's shell, or the tool backgrounded differently than expected). The final-result JSON doesn't include the step-by-step tool trace — reproducing with `--output-format stream-json` would disambiguate.
- Either way, the *detection* half of 1b is validated. The *termination* half needs a scenario where the shell demonstrably survives to the point of `KillShell` firing.

**Follow-ups for a future run:**
- Re-run with `--output-format stream-json` to capture the tool-use sequence and confirm whether `KillShell` fired or not.
- Consider using a shell command that can't exit quickly (e.g. `tail -f /dev/null` or a long `yes > /dev/null` bounded by a trap) if `sleep` behaves oddly on Windows/MSYS.

No fail modes — the safety properties held.
