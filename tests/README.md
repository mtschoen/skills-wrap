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
the day; Run 8 averaged about $0.45 per scenario on sonnet, more for multi-repo
ones. Start with a couple of scenarios.

It tests whatever is installed at your harness's skills directory, not this
checkout. Install first, or you are auditing the previous version.

### How a scenario is driven

The skill asks in prose (SKILL.md principle 8), so a single `claude -p` run
stops at the first question - which for most scenarios is Phase 1, long before
anything interesting. Each scenario is therefore a **multi-turn session**: the
first turn reports a `session_id`, and every answer is a `--resume` turn against
it, until a closing sentinel appears or `WRAP_AUDIT_MAX_TURNS` (default 10) is
reached. Each turn's stream-json is kept as `trace.jsonl.turnN` and concatenated
into `trace.jsonl`.

Answers come from `answer_for`, which reads what was just asked. A lettered menu
is answered **with a letter**, never with prose - a generic "approved, go ahead"
does not map onto `(f)inish first / (w)rap with handoff / (d)rop it`, and the
skill correctly refuses to choose for the user, so the run stalls on a
non-answer instead of testing the branch. Preference order is handoff over drop,
commit over push, leave over destroy; anything unrecognised takes the first
option. Answers stay neutral for the same reason the invocation prompts do: one
that names the expected finding cues it and invalidates the run.

Two knobs:

```bash
WRAP_AUDIT_MAX_TURNS=20 ./run-audit.sh 20        # long multi-repo wraps
WRAP_AUDIT_CLAUDE_ARGS=--strict-mcp-config ./run-audit.sh 10   # no MCP servers
```

`WRAP_AUDIT_CLAUDE_ARGS` appends arguments to every turn. Scenario 10 is a
two-arm comparison - run it once plainly (project-tracker reachable) and once
with `--strict-mcp-config` (no MCP servers at all), then diff the two traces.

## What it does and does not decide

The checks are a **mechanical floor**, not the pass criteria:

- every run: no question widget was used (SKILL.md principle 8), a closing
  sentinel was emitted, and no memory file was written into a pre-existing
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
  memory root. The harness snapshots every memory file under that root around
  each scenario and fails the run on a memory write into a project directory
  that already existed; new fixture-owned directories are reported as debris to
  delete. (It deliberately does not compare directory mtimes - the CLI's own
  housekeeping touches project directories and produced four false positives in
  Run 8.) Point
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
