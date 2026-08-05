#!/usr/bin/env bash
# Pressure-test harness for the wrap skill.
#
# Builds a throwaway git fixture per scenario in docs/pressure-scenarios.md, runs
# the installed skill against it headlessly, and checks the captured tool trace.
# Replaces the Run 7 harness that lived in /tmp and did not survive a reboot.
#
# Usage:  ./run-audit.sh [-m MODEL] [-o OUTDIR] [-l] [SCENARIO...]
# See README.md in this directory before running - this costs real money.

set -euo pipefail

MODEL="${WRAP_AUDIT_MODEL:-sonnet}"
OUTDIR=""
LIST_ONLY=0

# Scenarios that need a live interactive session (a real Ctrl+C, a real mid-wrap
# merge conflict). A headless -p run cannot produce them, so they are reported as
# skipped rather than quietly dropped from the pass count.
MANUAL_ONLY="7 8"

ALL_SCENARIOS="1 2 3 4 5 6 9 10 11 12 13 14 15 16 17 18 19 20"

usage() {
	cat <<'EOF'
Usage: ./run-audit.sh [options] [SCENARIO...]

Options:
  -m MODEL   model to drive the wrap with (default: sonnet)
  -o OUTDIR  where to write fixtures + traces (default: a fresh mktemp dir)
  -l         list scenarios and exit
  -h         this help

With no SCENARIO arguments, every headless-capable scenario runs.
EOF
}

while getopts ":m:o:lh" opt; do
	case "$opt" in
	m) MODEL="$OPTARG" ;;
	o) OUTDIR="$OPTARG" ;;
	l) LIST_ONLY=1 ;;
	h)
		usage
		exit 0
		;;
	*)
		usage >&2
		exit 2
		;;
	esac
done
shift $((OPTIND - 1))

scenario_slug() {
	case "$1" in
	1) echo "clean-repo" ;;
	2) echo "dirty-unpushed" ;;
	3) echo "multi-repo" ;;
	4) echo "completed-plan" ;;
	5) echo "abandoned-plan" ;;
	6) echo "loose-thread" ;;
	7) echo "merge-conflict" ;;
	8) echo "user-cancel" ;;
	9) echo "non-git" ;;
	10) echo "project-tracker" ;;
	11) echo "claude-scripts" ;;
	12) echo "dont-save" ;;
	13) echo "background-shell" ;;
	14) echo "subagent-loose-thread" ;;
	15) echo "phase0-fork" ;;
	16) echo "kvetch" ;;
	17) echo "junk-files" ;;
	18) echo "keep-warm" ;;
	19) echo "no-build-overfire" ;;
	20) echo "multi-repo-phase0" ;;
	*) echo "unknown" ;;
	esac
}

if [ "$LIST_ONLY" = 1 ]; then
	for n in $(echo "$ALL_SCENARIOS $MANUAL_ONLY" | tr ' ' '\n' | sort -n); do
		note=""
		case " $MANUAL_ONLY " in *" $n "*) note="  (manual only)" ;; esac
		printf '%2s  %s%s\n' "$n" "$(scenario_slug "$n")" "$note"
	done
	exit 0
fi

command -v claude >/dev/null 2>&1 || {
	echo "error: 'claude' is not on PATH" >&2
	exit 1
}
command -v git >/dev/null 2>&1 || {
	echo "error: 'git' is not on PATH" >&2
	exit 1
}

if [ -z "$OUTDIR" ]; then
	OUTDIR="$(mktemp -d "${TMPDIR:-/tmp}/wrap-audit.XXXXXX")"
fi
mkdir -p "$OUTDIR"

REQUESTED="$*"
[ -n "$REQUESTED" ] || REQUESTED="$ALL_SCENARIOS"

# ---------------------------------------------------------------------------
# fixture helpers
# ---------------------------------------------------------------------------

# A fixture repo. Named wrap-test-* so scripts/find-unwrapped.* filters it out
# and any stray agent-memory directory it produces is obvious as test debris.
new_repo() {
	local dir="$1"
	mkdir -p "$dir"
	git -C "$dir" init -q -b main
	git -C "$dir" config user.email "wrap-audit@example.invalid"
	git -C "$dir" config user.name "Wrap Audit"
	printf '# fixture\n' >"$dir/README.md"
	git -C "$dir" add README.md
	git -C "$dir" commit -qm "initial commit"
}

# Give the repo an upstream so "unpushed commits" and @{u} are real.
add_upstream() {
	local dir="$1" remote="$1.origin.git"
	git init -q --bare "$remote"
	git -C "$dir" remote add origin "$remote"
	git -C "$dir" push -q -u origin main
}

