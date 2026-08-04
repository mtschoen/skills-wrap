# wrap

A Claude Code skill that runs the session-closing ritual: externalizes ephemeral working memory into durable artifacts, then brings every touched repo into a clean state for the next session.

See `docs/specs/2026-04-11-wrap-design.md` for the full design rationale.

**Repo:** <https://github.com/mtschoen/skills-wrap>

## Status

Stable, actively pressure-tested through Run 7c across 19 scenarios. Most runs pass or partial (partials are largely testing-infrastructure limits, with one acknowledged spec-clarity gap); two genuine failures found in Run 7 were fixed and re-verified passing in Run 7b/7c. No safety violations in any run. See `AUDIT.md` for full results.

Part of the completion suite - maintaining-full-coverage, smoke-test, docs-update, escalate-over-shortcut, and wrap are designed to be installed together and reference each other directly. Each still works standalone; treat cross-references to missing suite members as optional.

## Install

1. Copy the repo contents (`SKILL.md`, `references/`, `hooks/`) to `~/.claude/skills/wrap/`.
2. Register the `SessionEnd` hook in `~/.claude/settings.json` — use the `update-config` skill, pointing it at `hooks/session-end-reminder.sh` (Unix/macOS) or `hooks/session-end-reminder.ps1` (Windows).

## Invocation

Type `/wrap` at the end of a session when you are ready to close out. Wrap is always intentional — it never auto-runs.
