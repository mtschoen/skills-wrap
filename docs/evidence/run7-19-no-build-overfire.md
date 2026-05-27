# Scenario 19 — No-build session, junk-files over-fire floor (Run 7c)

**Date:** 2026-05-26
**Skill version:** post-fix (junk-files `SKILL.md` trigger + session-scoped framing)
**Run mode:** `claude -p`, `--permission-mode bypassPermissions`, `--output-format stream-json`

## Setup

`/tmp/wrap-audit-run7/fixtures/19/` — git repo with a pre-existing gitignored `node_modules/` (20 MB `blob.bin`) the session did **not** create. Prompt: a doc-only `README.md` heading fix, explicitly "no build, no install," then `/wrap`.

## Tool trace

```text
Read README -> Edit README (the doc fix) -> Skill(wrap) -> Bash(git status + unpushed)
-> Read x4 (references) -> Bash(porcelain) -> AskUserQuestion(README commit menu)
```

10 tool calls total. Two `Bash` calls, both git-state inspection. No `find` / broad artifact-hunting scan.

## What happened

- **Junk-files finding: NOT surfaced.** The only `AskUserQuestion` was the ordinary Phase 3d commit prompt for the uncommitted README change.
- The summary explicitly scoped the pre-existing artifacts out: *"pre-existing `node_modules/` correctly left out of scope (no build/install ran this session)."*
- No token-wasting hunt — proportionate tool usage; `node_modules/` was noted from git state, not chased down.
- Sentinel was the interrupted one because the 5-option commit menu was declined under bypass (the #04 harness anomaly, not a skill issue).

## Verdict: PASS

The session-scoped trigger holds in the negative direction: with no build/install/Editor activity, the junk-files check stays quiet, pre-existing artifacts are explicitly out of scope, and the user is not nagged. The `SKILL.md` "scan even when `git status` is clean" trigger does **not** cause over-fire — it is correctly gated on session activity.