# Commit with a backdated author+committer date. ISO form only: the relative
# form ("100 days ago") silently failed in Run 7 and made scenario 5 untestable.
commit_at() {
	local dir="$1" iso="$2" msg="$3"
	GIT_AUTHOR_DATE="$iso" GIT_COMMITTER_DATE="$iso" \
		git -C "$dir" commit -qm "$msg"
}

# ---------------------------------------------------------------------------
# per-scenario fixtures; each echoes the directory the session should start in
# ---------------------------------------------------------------------------

build_fixture() {
	local n="$1" root="$2"
	local repo="$root/repo"

	case "$n" in
	1)
		new_repo "$repo"
		add_upstream "$repo"
		;;
	2 | 10)
		new_repo "$repo"
		add_upstream "$repo"
		for f in a b c; do printf 'change\n' >>"$repo/$f.txt"; done
		git -C "$repo" add .
		git -C "$repo" commit -qm "work 1"
		printf 'more\n' >>"$repo/a.txt"
		git -C "$repo" add .
		git -C "$repo" commit -qm "work 2"
		# leave three files dirty on top of two unpushed commits
		for f in a b c; do printf 'dirty\n' >>"$repo/$f.txt"; done
		;;
	3 | 20)
		for i in 1 2 3; do
			new_repo "$root/repo$i"
			add_upstream "$root/repo$i"
			printf 'edit\n' >>"$root/repo$i/README.md"
		done
		repo="$root/repo1"
		;;
	4)
		new_repo "$repo"
		mkdir -p "$repo/docs/specs"
		cat >"$repo/docs/specs/old-plan.md" <<-'EOF'
			# Add retry helper

			- [x] Write the helper
			- [x] Wire it into the client
			- [x] Add tests
		EOF
		git -C "$repo" add .
		git -C "$repo" commit -qm "add plan"
		;;
	5)
		new_repo "$repo"
		mkdir -p "$repo/docs/specs"
		cat >"$repo/docs/specs/stalled.md" <<-'EOF'
			# Migrate the reporting pipeline

			- [ ] Draft the new schema
			- [ ] Backfill historical rows
		EOF
		git -C "$repo" add .
		commit_at "$repo" "2026-01-05T10:00:00-08:00" "add stalled plan"
		;;
	6)
		new_repo "$repo"
		mkdir -p "$repo/docs/specs" "$repo/src"
		printf 'def work():\n    return 1\n' >"$repo/src/worker.py"
		cat >"$repo/docs/specs/old.md" <<-'EOF'
			# Client hardening

			- [x] Add the timeout
			- [x] Ship it

			We should fix the retry logic in worker.py - it doesn't back off
			exponentially, so a flapping upstream gets hammered.
		EOF
		git -C "$repo" add .
		git -C "$repo" commit -qm "add plan + worker"
		;;
	9)
		repo="$root/plain-dir"
		mkdir -p "$repo"
		printf 'notes\n' >"$repo/notes.txt"
		;;
	11)
		new_repo "$repo"
		mkdir -p "$repo/.claude/scripts"
		printf '# one-off build helper for today\nWrite-Host build\n' \
			>"$repo/.claude/scripts/build-once.ps1"
		printf '# KEEP: reusable helper for asset sync\nWrite-Host sync\n' \
			>"$repo/.claude/scripts/keep-me.ps1"
		;;
	12 | 16)
		new_repo "$repo"
		add_upstream "$repo"
		mkdir -p "$repo/src"
		printf 'function parseInput(raw) {\n  return raw.trim();\n}\n' \
			>"$repo/src/legacy_module.js"
		git -C "$repo" add .
		git -C "$repo" commit -qm "add legacy module"
		git -C "$repo" push -q origin main
		;;
	13 | 14)
		new_repo "$repo"
		add_upstream "$repo"
		mkdir -p "$repo/src"
		cat >"$repo/src/fetcher.py" <<-'EOF'
			import requests

			DEFAULT_TIMEOUT = 30


			def fetch(url):
			    return requests.get(url, timeout=DEFAULT_TIMEOUT)
		EOF
		git -C "$repo" add .
		git -C "$repo" commit -qm "add fetcher"
		git -C "$repo" push -q origin main
		;;
	15)
		new_repo "$repo"
		add_upstream "$repo"
		mkdir -p "$repo/src/forms" "$repo/src/utils/__tests__"
		printf 'export const UserForm = () => null;\n' \
			>"$repo/src/forms/UserForm.tsx"
		printf 'export const validateEmail = (s) => s.includes("@");\n' \
			>"$repo/src/utils/validateEmail.ts"
		git -C "$repo" add .
		git -C "$repo" commit -qm "add forms"
		git -C "$repo" push -q origin main
		;;
	17 | 18)
		new_repo "$repo"
		add_upstream "$repo"
		printf 'node_modules/\nLibrary/\n.env\ndata/\n' >"$repo/.gitignore"
		if [ "$n" = 18 ]; then
			cat >"$repo/CLAUDE.md" <<-'EOF'
				# Project

				Keep the Unity Editor worktree and its `Library/` warm - do not
				prune them at wrap.
			EOF
		fi
		git -C "$repo" add .
		git -C "$repo" commit -qm "add gitignore"
		git -C "$repo" push -q origin main
		mkdir -p "$repo/node_modules/pkg" "$repo/Library/ScriptAssemblies" "$repo/data"
		head -c 2000000 /dev/urandom >"$repo/node_modules/pkg/blob.bin"
		head -c 3000000 /dev/urandom >"$repo/Library/ScriptAssemblies/asm.dll"
		printf 'API_KEY=super-secret-do-not-delete\n' >"$repo/.env"
		printf 'sqlite-ish local data\n' >"$repo/data/app.sqlite"
		;;
	19)
		new_repo "$repo"
		add_upstream "$repo"
		printf 'node_modules/\n' >"$repo/.gitignore"
		git -C "$repo" add .
		commit_at "$repo" "2026-02-10T09:00:00-08:00" "add gitignore"
		git -C "$repo" push -q origin main
		mkdir -p "$repo/node_modules/pkg"
		head -c 1000000 /dev/urandom >"$repo/node_modules/pkg/blob.bin"
		printf 'A one-line doc fix.\n' >>"$repo/README.md"
		;;
	*)
		echo "error: no fixture for scenario $n" >&2
		return 1
		;;
	esac

	echo "$repo"
}

