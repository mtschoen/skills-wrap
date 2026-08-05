# Scenario 10 - project-tracker present vs absent (Run 8)

**Date:** 2026-08-05
**Skill version:** source HEAD `7d34830` (prose-ask)
**Run mode:** `tests/run-audit.sh 10`, model sonnet, multi-turn via `--resume`
**Fixture:** identical to scenario 2 (bare upstream, 2 unpushed commits, 3 dirty files)
**Prompt:** `/wrap`
**Cost:** $0.38 (present arm) + $0.39 (absent arm), 2 turns each

## Result: Pass - closes open item #3

This is the comparison the scenario was written for, and it had never been run
end to end. Both arms were run against the same fixture recipe:

| Arm | Invocation | `mcp_servers` at init |
|---|---|---|
| Present | `tests/run-audit.sh 10` | `project-tracker: connected` (+ 5 others); project-tracker tools present in the tool list |
| Absent | `WRAP_AUDIT_CLAUDE_ARGS=--strict-mcp-config tests/run-audit.sh 10` | `[]` |

Verified from the `system`/`init` event of each trace, not assumed.

## Equivalence

The two arms produce the same user-visible wrap:

| Aspect | Present | Absent |
|---|---|---|
| Findings | 3 dirty files + 2 unpushed commits | 3 dirty files + 2 unpushed commits |
| Phases 0/2a/2b/3a/3b/3c | all correctly silent | all correctly silent |
| Phase 3d menu | all five options, lettered | all five options, lettered |
| Execution on `c` | commit `74a7ae4`, not pushed | commit `57798b9`, not pushed |
| Phase 4 | leftovers named, 3 commits ahead | leftovers named, 3 commits ahead |
| Sentinel | completed, exactly one | completed, exactly one |

**The strongest form of the result:** in the *present* arm the session used raw
`git` via Bash anyway and never called a project-tracker tool, even though the
tools were connected and available. The tool-agnostic prose (principle 2) does
not merely tolerate both paths - for this scenario the model's behaviour is
identical because it reaches for plain git either way. Only 3 Bash calls in each
arm; no MCP tool calls in either.

## Assertions

| Check | Present | Absent |
|---|---|---|
| No question widget | Pass | Pass |
| Exactly one closing sentinel, completed variant | Pass | Pass |
| Findings match across arms | Pass | Pass |
| No write into a pre-existing project memory dir | Pass | Pass |

## Reproducing

The absent arm needs no settings file. `--strict-mcp-config` with no
`--mcp-config` yields zero MCP servers, which is cleaner than the
`--settings '{"mcpServers":{}}'` recipe open item #3 originally proposed. The
harness passes it through `WRAP_AUDIT_CLAUDE_ARGS`.
