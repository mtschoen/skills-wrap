# Scenario 13 — Background shell at wrap time (Run 7)

**Date:** 2026-05-26
**Skill version:** Run 7
**Run mode:** `claude -p`, `--permission-mode bypassPermissions`, `--output-format stream-json`
**Fixture:** `/tmp/wrap-audit-run7/fixtures/13` — git repo, single `README.md`, clean tree, no upstream.
**Prompt:** "Start a long-running background shell with exactly this command: `python3 -c 'import time; time.sleep(600)'`. Confirm via its output that it is alive, then run /wrap."

## Tool trace

```text
0. Bash(run_in_background=true)  cmd="python3 -c 'import time; time.sleep(600)'"
     → TOOL_RESULT: "Command running in background with ID: bucn0xubg. Output is being written to: ..."
1. Read  file_path='...tasks/bucn0xubg.output'
     → empty (sleep writes nothing — agent noted this correctly)
2. Bash  cmd='ps -eo pid,etime,cmd | grep "[t]ime.sleep(600)"'
     → confirms PID 2117694 alive (~18s elapsed)
3. Skill  skill='wrap'
4. Bash  cmd='git status ... && ps -o pid,etime,cmd -p 2117694 ...'
     → confirms process still alive at wrap time
5. ToolSearch  q='select:TaskStop'
     → loaded TaskStop schema
6. AskUserQuestion
     Q: "Phase 2b background sweep found one live process this session started: background
         shell `bucn0xubg` (`python3 -c 'import time; time.sleep(600)'`, ~50s in, no output
         — silent sleep). Wrap terminates session-spawned background processes before closing.
         Stop it?"
     opts (2): ['Stop it (Recommended)', 'Leave it running']
   → TOOL_RESULT: "Answer questions?"
     [bypassPermissions: 2-option prompt → auto-picked first = "Stop it"]
7. ★ TaskStop  task_id='bucn0xubg'
     → TOOL_RESULT: '{"message":"Successfully stopped task: bucn0xubg (python3 -c \'import time; time.sleep(600)\')",...}'
8. Bash  cmd='ps -o pid,etime,cmd -p 2117694 2>/dev/null || echo "GONE: sleep process terminated"'
     → TOOL_RESULT: "GONE: sleep process terminated"
```

11 turns total.

## Note on AskUserQuestion response

The tool result for the AskUserQuestion was `"Answer questions?"` rather than `"Stop it"`. The agent's text (turn 5) explains: "The interactive prompt couldn't be answered in this (headless `claude -p`) environment" and notes it applied the recommended default rather than blocking. The subsequent `TaskStop` call confirms correct behavior regardless — the 2-option prompt in `bypassPermissions` mode auto-picks the first option ("Stop it"), and `TaskStop` fired on the next turn.

## Final summary (verbatim)

> **Phase 2b — Background process sweep:** 1 process found and terminated.
>
> - `bucn0xubg` — `python3 -c 'import time; time.sleep(600)'`, ran ~50s, **silent** (empty output, nothing to harvest) → stopped via `TaskStop`, confirmed gone (PID 2117694 no longer exists).
> - Note: interactive approval (`AskUserQuestion`) couldn't be collected in this headless run — it errored rather than returning a choice. Rather than block, I applied the recommended default to the single unambiguously-safe item (terminating self-started session scratch). No other item required approval.
>
> **That's a /wrap. Go ahead and close the session.**

## Analysis

**Status:** PASS.

All pass criteria verified via tool trace (not just narrative):

| Criterion | Result |
|---|---|
| `Bash(run_in_background=true)` fired | ✓ event 0 |
| Output confirmed alive (`TaskOutput`-equivalent via Read + ps check) | ✓ events 1–2 |
| `AskUserQuestion` surfaced with 2-option Stop/Leave | ✓ event 6 |
| Auto-picked "Stop it" (2-option bypassPermissions) | ✓ per harness rule |
| `TaskStop` fired (verified in tool trace) | ✓ event 7, task_id=`bucn0xubg` |
| `TaskStop` success confirmed | ✓ `Successfully stopped task: bucn0xubg` |
| Process confirmed gone post-stop | ✓ `GONE: sleep process terminated` (event 8) |
| Summary names the killed shell | ✓ `bucn0xubg` + command verbatim in Phase 2b bullet |
| COMPLETION sentinel | ✓ "That's a /wrap. Go ahead and close the session." |

The agent used `Read` on the output file (not a `TaskOutput` tool call) + a `ps` Bash as the "confirm alive" step. This is functionally equivalent — it read the task output path directly and cross-checked with `ps`. The per-item context in the AskUserQuestion includes command, elapsed time (~50s), and output state (silent sleep) — sufficient for a user to decide y/n without inspecting the shell.

**Bypass-mode behavior:** AskUserQuestion returned `"Answer questions?"` (2-option prompt → bypass picks first = "Stop it"). Agent applied the recommended default and proceeded to `TaskStop`. This matches the documented harness behavior from Run 6.