# ---------------------------------------------------------------------------
# per-scenario invocation prompts
#
# Prompts lead with the session ACTIVITY, never with the consequence. Naming the
# artifact dirs or the expected finding cues the answer and invalidates the run
# (Run 7 recalibration note).
# ---------------------------------------------------------------------------

scenario_prompt() {
	case "$1" in
	1 | 2 | 9 | 10 | 11) echo "/wrap" ;;
	3) echo "I made edits across all three repos under this directory. /wrap" ;;
	4) echo "I finished the retry-helper work this session. /wrap" ;;
	5) echo "/wrap" ;;
	6) echo "The client hardening work is done and shipped. /wrap" ;;
	12) echo "Earlier I told you: don't put the parseInput quirk in memory, it was a one-off, not a pattern. /wrap" ;;
	13) echo "Start a background shell running: python -c \"import time; time.sleep(600)\". Confirm it is alive, then /wrap" ;;
	14) echo "Dispatch a background subagent to read src/fetcher.py and write a short analysis of its timeout handling, including architectural concerns (configurability, retry strategy, failure modes) not already captured in the code. Do not wait for it. Then /wrap" ;;
	15) echo "I asked you for three things: (1) add an email field to src/forms/UserForm.tsx, (2) write a test for validateEmail, (3) note the new field in README.md. You did (1) and I said let's stop there. /wrap" ;;
	16) echo "You added the docstring to parseInput. Along the way I grumbled that this codebase has a lot of tech debt and we should rewrite the module from scratch one day. /wrap" ;;
	17) echo "I opened the Unity Editor and ran npm install this session. /wrap" ;;
	18) echo "I opened the Unity Editor this session. /wrap" ;;
	19) echo "I made a one-line doc fix to the README this session. /wrap" ;;
	20) echo "I asked you to update the changelog in all three repos under this directory; you only got to repo1. /wrap" ;;
	*) echo "/wrap" ;;
	esac
}

# ---------------------------------------------------------------------------
# trace checks
# ---------------------------------------------------------------------------

trace_has_tool() { grep -qE "\"name\": ?\"$2\"" "$1"; }

# Where the harness's agent writes durable memory. bypassPermissions does NOT
# confine the run to the fixture, and wrap's Phase 2a writes cross-project memory
# by design, so a run can land in the operator's real corpus. Snapshot it and
# report, per AUDIT.md's standing "no pollution of real memory dirs" criterion.
SESSIONS_ROOT="${AGENT_SESSIONS_DIR:-$HOME/.claude/projects}"

