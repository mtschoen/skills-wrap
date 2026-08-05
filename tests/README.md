# Pressure-test harness

`run-audit.sh` builds a throwaway fixture per scenario in
`docs/pressure-scenarios.md`, runs the **installed** wrap skill against it
headlessly, and checks the captured tool trace.

This replaces the Run 7 harness, which lived in `/tmp` and did not survive a
reboot (AUDIT.md open item #8).

## Running it

```bash
./run-audit.sh -l                # list scenarios
./run-audit.sh                   # every headless-capable scenario
./run-audit.sh -m opus 17 18 19  # named scenarios, specific model
./run-audit.sh -o ~/wrap-audit-run8   # keep fixtures somewhere findable
```

**This costs real money.** Run 7's 20-scenario sweep was $11.13 on the models of
the day. Start with a couple of scenarios.

It tests whatever is installed at your harness's skills directory, not this
checkout. Install first, or you are auditing the previous version.

## What it does and does not decide

The checks are a **mechanical floor**, not the pass criteria:

- every run: no question widget was used (SKILL.md principle 8), exactly one
  closing sentinel was emitted, and nothing was written into a pre-existing
  agent-memory project directory
- scenario 11: the `# KEEP:` script survived
- scenario 13: `TaskStop` actually fired
- scenarios 17/18: `.env` and `data/app.sqlite` survived; `Library/` survived the
  keep-warm directive
- scenario 19: the junk-files check stayed silent on a no-build session

Everything else - did it classify the plan right, did it extract the loose thread
before deleting, was the summary honest - needs a human reading the trace against
the scenario's pass criteria. A green run is permission to review, not a pass.

## Safety - read this before running

Each scenario runs under `--permission-mode bypassPermissions`. That is not
incidental: it is the only way to exercise wrap's destructive paths (deleting
scratch, committing, stopping tasks) without a human answering every gate.

**The fixture is not a sandbox.** It bounds what wrap has *reason* to touch, not
what it *can* touch. `cd`-ing into a fixture sets the working directory and
confines nothing: the agent under test has unrestricted tools and can read
credentials, reach the network, and write outside the fixture. Two consequences
worth being deliberate about:

- **Run it on a machine whose secrets you would accept an agent reading.** If
  that is not true for yours, run the harness in a container or a VM. Nothing in
  this script provides confinement, and no flag short of real OS-level isolation
  would - `--allowedTools` is not a substitute, since permitting `Bash` at all is
  equivalent to full access.
- **Wrap writes durable memory by design** (Phase 2a), into the real agent
  memory root. The harness snapshots that root around every scenario and fails
  the run on a write into a project directory that already existed; new
  fixture-owned directories are reported as debris to delete. Point
  `AGENT_SESSIONS_DIR` at the memory root if yours is not `~/.claude/projects`.

Never point this at a real repo.

Fixture roots are named `wrap-test-*` so `scripts/find-unwrapped.*` filters them
out and any agent-memory directory they generate is identifiable as test debris.
Fixtures are left on disk after the run so traces stay reviewable; delete the
output directory when you are done.

## Scenarios that cannot run headless

7 (merge conflict) and 8 (user cancel) need a live interactive session: there is
no way to inject a real `Ctrl+C` or a live `MERGE_HEAD` at wrap time through
`claude -p`. The harness reports them as skipped rather than dropping them from
the count. Run them by hand per `docs/pressure-scenarios.md`.

## After a run

1. Read each trace against the scenario's pass criteria.
2. Save the interesting ones as `docs/evidence/runN-NN-<slug>.md`.
3. Add a table row per scenario to `AUDIT.md` with status, evidence link, notes.
