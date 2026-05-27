# Scenario 9 — Non-git directory (Run 7)

**Date:** 2026-05-26
**Skill version:** Run 7
**Run mode:** `claude -p`, `--permission-mode bypassPermissions`, `--output-format stream-json`
**Fixture:** `/tmp/wrap-audit-run7/fixtures/9` — plain directory (no `.git`), single pre-existing `notes.txt`.
**Prompt:** `/wrap`

## Tool trace

```text
0. Bash   cmd='echo "=== cwd ===" && pwd && ... && git rev-parse --show-toplevel 2>&1 ...'
            → git rev-parse returned error (not a repo)
1. Read   file_path='/tmp/wrap-audit-run7/fixtures/9/notes.txt'
            → read to confirm pre-existing, not session-created
```

No Write, no Edit, no AskUserQuestion, no commits. 3 turns total.

## Final summary (verbatim)

> **cwd** `/tmp/wrap-audit-run7/fixtures/9` is **not a git repository** (no repo here or in any parent up to the mount point).
> It contains one pre-existing file, `notes.txt` ("plain file"), created before this session — not session scratch, not a plan, not loose-thread material. Nothing I touched.
> This session has no prior conversation, no edits, no background processes, and no memory to offload.
>
> All phases land on empty:
>
> - **Phase 0:** no outstanding asks.
> - **Phase 1:** no git repos in scope — the cwd isn't version-controlled, and nothing else was touched.
> - **Phase 2a/2b:** nothing to offload; no background shells, subagents, or monitors running.
> - **Phase 3:** no repos, so no per-repo work.
>
> Nothing to wrap. The working directory `/tmp/wrap-audit-run7/fixtures/9` is not a git repository (its lone file `notes.txt` is pre-existing and untouched), there are no memory items to offload, and no background processes are running.
>
> **That's a /wrap. Go ahead and close the session.**

## Analysis

**Status:** PASS.

All pass criteria met:

- Phase 1 detected the directory is not a git repo via `git rev-parse` returning an error.
- Phase 3 git operations were never attempted (no `git status`, no `git log`, no `git commit` in the Bash calls) — gracefully skipped because no repos were in scope.
- Summary explicitly mentions the non-git status: "The working directory … is not a git repository."
- No errors, no garbage output. Clean 3-turn execution.
- The COMPLETION sentinel appears verbatim: "That's a /wrap. Go ahead and close the session."
- The agent additionally read `notes.txt` to confirm it was pre-existing and not session scratch — defensive but correct (not fabrication).
