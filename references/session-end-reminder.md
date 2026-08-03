# SessionEnd Reminder Hook

A decoupled nudge mechanism, separate from the wrap skill itself. Registered as a `SessionEnd` hook (see "Registering the hook" below for the manual-install vs. plugin-install shapes). Runs at session exit, prints at most one line, exits 0.

## What it does

Checks the session's final `cwd` for wrap-worthy signals:

1. Working tree dirty? (`git status --porcelain` non-empty)
2. Unpushed commits? (`git log @{u}..HEAD` non-empty, if upstream exists)
3. Any files present in `.claude/scripts/`?

If any fire, prints a single-line reminder. Otherwise prints nothing.

## Rate limiter

A marker file at `~/.claude/wrap-nudge-last-fired`. If the hook fired within the last 5 minutes, the hook skips entirely (prevents noise during quick-exit-restart cycles). On each non-skipped run, the hook touches the marker.

**Wrap itself does not read or write this file.** Full decoupling — the skill and the hook know nothing about each other.

## Output format

Example:

```text
⚠ wrap-worthy state: 3 dirty files, 2 unpushed commits in ~/myrepo. Consider /wrap next session.
```

If no signals fire, the hook prints nothing. Silent is valid.

## Scope caveat

The hook sees only the session's final `cwd`. If the session touched multiple repos but exited from a third, the hook only reports that third. This is acceptable because the hook is a nudge, not a checklist — the user knows what they touched.

## Registering the hook

The snippet shape depends on how the skill got onto disk - a manual copy vs. a plugin install register differently. Pick the one that matches this install.

**Manual install** (the skill copied directly into `~/.claude/skills/wrap/`): register via a `SessionEnd` entry in `~/.claude/settings.json`, with a literal path to the hook script:

```json
{
  "hooks": {
    "SessionEnd": [
      {
        "command": "~/.claude/skills/wrap/hooks/session-end-reminder.sh"
      }
    ]
  }
}
```

On Windows, substitute `session-end-reminder.ps1`:

```json
{
  "hooks": {
    "SessionEnd": [
      {
        "command": "pwsh -NoProfile -File C:/Users/<you>/.claude/skills/wrap/hooks/session-end-reminder.ps1"
      }
    ]
  }
}
```

Use the `update-config` skill to perform the registration rather than hand-editing `settings.json`.

**Plugin install**: this shape does not apply. A plugin lands under a versioned plugin-cache path (e.g. `~/.claude/plugins/cache/<marketplace>/wrap/<version>/`) that changes on every version bump, and the plugin registers its own hooks via a `hooks.json` manifest shipped alongside it - there is no user `settings.json` edit at all. The manifest resolves the install path at runtime with `${CLAUDE_PLUGIN_ROOT}` instead of a literal path:

```json
{
  "hooks": {
    "SessionEnd": [
      {
        "hooks": [
          { "type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/hooks/session-end-reminder.sh" }
        ]
      }
    ]
  }
}
```

Don't paste the manual-install snippet into a plugin's `hooks.json` (a literal `~/.claude/skills/wrap/...` path breaks the moment the plugin version bumps) or the plugin snippet into a hand-edited `settings.json` (`${CLAUDE_PLUGIN_ROOT}` has no meaning there).

Note the manifest is the **plugin author's** responsibility, not the installing user's: `hooks/hooks.json` lives at the plugin root and Claude Code auto-loads it when the plugin is enabled — a skill directory inside a plugin cannot self-register its hooks. If a plugin bundles this skill without shipping that manifest, the hook simply never fires until the user wires it manually via the manual-install path above.

## What the hook must NOT do

- Invoke wrap. It is a nudge, not a trigger.
- Block or delay exit. Must return within milliseconds and exit 0 always.
- Read wrap's internal state. Wrap is stateless; the hook is rate-limited independently.
- Check multiple repos. Single-repo (final `cwd`) is the intentional scope.
