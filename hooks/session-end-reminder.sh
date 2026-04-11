#!/usr/bin/env bash
# wrap skill — SessionEnd reminder hook.
# Prints a one-line nudge if the current cwd has wrap-worthy state.
# Rate-limited to once per 5 minutes via ~/.claude/wrap-nudge-last-fired.
# Must exit 0 always. Never blocks or invokes wrap.

set -u

MARKER="$HOME/.claude/wrap-nudge-last-fired"
RATE_LIMIT_SECONDS=300

# Rate limit: skip if marker is recent
if [ -f "$MARKER" ]; then
    now=$(date +%s)
    last=$(stat -c %Y "$MARKER" 2>/dev/null || stat -f %m "$MARKER" 2>/dev/null || echo 0)
    if [ $((now - last)) -lt $RATE_LIMIT_SECONDS ]; then
        exit 0
    fi
fi

# Only meaningful if cwd is inside a git repo
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    exit 0
fi

repo_name=$(basename "$(git rev-parse --show-toplevel)")
signals=()

# 1. Dirty working tree?
dirty_count=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
if [ "$dirty_count" -gt 0 ]; then
    signals+=("$dirty_count dirty files")
fi

# 2. Unpushed commits? (only if upstream exists)
if git rev-parse --abbrev-ref '@{u}' >/dev/null 2>&1; then
    unpushed_count=$(git log --oneline '@{u}..HEAD' 2>/dev/null | wc -l | tr -d ' ')
    if [ "$unpushed_count" -gt 0 ]; then
        signals+=("$unpushed_count unpushed commits")
    fi
fi

# 3. Files in .claude/scripts/?
if [ -d ".claude/scripts" ]; then
    script_count=$(find .claude/scripts -maxdepth 1 -type f 2>/dev/null | wc -l | tr -d ' ')
    if [ "$script_count" -gt 0 ]; then
        signals+=("$script_count script(s) in .claude/scripts")
    fi
fi

# Print nudge if any signals, update marker
if [ "${#signals[@]}" -gt 0 ]; then
    IFS=', '
    echo "⚠ wrap-worthy state: ${signals[*]} in $repo_name. Consider /wrap next session."
    mkdir -p "$(dirname "$MARKER")"
    touch "$MARKER"
fi

exit 0
