#!/usr/bin/env bash
# find-unwrapped.sh — List recent Claude Code sessions that did NOT end with /wrap.
#
# Heuristic: scan the tail of each session JSONL for an assistant tool_use that
# invoked the wrap skill. Sessions where wrap appears in the tail are considered
# wrapped; anything else is potentially WIP.
#
# Default filters (suppress noise so the list reflects real WIP):
#   --since      2026-04-11   (first wrap-skill commit; older sessions can't have wrapped)
#   --min-bytes  50000        (skip short Q&A sessions)
#   wrap-test*   excluded     (scratch test projects, not real work)
#
# Usage:
#   find-unwrapped.sh                       # filtered unwrapped sessions, pretty output
#   find-unwrapped.sh --limit 100           # scan more sessions
#   find-unwrapped.sh --since 2026-04-20    # narrower recency window
#   find-unwrapped.sh --min-bytes 0         # include short sessions
#   find-unwrapped.sh --all                 # bypass all filters; show wrapped too (✓)
#   find-unwrapped.sh --raw                 # tab-separated, no filters applied
#
# Resume any listed session with:
#   claude --resume <session-id>

set -euo pipefail

projects_dir="${CLAUDE_PROJECTS_DIR:-$HOME/.claude/projects}"
limit=50
tail_lines=300
since='2026-04-11'
min_bytes=50000
exclude_pattern='wrap-test'
show_all=0
raw=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --limit)     limit="$2"; shift 2 ;;
        --tail)      tail_lines="$2"; shift 2 ;;
        --since)     since="$2"; shift 2 ;;
        --min-bytes) min_bytes="$2"; shift 2 ;;
        --exclude)   exclude_pattern="$2"; shift 2 ;;
        --all)       show_all=1; shift ;;
        --raw)       raw=1; shift ;;
        -h|--help)
            sed -n '2,22p' "$0" | sed 's/^# \{0,1\}//'
            exit 0
            ;;
        *) echo "unknown argument: $1" >&2; exit 2 ;;
    esac
done

if [[ ! -d "$projects_dir" ]]; then
    echo "no projects dir at $projects_dir" >&2
    exit 1
fi

# Format mtime portably (GNU stat on Git Bash / Linux; BSD stat on macOS)
format_mtime() {
    local f="$1"
    if stat -c '%y' "$f" >/dev/null 2>&1; then
        stat -c '%y' "$f" | cut -d. -f1
    else
        stat -f '%Sm' -t '%Y-%m-%d %H:%M:%S' "$f"
    fi
}

# Epoch seconds for the --since cutoff, for cross-platform date math
since_epoch=$(date -d "$since" +%s 2>/dev/null \
    || date -j -f '%Y-%m-%d' "$since" +%s 2>/dev/null \
    || { echo "could not parse --since '$since'" >&2; exit 2; })

mtime_epoch() {
    local f="$1"
    stat -c '%Y' "$f" 2>/dev/null || stat -f '%m' "$f"
}

# Scan most recent N session files
mapfile -t files < <(ls -t "$projects_dir"/*/*.jsonl 2>/dev/null | head -n "$limit")

if [[ ${#files[@]} -eq 0 ]]; then
    echo "no session files found under $projects_dir" >&2
    exit 0
fi

if [[ $raw -eq 0 ]]; then
    if [[ $show_all -eq 1 ]]; then
        printf 'All recent sessions (top %d, ✓ = wrapped, no filters):\n\n' "$limit"
    else
        printf 'Unwrapped sessions  (since %s, ≥%s bytes, top %d scanned):\n\n' \
            "$since" "$min_bytes" "$limit"
    fi
fi

shown=0
for f in "${files[@]}"; do
    project=$(basename "$(dirname "$f")")
    session=$(basename "$f" .jsonl)
    size=$(wc -c <"$f" | tr -d ' ')
    file_epoch=$(mtime_epoch "$f")

    # Filters (skip when --all)
    if [[ $show_all -eq 0 ]]; then
        [[ -n "$exclude_pattern" && "$project" == *"$exclude_pattern"* ]] && continue
        [[ $file_epoch -lt $since_epoch ]] && continue
        [[ $size -lt $min_bytes ]] && continue
    fi

    if tail -n "$tail_lines" "$f" | grep -q '"skill":"wrap"'; then
        wrapped=1
    else
        wrapped=0
    fi

    # Hide wrapped sessions unless --all
    if [[ $wrapped -eq 1 && $show_all -eq 0 ]]; then
        continue
    fi

    mtime=$(format_mtime "$f")

    if [[ $raw -eq 1 ]]; then
        printf '%s\t%s\t%s\t%d\t%s\n' "$mtime" "$wrapped" "$project" "$size" "$session"
    else
        marker='  '
        [[ $wrapped -eq 1 ]] && marker='✓ '
        if [[ $size -ge 1048576 ]]; then
            human=$(awk "BEGIN { printf \"%.1f MB\", $size / 1048576 }")
        elif [[ $size -ge 1024 ]]; then
            human=$(awk "BEGIN { printf \"%.0f KB\", $size / 1024 }")
        else
            human="${size} B"
        fi
        printf '  %s%s  %-40s  %s  (%s)\n' "$marker" "$mtime" "$project" "$session" "$human"
    fi
    shown=$((shown + 1))
done

if [[ $raw -eq 0 ]]; then
    if [[ $shown -eq 0 ]]; then
        printf '  (none)\n'
    fi
    printf '\nResume with: claude --resume <session-id>\n'
fi
