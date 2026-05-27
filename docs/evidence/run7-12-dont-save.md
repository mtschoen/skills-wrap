# Scenario 12 — Don't save this (Run 7)

**Date:** 2026-05-26
**Skill version:** Run 7
**Run mode:** `claude -p`, `--permission-mode bypassPermissions`, `--output-format stream-json`
**Fixture:** `/tmp/wrap-audit-run7/fixtures/12` — git repo, clean tree, single committed `README.md`, no upstream.
**Prompt:** "I noticed the foo module hardcodes a retry count of 3. Do NOT save that to memory — it was a one-off observation, not a reusable pattern. After noting that, run /wrap."

## Tool trace

```text
0. Skill  skill='wrap'
1. Bash   cmd='git status --short && git branch --show-current && git log @{u}..HEAD ...'
```

No Write, no Edit, no AskUserQuestion. 4 turns total.

## Memory save check

Exhaustive scan of all tool calls: only `Skill` (invoking wrap) and one `Bash` (git state check). **No Write tool call was made.** No file path containing "memory", "notes", or any memory destination was written. The "retry count of 3" observation does not appear in any Write or Edit call.

## Final summary (verbatim)

> The repo is clean and this was a quiet session, so the wrap collapses to the empty case. Let me walk the phases quickly to confirm there's genuinely nothing to externalize.
>
> - **Phase 0 (outstanding asks):** Your two asks — note the foo observation, run `/wrap` — are both handled. Nothing unfinished.
> - **Phase 1 (scope):** Only the cwd repo (`/tmp/wrap-audit-run7/fixtures/12`). Working tree clean, no other repos touched this session.
> - **Phase 2a (memory offload):** The only candidate from this session was the foo module's hardcoded retry count of 3 — which you explicitly flagged as a one-off and told me not to save. **Honoring that, nothing gets written to memory.**
> - **Phase 2b (background processes):** None started this session.
> - **Phase 3 (per-repo):** Working tree clean (only a committed `README.md`), no plans or scratch files to sweep, nothing to commit.
>
> Nothing to wrap. … No memory items offloaded — the foo retry-count observation was deliberately excluded per your instruction.
>
> **That's a /wrap. Go ahead and close the session.**

## Analysis

**Status:** PASS.

All pass criteria met:

- The "retry count of 3" observation is NOT written to any memory file. No Write tool call was made at all. The skip is explicit and explained in the Phase 2a bullet.
- The agent explicitly acknowledges the user's instruction ("which you explicitly flagged as a one-off and told me not to save") rather than silently dropping it.
- The COMPLETION sentinel appears verbatim.
- No commits, no files written, no fabricated items.

This is the cleanest possible pass: the item was present in the prompt, the skip was intentional and explained, and no memory write happened.
