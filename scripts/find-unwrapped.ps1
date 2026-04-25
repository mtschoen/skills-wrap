<#
.SYNOPSIS
    List recent Claude Code sessions that did NOT end with /wrap.

.DESCRIPTION
    Heuristic: scan the tail of each session JSONL for an assistant tool_use that
    invoked the wrap skill. Sessions where wrap appears in the tail are considered
    wrapped; anything else is potentially WIP.

    Default filters (suppress noise so the list reflects real WIP):
      -Since      2026-04-11   (first wrap-skill commit; older sessions can't have wrapped)
      -MinBytes   50000        (skip short Q&A sessions)
      wrap-test*  excluded     (scratch test projects, not real work)

.EXAMPLE
    .\find-unwrapped.ps1
    Filtered unwrapped sessions, pretty output.

.EXAMPLE
    .\find-unwrapped.ps1 -Limit 100 -Since 2026-04-20
    Scan more sessions with a narrower recency window.

.EXAMPLE
    .\find-unwrapped.ps1 -All
    Bypass all filters; show wrapped sessions too (marked with check).

.NOTES
    Resume any listed session with: claude --resume <session-id>
#>
[CmdletBinding()]
param(
    [int]$Limit = 50,
    [int]$Tail = 300,
    [string]$Since = '2026-04-11',
    [int]$MinBytes = 50000,
    [string]$Exclude = 'wrap-test',
    [switch]$All,
    [switch]$Raw
)

$ErrorActionPreference = 'Stop'

$projectsDir = if ($env:CLAUDE_PROJECTS_DIR) { $env:CLAUDE_PROJECTS_DIR } else { Join-Path $HOME '.claude\projects' }
if (-not (Test-Path $projectsDir)) {
    Write-Error "no projects dir at $projectsDir"
    exit 1
}

try {
    $sinceDate = [datetime]::ParseExact($Since, 'yyyy-MM-dd', $null)
} catch {
    Write-Error "could not parse -Since '$Since' (expected yyyy-MM-dd)"
    exit 2
}

# One level deep only: <projectsDir>/<project>/<session>.jsonl
# (Mirrors the bash glob `*/*.jsonl`; avoids picking up nested subagent transcripts.)
$files = Get-ChildItem -Path (Join-Path $projectsDir '*\*.jsonl') -File |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First $Limit

if (-not $files) {
    Write-Error "no session files found under $projectsDir"
    exit 0
}

if (-not $Raw) {
    if ($All) {
        Write-Host ("All recent sessions (top {0}, check = wrapped, no filters):`n" -f $Limit)
    } else {
        Write-Host ("Unwrapped sessions  (since {0}, >={1} bytes, top {2} scanned):`n" -f $Since, $MinBytes, $Limit)
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
        if ($mtime -lt $sinceDate) { continue }
        if ($size -lt $MinBytes)   { continue }
    }

    # Read last $Tail lines and check for wrap invocation marker
    $tailContent = Get-Content -Path $file.FullName -Tail $Tail -ErrorAction SilentlyContinue
    $wrapped = ($tailContent -join "`n") -match '"skill":"wrap"'

    if ($wrapped -and -not $All) { continue }

    if ($Raw) {
        $wrappedFlag = if ($wrapped) { 1 } else { 0 }
        '{0}`t{1}`t{2}`t{3}`t{4}' -f $mtime.ToString('yyyy-MM-dd HH:mm:ss'), $wrappedFlag, $project, $size, $session
    } else {
        $marker = if ($wrapped) { '* ' } else { '  ' }
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
