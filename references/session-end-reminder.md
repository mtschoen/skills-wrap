# SessionEnd Reminder Hook

A decoupled nudge mechanism, separate from the wrap skill itself. Registered as a `SessionEnd` hook in `~/.claude/settings.json`, runs at session exit, prints at most one line, exits 0.

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
```
⚠ wrap-worthy state: 3 dirty files, 2 unpushed commits in ~/llamalab. Consider /wrap next session.
```

If no signals fire, the hook prints nothing. Silent is valid.

## Scope caveat

The hook sees only the session's final `cwd`. If the session touched multiple repos but exited from a third, the hook only reports that third. This is acceptable because the hook is a nudge, not a checklist — the user knows what they touched.

## Settings.json example

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

## What the hook must NOT do

- Invoke wrap. It is a nudge, not a trigger.
- Block or delay exit. Must return within milliseconds and exit 0 always.
- Read wrap's internal state. Wrap is stateless; the hook is rate-limited independently.
- Check multiple repos. Single-repo (final `cwd`) is the intentional scope.