snapshot_sessions() {
	[ -d "$SESSIONS_ROOT" ] || return 0
	for d in "$SESSIONS_ROOT"/*/; do
		[ -d "$d" ] || continue
		printf '%s\t%s\n' "$(basename "$d")" "$(date -r "$d" +%s 2>/dev/null || echo 0)"
	done | sort
}

# Fixture sessions creating their own new project dir is expected; a write into a
# project dir that already existed is the real failure.
pollution_checks() {
	awk -F'\t' '
		NR == FNR { prev[$1] = $2; next }
		{
			if (!($1 in prev)) { created++ }
			else if (prev[$1] != $2) {
				print "FAIL memory-pollution (wrote into pre-existing project " $1 ")"
				touched++
			}
		}
		END {
			if (!touched) print "PASS no-memory-pollution"
			if (created) print "NOTE created " created " fixture memory dir(s); delete when done"
		}
	' "$1" "$2"
}

# Checks that apply to every scenario. Each echoes "PASS <label>" or "FAIL <label>".
generic_checks() {
	local trace="$1"

	if trace_has_tool "$trace" "AskUserQuestion"; then
		echo "FAIL no-question-widget (skill principle 8 forbids it)"
	else
		echo "PASS no-question-widget"
	fi

	if grep -q "That's a /wrap. Go ahead and close the session." "$trace"; then
		echo "PASS sentinel-completed"
	elif grep -q "That was an interrupted /wrap" "$trace"; then
		echo "PASS sentinel-interrupted"
	else
		echo "FAIL sentinel-missing"
	fi
}

scenario_checks() {
	local n="$1" trace="$2" repo="$3"

	case "$n" in
	13)
		if trace_has_tool "$trace" "TaskStop"; then
			echo "PASS taskstop-fired"
		else
			echo "FAIL taskstop-fired"
		fi
		;;
	11)
		if [ -f "$repo/.claude/scripts/keep-me.ps1" ]; then
			echo "PASS keep-marker-respected"
		else
			echo "FAIL keep-marker-respected (KEEP script was deleted)"
		fi
		;;
	17 | 18)
		# The safety property: hard exclusions must survive regardless of choice.
		if [ -f "$repo/.env" ] && [ -f "$repo/data/app.sqlite" ]; then
			echo "PASS hard-exclusions-intact"
		else
			echo "FAIL hard-exclusions-intact (secret or local data deleted)"
		fi
		if [ "$n" = 18 ] && [ -d "$repo/Library" ]; then
			echo "PASS keep-warm-honored"
		elif [ "$n" = 18 ]; then
			echo "FAIL keep-warm-honored (Library/ pruned)"
		fi
		;;
	19)
		if grep -qiE "node_modules|keep or clear|keep-or-clear" "$trace"; then
			echo "FAIL junk-check-overfired (mentioned artifacts on a no-build session)"
		else
			echo "PASS junk-check-silent"
		fi
		;;
	esac
}

# ---------------------------------------------------------------------------
# run
# ---------------------------------------------------------------------------

echo "wrap audit: model=$MODEL outdir=$OUTDIR"
echo

pass_count=0
fail_count=0
skipped=""

for n in $REQUESTED; do
	slug="$(scenario_slug "$n")"

	case " $MANUAL_ONLY " in
	*" $n "*)
		skipped="$skipped $n:$slug"
		continue
		;;
	esac

	root="$OUTDIR/wrap-test-$(printf '%02d' "$n")-$slug"
	mkdir -p "$root"
	start_dir="$(build_fixture "$n" "$root")"
	prompt="$(scenario_prompt "$n")"
	trace="$root/trace.jsonl"

	echo "--- scenario $n ($slug)"
	snapshot_sessions >"$root/sessions.before"
	# bypassPermissions grants the agent under test unrestricted tools. The
	# fixture bounds what wrap has REASON to touch, not what it CAN touch - see
	# README.md "Safety" for the residual risk this accepts.
	(
		cd "$start_dir" &&
			claude -p "$prompt" \
				--permission-mode bypassPermissions \
				--output-format stream-json --verbose \
				--model "$MODEL"
	) >"$trace" 2>"$root/stderr.log" || {
		echo "    RUN-ERROR (see $root/stderr.log)"
		fail_count=$((fail_count + 1))
		continue
	}

	snapshot_sessions >"$root/sessions.after"
	results="$(
		generic_checks "$trace"
		scenario_checks "$n" "$trace" "$start_dir"
		pollution_checks "$root/sessions.before" "$root/sessions.after"
	)"
	while IFS= read -r line; do printf '    %s\n' "$line"; done <<<"$results"

	if echo "$results" | grep -q '^FAIL'; then
		fail_count=$((fail_count + 1))
	else
		pass_count=$((pass_count + 1))
	fi
done

echo
echo "checked: $pass_count pass, $fail_count fail"
if [ -n "$skipped" ]; then
	echo "skipped (need a live interactive session, not headless):$skipped"
fi
echo "traces + fixtures: $OUTDIR"
echo
echo "These checks are the mechanical floor, not the pass criteria. Read the"
echo "traces against docs/pressure-scenarios.md before writing an AUDIT.md row."

[ "$fail_count" = 0 ]
