<#
.SYNOPSIS
    List recent agent sessions that did NOT end with /wrap.
    Scans the agent's session transcripts (Claude Code: ~/.claude/projects).

.DESCRIPTION
    Heuristic: scan each session JSONL for any of:
      - "skill":"wrap" / "attributionSkill":"wrap"  (Skill-tool invocation)
      - <command-name>/wrap</command-name>          (slash-command invocation)
      - "Launching skill: wrap"                     (skill engagement marker)
    Sessions with any marker are considered wrapped; anything else is potentially WIP.

    Modes:
      (default)  show sessions missing /wrap
      -NoExit    show sessions with no clean-exit signal (crashed, killed, or
                 abandoned). Heuristic: a session matching the /wrap marker
                 above also counts as a clean exit, even with no literal
                 /exit - so a session that ran /wrap and kept going afterward
                 will NOT show up here, even if it is still active.

    Default filters (suppress noise so the list reflects real WIP):
      -Since      2026-04-30   (earliest observed real /wrap invocation; the skill
                                 existed since 2026-04-11 but routine adoption lagged
                                 by ~3 weeks. An earlier default flagged the
                                 adoption-gap window as "unwrapped" - false alarms.)
      -MinBytes   50000        (skip short Q&A sessions)
      wrap-test*  excluded     (scratch test projects, not real work)

.EXAMPLE
    .\find-unwrapped.ps1
    Filtered unwrapped sessions, pretty output.

.EXAMPLE
    .\find-unwrapped.ps1 -NoExit
    Sessions that didn't exit cleanly.

.EXAMPLE
    .\find-unwrapped.ps1 -Limit 100 -Since 2026-04-20
    Scan more sessions with a narrower recency window.

.EXAMPLE
    .\find-unwrapped.ps1 -NoSince
    Disable the date cutoff entirely.

.EXAMPLE
    .\find-unwrapped.ps1 -All
    Bypass all filters; show matched sessions too (marked with a check).

.EXAMPLE
    .\find-unwrapped.ps1 -Raw
    Tab-separated output, no filters applied (combine with -All for the full raw dump).

.NOTES
    Resume any listed session with: claude --resume <session-id>
#>
[CmdletBinding()]
param(
    [int]$Limit = 50,
    [string]$Since = '2026-04-30',
    [switch]$NoSince,
    [int]$MinBytes = 50000,
    [string]$Exclude = 'wrap-test',
    [switch]$NoExit,
    [switch]$All,
    [switch]$Raw
)

$ErrorActionPreference = 'Stop'

# Combined regex matching any signal that the wrap skill was engaged in a session.
# Slash-command (<command-name>/wrap</command-name>) is the most common path and
# is missed by the older "skill":"wrap"-only heuristic.
$wrapMarkerPattern = '"(skill|attributionSkill)":"wrap"|<command-name>/wrap</command-name>|Launching skill: wrap'

$projectsDir = if ($env:AGENT_SESSIONS_DIR) { $env:AGENT_SESSIONS_DIR } else { Join-Path $HOME '.claude\projects' }
if (-not (Test-Path $projectsDir)) {
    Write-Error "no projects dir at $projectsDir"
    exit 1
}

# Empty/-NoSince means no date cutoff at all.
$sinceDate = $null
if (-not $NoSince) {
    try {
        $sinceDate = [datetime]::ParseExact($Since, 'yyyy-MM-dd', $null)
    } catch {
        Write-Error "could not parse -Since '$Since' (expected yyyy-MM-dd)"
        exit 2
    }
}

$mode = if ($NoExit) { 'no-exit' } else { 'unwrapped' }

# Collect session IDs of actively running claude processes (matches --resume <id>
# on the command line), so -NoExit doesn't flag a session that's simply still open.
function Get-ActiveSessionIds {
    $ids = @()
    try {
        $procs = Get-CimInstance Win32_Process -Filter "Name LIKE '%claude%'" -ErrorAction Stop
    } catch {
        return $ids
    }
    foreach ($p in $procs) {
        $cmd = $p.CommandLine
        if (-not $cmd) { continue }
        $parts = $cmd -split '\s+'
        for ($i = 0; $i -lt $parts.Length - 1; $i++) {
            if ($parts[$i] -eq '--resume') {
                $ids += $parts[$i + 1]
            }
        }
    }
    return $ids
}

$activeSessionIds = if ($mode -eq 'no-exit') { Get-ActiveSessionIds } else { @() }
# Current (non-resumed) session: a JSONL modified within the last 120s is almost
# certainly still active, not crashed.
$activeGraceSeconds = 120
$now = Get-Date

# One level deep only: <projectsDir>/<project>/<session>.jsonl
# (Mirrors the bash glob */*.jsonl; avoids picking up nested subagent transcripts.)
$files = Get-ChildItem -Path (Join-Path $projectsDir '*\*.jsonl') -File |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First $Limit

if (-not $files) {
    Write-Error "no session files found under $projectsDir"
    exit 0
}

if (-not $Raw) {
    if ($mode -eq 'no-exit') {
        $label = 'No clean /exit'
        $markerLabel = 'exited'
    } else {
        $label = 'Unwrapped'
        $markerLabel = 'wrapped'
    }
    if ($All) {
        Write-Host ("All recent sessions (top {0}, check = {1}, no filters):`n" -f $Limit, $markerLabel)
    } elseif (-not $NoSince) {
        Write-Host ("{0} sessions  (since {1}, >={2} bytes, top {3} scanned):`n" -f $label, $Since, $MinBytes, $Limit)
    } else {
        Write-Host ("{0} sessions  (no date cutoff, >={1} bytes, top {2} scanned):`n" -f $label, $MinBytes, $Limit)
    }
}

function Format-Size([long]$bytes) {
    if ($bytes -ge 1MB) { return ('{0:N1} MB' -f ($bytes / 1MB)) }
    if ($bytes -ge 1KB) { return ('{0:N0} KB' -f ($bytes / 1KB)) }
    return "$bytes B"
}

$shown = 0
foreach ($file in $files) {
    $project = $file.Directory.Name
    $session = $file.BaseName
    $size    = $file.Length
    $mtime   = $file.LastWriteTime

    if (-not $All) {
        if ($Exclude -and $project -like "*$Exclude*") { continue }
        if ($sinceDate -and $mtime -lt $sinceDate) { continue }
        if ($size -lt $MinBytes) { continue }
    }

    # Scan the whole file for the wrap marker - not just a tail slice. A session
    # can invoke /wrap early and keep talking afterward (or vice versa), and a
    # tail-only scan silently misses those.
    $wrapped = [bool](Select-String -Path $file.FullName -Pattern $wrapMarkerPattern -CaseSensitive -Quiet -ErrorAction SilentlyContinue)

    if ($mode -eq 'no-exit') {
        if ($activeSessionIds -contains $session) {
            $matched = $true
        } elseif (($now - $mtime).TotalSeconds -lt $activeGraceSeconds) {
            $matched = $true
        } elseif ($wrapped) {
            # Wrapped sessions count as a clean exit.
            $matched = $true
        } else {
            $tail = Get-Content -Path $file.FullName -Tail 5 -ErrorAction SilentlyContinue
            $matched = [bool]($tail | Select-String -SimpleMatch -Pattern '"content":"<command-name>/exit</command-name>' -CaseSensitive -Quiet)
        }
    } else {
        $matched = $wrapped
    }

    # Hide matched sessions unless -All.
    if ($matched -and -not $All) { continue }

    if ($Raw) {
        $matchedFlag = if ($matched) { 1 } else { 0 }
        $fields = @($mtime.ToString('yyyy-MM-dd HH:mm:ss'), $matchedFlag, $project, $size, $session)
        $fields -join "`t"
    } else {
        $marker = if ($matched) { '* ' } else { '  ' }
        $line = '  {0}{1}  {2,-40}  {3}  ({4})' -f `
            $marker, `
            $mtime.ToString('yyyy-MM-dd HH:mm:ss'), `
            $project, `
            $session, `
            (Format-Size $size)
        Write-Host $line
    }
    $shown++
}

if (-not $Raw) {
    if ($shown -eq 0) { Write-Host '  (none)' }
    Write-Host "`nResume with: claude --resume <session-id>"
}
