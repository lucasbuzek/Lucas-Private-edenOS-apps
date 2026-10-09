# JANITOR Windows CLI 0.1.2  (Windows PowerShell 3.0+ / PowerShell 7 - Windows 7 SP1 needs the free WMF 5.1 update; Windows 8+ works as shipped)
# Contract: UNKNOWN != JUNK. inspect -> classify -> review -> confirm -> act -> verify -> record.
# No daemon, telemetry, network or installs. Cloud-provider (OneDrive/Dropbox/...) storage is never traversed, hashed or moved.
param(
    [Parameter(Position = 0)][string]$Command = 'help',
    [Parameter(Position = 1, ValueFromRemainingArguments = $true)][string[]]$Rest,
    [switch]$Yes,
    [int]$Budget = 6
)
if ($PSVersionTable.PSVersion.Major -lt 3) {
    Write-Host 'JANITOR needs Windows PowerShell 3.0 or newer (this is version' $PSVersionTable.PSVersion.ToString() ').' -ForegroundColor Red
    Write-Host 'Windows 7 SP1: install the free Windows Management Framework 5.1 from Microsoft, then run again. Nothing was changed.'
    exit 1
}
$Version = '0.1.2'
$ErrorActionPreference = 'Continue'
$UserHome = $env:USERPROFILE
$State = if ($env:JANITOR_HOME) { $env:JANITOR_HOME } else { Join-Path $env:LOCALAPPDATA 'JANITOR' }
$QRoot = if ($env:JANITOR_QUARANTINE) { $env:JANITOR_QUARANTINE } else { Join-Path $UserHome 'Downloads\#Review&Delete\JANITOR' }
$Last = Join-Path $State 'last-scan.tsv'
New-Item -ItemType Directory -Force -Path $State | Out-Null
$LogFile = Join-Path $State ('janitor-{0:yyyyMMdd}.log' -f (Get-Date))
$Tab = "`t"
$Inv = [System.Globalization.CultureInfo]::InvariantCulture

function Log($m) { Add-Content -Path $LogFile -Value ('{0:s} {1}' -f (Get-Date), $m) -ErrorAction SilentlyContinue }
function HK($kb) {   # invariant culture: always "5.0 GB", never "5,0 GB"
    if ($kb -ge 1048576) { ($kb / 1048576).ToString('N1', $Inv) + ' GB' }
    elseif ($kb -ge 1024) { ($kb / 1024).ToString('N1', $Inv) + ' MB' }
    else { ([string]$kb) + ' KB' }
}
function Abbr($p) { if ($p -and $p.StartsWith($UserHome, [StringComparison]::OrdinalIgnoreCase)) { '~' + $p.Substring($UserHome.Length) } else { $p } }
function Exists($p) { Test-Path -LiteralPath $p }
function Die($m) { Write-Host $m -ForegroundColor Red; exit 1 }
function Confirm-Action($q) { if ($Yes) { return $true }; $a = Read-Host "$q [y/N]"; return ($a -eq 'y' -or $a -eq 'Y') }

# ---------- safety primitives ----------
$CloudRoots = @()
foreach ($v in 'OneDrive', 'OneDriveConsumer', 'OneDriveCommercial') { $p = [Environment]::GetEnvironmentVariable($v); if ($p) { $CloudRoots += $p.TrimEnd('\') } }
foreach ($n in 'Dropbox', 'Google Drive', 'GoogleDrive', 'iCloudDrive', 'Box', 'pCloudDrive', 'MEGA', 'Sync') { $CloudRoots += (Join-Path $UserHome $n) }

function Test-Under($path, $root) {
    if (-not $path -or -not $root) { return $false }
    $p = $path.TrimEnd('\'); $r = $root.TrimEnd('\')
    return ($p -ieq $r) -or $p.StartsWith($r + '\', [StringComparison]::OrdinalIgnoreCase)
}
function Get-StorageClass($path) {
    foreach ($r in $CloudRoots) { if (Test-Under $path $r) { return 'FILE_PROVIDER-CLOUD' } }
    foreach ($pr in @($env:SystemRoot, $env:ProgramFiles, ${env:ProgramFiles(x86)}, $env:ProgramData)) { if ($pr -and (Test-Under $path $pr)) { return 'PROTECTED' } }
    if ($path -like '\\*') { return 'NETWORK' }
    try {
        $d = New-Object System.IO.DriveInfo ($path.Substring(0, 1))
        if ($d.DriveType -eq 'Network') { return 'NETWORK' }
        if ($d.DriveType -eq 'Removable') { return 'EXTERNAL' }
    } catch { }
    return 'LOCAL'
}
function Test-CloudItem($fi) {   # recall-on-access / offline placeholders = cloud-only content
    $a = [int]$fi.Attributes
    return (($a -band 0x400000) -ne 0) -or (($a -band 0x40000) -ne 0) -or (($a -band 0x1000) -ne 0)
}
function Test-Broad($path) {      # profile folder, a drive root, or anything containing the profile
    $r = Resolve-Path -LiteralPath $path -ErrorAction SilentlyContinue
    if (-not $r) { return $false }
    $p = $r.ProviderPath.TrimEnd('\'); $h = $UserHome.TrimEnd('\')
    return ($p -ieq $h) -or ($p -match '^[A-Za-z]:$') -or $h.StartsWith($p + '\', [StringComparison]::OrdinalIgnoreCase)
}
$ManagedName = '^(\..*|#review.*|.*backup.*|.*lkg.*|objects|blobs|node_modules|vendor|Pods|DerivedData|snapshots|AppData|\$RECYCLE\.BIN|System Volume Information)$'
$Markers = '.git', 'Package.swift', 'package.json', 'Cargo.toml', 'pyproject.toml', 'build.gradle', 'build.gradle.kts', 'pom.xml', 'go.mod', 'Podfile'
function Test-Managed($dir) {     # DirectoryInfo
    if ($dir.Name -imatch $ManagedName) { return $true }
    if (Test-Under $dir.FullName $QRoot) { return $true }
    foreach ($m in $Markers) { if (Test-Path -LiteralPath (Join-Path $dir.FullName $m)) { return $true } }
    return $false
}
function Get-DirKB($path, $deadline) {
    $total = [long]0; $partial = $false
    if (Test-Path -LiteralPath $path -PathType Leaf) {
        $f = Get-Item -LiteralPath $path -Force
        if (-not (Test-CloudItem $f)) { $total = $f.Length }
        return [pscustomobject]@{ KB = [long]($total / 1024); Partial = $false }
    }
    $stack = New-Object System.Collections.Generic.Stack[string]; $stack.Push($path)
    while ($stack.Count -gt 0) {
        if ((Get-Date) -gt $deadline) { $partial = $true; break }
        $d = $stack.Pop()
        try {
            $di = New-Object System.IO.DirectoryInfo $d
            foreach ($f in $di.EnumerateFiles()) {
                if ($f.Attributes -band [IO.FileAttributes]::ReparsePoint) { continue }
                if (Test-CloudItem $f) { continue }
                $total += $f.Length
            }
            foreach ($s in $di.EnumerateDirectories()) {
                if ($s.Attributes -band [IO.FileAttributes]::ReparsePoint) { continue }
                $stack.Push($s.FullName)
            }
        } catch { }
    }
    [pscustomobject]@{ KB = [long]($total / 1024); Partial = $partial }
}

# ---------- candidate table ----------
$Cands = New-Object System.Collections.Generic.List[object]
function Add-Cand($safe, $kb, $cat, $path, $keeper) { $Cands.Add([pscustomobject]@{ Safe = $safe; KB = [long]$kb; Cat = $cat; Path = $path; Keeper = $keeper }) }
function Finish-Scan($limit) {
    $rows = @($Cands | Sort-Object KB -Descending | Select-Object -First $limit)
    $lines = @(); $i = 0
    foreach ($r in $rows) { $i++; $lines += ($i, $r.Safe, $r.KB, $r.Cat, $r.Path, $r.Keeper) -join $Tab }
    Set-Content -LiteralPath $Last -Value $lines -Encoding UTF8
    Write-Host ''
    if ($rows.Count -eq 0) { Write-Host '  (nothing to review)' } else {
        '{0,4}  {1,-7} {2,10}  {3,-18} {4}' -f 'ID', 'SAFETY', 'SIZE', 'CATEGORY', 'PATH' | Write-Host
        $i = 0
        foreach ($r in $rows) {
            $i++
            '{0,4}  {1,-7} {2,10}  {3,-18} {4}' -f $i, $r.Safe, (HK $r.KB), $r.Cat, (Abbr $r.Path) | Write-Host
            if ($r.Keeper) { Write-Host ('{0,36} keeps: {1}' -f '', (Abbr $r.Keeper)) -ForegroundColor DarkGray }
        }
    }
    $tot = [long]0; foreach ($r in $rows) { if ($r.Safe -eq 'SAFE') { $tot += $r.KB } }
    Write-Host ''
    Write-Host ("SAFE items: {0} - review, then: janitor quarantine --all-safe | janitor quarantine ID... | janitor delete ID..." -f (HK $tot)) -ForegroundColor Cyan
    Log ("scan: {0} candidates, safe {1}" -f $rows.Count, (HK $tot))
}

# ---------- scan ----------
function Collect($dir, $cat, $safe, $olderThanDays) {
    if (-not (Exists $dir)) { return }
    $cls = Get-StorageClass $dir
    if ($cls -ne 'LOCAL') { Write-Host ("  [DEFERRED]  {0} ({1}) - not traversed" -f (Abbr $dir), $cls); return }
    $deadline = (Get-Date).AddSeconds($Budget); $partial = $false
    $kids = @(Get-ChildItem -LiteralPath $dir -Force -ErrorAction SilentlyContinue)
    foreach ($k in $kids) {
        if ($k.Attributes -band [IO.FileAttributes]::ReparsePoint) { continue }
        if ($k.FullName.Contains($Tab)) { continue }
        if ($olderThanDays -gt 0 -and $k.LastWriteTime -gt (Get-Date).AddDays(-$olderThanDays)) { continue }
        if ((Get-Date) -gt $deadline) { $partial = $true; break }
        $r = Get-DirKB $k.FullName $deadline
        if ($r.Partial) { $partial = $true }
        if ($r.KB -ge 100) { Add-Cand $safe $r.KB $cat $k.FullName '' }
    }
    $st = if ($partial) { 'PARTIAL' } else { 'COMPLETE' }
    Write-Host ("  [{0}]  {1}" -f $st, (Abbr $dir))
}
function Cmd-Scan($mode) {
    if (-not $mode) { $mode = 'quick' }
    Write-Host ("JANITOR {0} - {1} scan  (bounded: {2}s per root, your profile folder is never crawled)" -f $Version, $mode, $Budget) -ForegroundColor White
    $la = $env:LOCALAPPDATA
    Collect $env:TEMP 'STALE TEMP' 'SAFE' 14
    Collect (Join-Path $la 'Microsoft\Windows\INetCache') 'CACHE' 'SAFE' 0
    Collect (Join-Path $la 'D3DSCache') 'CACHE' 'SAFE' 0
    Collect (Join-Path $la 'CrashDumps') 'CRASH DUMP' 'SAFE' 0
    Collect (Join-Path $la 'Microsoft\Windows\WER') 'LOG' 'SAFE' 0
    if ($mode -eq 'full') {
        foreach ($b in 'Google\Chrome\User Data\Default\Cache', 'Microsoft\Edge\User Data\Default\Cache', 'Mozilla\Firefox\Profiles') { Collect (Join-Path $la $b) 'BROWSER CACHE' 'REVIEW' 0 }
    }
    Finish-Scan 60
}

# ---------- duplicates ----------
function Get-Sha($path, $limit) {
    try {
        $sha = [System.Security.Cryptography.SHA256]::Create()
        $fs = [System.IO.File]::Open($path, 'Open', 'Read', 'ReadWrite')
        try {
            if ($limit -gt 0) { $buf = New-Object byte[] $limit; $n = $fs.Read($buf, 0, $limit); $h = $sha.ComputeHash($buf, 0, $n) }
            else { $h = $sha.ComputeHash($fs) }
        } finally { $fs.Dispose(); $sha.Dispose() }
        return ([BitConverter]::ToString($h) -replace '-', '')
    } catch { return $null }
}
function Cmd-Dupes($folders) {
    $roots = @()
    foreach ($f in $folders) {
        if (-not (Test-Path -LiteralPath $f -PathType Container)) { Write-Host "SKIPPED: $f is not a folder"; continue }
        if (Test-Broad $f) { Write-Host ("REFUSED: {0} is your profile folder (or above it). Duplicate scans never run there." -f (Abbr $f)) -ForegroundColor Red; continue }
        $roots += (Resolve-Path -LiteralPath $f).ProviderPath
    }
    if ($roots.Count -eq 0) { foreach ($n in 'Videos', 'Music', 'Pictures', 'Downloads') { $p = Join-Path $UserHome $n; if (Exists $p) { $roots += $p } } }
    Write-Host ("JANITOR {0} - exact duplicates  (files >= 1 MB; managed trees, hidden, backup/LKG, projects, quarantine and cloud storage excluded)" -f $Version) -ForegroundColor White
    $files = New-Object System.Collections.Generic.List[object]
    foreach ($r in $roots) {
        $cls = Get-StorageClass $r
        if ($cls -ne 'LOCAL') { Write-Host ("  [DEFERRED]  {0} ({1})" -f (Abbr $r), $cls); continue }
        $rootDi = New-Object System.IO.DirectoryInfo $r
        if (Test-Managed $rootDi) { Write-Host ("  [EXCLUDED]  {0} looks like a managed tree" -f (Abbr $r)); continue }
        $deadline = (Get-Date).AddSeconds($Budget * 2); $partial = $false
        $stack = New-Object System.Collections.Generic.Stack[object]; $stack.Push(@($r, 0))
        while ($stack.Count -gt 0) {
            if ((Get-Date) -gt $deadline) { $partial = $true; break }
            $item = $stack.Pop(); $d = $item[0]; $depth = $item[1]
            try {
                $di = New-Object System.IO.DirectoryInfo $d
                foreach ($f in $di.EnumerateFiles()) {
                    if ($f.Attributes -band [IO.FileAttributes]::ReparsePoint) { continue }
                    if ($f.Length -lt 1MB -or (Test-CloudItem $f) -or $f.FullName.Contains($Tab)) { continue }
                    $files.Add($f)
                }
                if ($depth -lt 6) {
                    foreach ($s in $di.EnumerateDirectories()) {
                        if ($s.Attributes -band [IO.FileAttributes]::ReparsePoint) { continue }
                        if (Test-Managed $s) { continue }
                        if ((Get-StorageClass $s.FullName) -ne 'LOCAL') { continue }
                        $stack.Push(@($s.FullName, ($depth + 1)))
                    }
                }
            } catch { }
        }
        $st = if ($partial) { 'PARTIAL' } else { 'COMPLETE' }
        Write-Host ("  [{0}]  {1}" -f $st, (Abbr $r))
    }
    $hdead = (Get-Date).AddSeconds($Budget * 5); $partialH = $false
    foreach ($g in ($files | Group-Object Length | Where-Object { $_.Count -gt 1 })) {
        $byPartial = @{}
        foreach ($f in $g.Group) {
            if ((Get-Date) -gt $hdead) { $partialH = $true; break }
            $h = Get-Sha $f.FullName 65536; if ($h) { if (-not $byPartial.ContainsKey($h)) { $byPartial[$h] = @() }; $byPartial[$h] += $f }
        }
        foreach ($pg in $byPartial.Values | Where-Object { $_.Count -gt 1 }) {
            $byFull = @{}
            foreach ($f in $pg) {
                if ((Get-Date) -gt $hdead) { $partialH = $true; break }
                $h = Get-Sha $f.FullName 0; if ($h) { if (-not $byFull.ContainsKey($h)) { $byFull[$h] = @() }; $byFull[$h] += $f }
            }
            foreach ($fg in $byFull.Values | Where-Object { $_.Count -gt 1 }) {
                $sorted = @($fg | Sort-Object LastWriteTimeUtc)
                $keeper = $sorted[0]
                foreach ($dup in $sorted | Select-Object -Skip 1) { Add-Cand 'REVIEW' ([long]($dup.Length / 1024)) 'EXACT DUPLICATE' $dup.FullName $keeper.FullName }
            }
        }
    }
    if ($partialH) { Write-Host '  PARTIAL - time budget reached; run again or narrow the folder' -ForegroundColor Yellow }
    Finish-Scan 300
    Write-Host 'Oldest copy is kept. Items are never auto-deleted; the kept copy is verified before any removal.' -ForegroundColor DarkGray
}

# ---------- quarantine / delete / restore ----------
function Read-Last() {
    if (-not (Exists $Last)) { Die 'No scan results. Run: janitor scan | janitor dupes' }
    $rows = @()
    foreach ($l in (Get-Content -LiteralPath $Last -Encoding UTF8)) {
        if (-not $l) { continue }
        $c = $l -split $Tab
        $rows += [pscustomobject]@{ Id = $c[0]; Safe = $c[1]; KB = [long]$c[2]; Cat = $c[3]; Path = $c[4]; Keeper = $(if ($c.Count -gt 5) { $c[5] } else { '' }) }
    }
    return $rows
}
function Select-Rows($ids) {
    $all = Read-Last
    if ($ids.Count -gt 0 -and ($ids[0] -eq '--all-safe' -or $ids[0] -eq '-all-safe' -or $ids[0] -eq '-AllSafe')) { $sel = @($all | Where-Object { $_.Safe -eq 'SAFE' }) }
    else { $sel = @($all | Where-Object { $ids -contains $_.Id }) }
    if ($sel.Count -eq 0) { Die 'Nothing selected.' }
    return $sel
}
function Test-Keeper($row, $sel) {
    if (-not $row.Keeper) { return $true }
    if (-not (Exists $row.Keeper)) { return $false }
    foreach ($s in $sel) { if ($s.Path -ieq $row.Keeper) { return $false } }
    if ((Test-Path -LiteralPath $row.Path -PathType Leaf) -and ((Get-Item -LiteralPath $row.Keeper -Force).Length -ne (Get-Item -LiteralPath $row.Path -Force).Length)) { return $false }
    return $true
}
function Cmd-Quarantine($ids) {
    $sel = Select-Rows $ids
    $tot = [long]0; foreach ($s in $sel) { $tot += $s.KB }
    Write-Host ("About to move {0} item(s) ({1}) to quarantine at {2}" -f $sel.Count, (HK $tot), (Abbr $QRoot))
    if (-not (Confirm-Action 'Proceed?')) { Write-Host 'Cancelled.'; return }
    New-Item -ItemType Directory -Force -Path $QRoot | Out-Null
    if ((Get-StorageClass $QRoot) -ne 'LOCAL') { Die 'Quarantine root is not LOCAL storage; provider-safe quarantine is not supported in the CLI edition.' }
    $op = '{0:yyyyMMdd-HHmmss}-janitor' -f (Get-Date)
    $dir = Join-Path $QRoot $op; $items = Join-Path $dir 'items'
    New-Item -ItemType Directory -Force -Path $items | Out-Null
    $man = Join-Path $dir 'manifest.tsv'
    Set-Content -LiteralPath $man -Value @("# JANITOR $Version quarantine $op", "# state`toriginal`tdestination`tkb`treason`ttimestamp") -Encoding UTF8
    $moved = 0; $failed = 0; $skipped = 0; $missing = 0; $i = 0
    foreach ($r in $sel) {
        $i++
        if (-not (Exists $r.Path)) { Write-Host ("  MISSING  {0}" -f (Abbr $r.Path)) -ForegroundColor Yellow; $missing++; continue }
        if (Test-Under $r.Path $QRoot) { Write-Host ("  SKIPPED  {0} (already in quarantine)" -f (Abbr $r.Path)); $skipped++; continue }
        $pc = Get-StorageClass (Split-Path -Parent $r.Path)
        if ($pc -ne 'LOCAL') { Write-Host ("  SKIPPED  {0} ({1})" -f (Abbr $r.Path), $pc); $skipped++; continue }
        if ($r.Path.Substring(0, 1) -ine $QRoot.Substring(0, 1)) { Write-Host ("  SKIPPED  {0} (different drive - a move would copy)" -f (Abbr $r.Path)); $skipped++; continue }
        if (-not (Test-Keeper $r $sel)) { Write-Host ("  SKIPPED  {0} (kept copy missing, changed or also selected)" -f (Abbr $r.Path)); $skipped++; continue }
        $dest = Join-Path $items ('{0:D3}-{1}' -f $i, (Split-Path -Leaf $r.Path))
        try { Move-Item -LiteralPath $r.Path -Destination $dest -ErrorAction Stop } catch { }
        if ((-not (Exists $r.Path)) -and (Exists $dest)) {
            Add-Content -LiteralPath $man -Value (('MOVED', $r.Path, $dest, $r.KB, $r.Cat, ('{0:s}' -f (Get-Date))) -join $Tab) -Encoding UTF8
            Write-Host ("  MOVED    {0}" -f (Abbr $r.Path)) -ForegroundColor Green; $moved++
        } else { Write-Host ("  FAILED   {0}" -f (Abbr $r.Path)) -ForegroundColor Red; $failed++ }
    }
    Write-Host ''
    Write-Host ("{0} MOVED | {1} FAILED | {2} SKIPPED | {3} MISSING -> {4}" -f $moved, $failed, $skipped, $missing, $op) -ForegroundColor White
    Write-Host "Space is freed when the quarantine is purged. Restore with: janitor restore $op"
    Log "quarantine $op moved=$moved failed=$failed skipped=$skipped missing=$missing"
}
function Cmd-Delete($ids) {
    $sel = Select-Rows $ids
    $tot = [long]0; foreach ($s in $sel) { $tot += $s.KB }
    Write-Host ("PERMANENTLY delete {0} item(s) ({1})? This cannot be undone. Prefer 'quarantine'." -f $sel.Count, (HK $tot)) -ForegroundColor Red
    if (-not $Yes) { $a = Read-Host 'Type DELETE to confirm'; if ($a -cne 'DELETE') { Write-Host 'Cancelled.'; return } }
    $gone = 0; $failed = 0; $skipped = 0; $freed = [long]0
    foreach ($r in $sel) {
        if (-not (Exists $r.Path)) { Write-Host ("  MISSING  {0}" -f (Abbr $r.Path)); continue }
        $depthOk = ($r.Path.TrimEnd('\').Split('\').Count -ge 4)
        if (-not $depthOk -or ((Get-StorageClass (Split-Path -Parent $r.Path)) -ne 'LOCAL') -or -not (Test-Keeper $r $sel)) { Write-Host ("  SKIPPED  {0}" -f (Abbr $r.Path)); $skipped++; continue }
        try { Remove-Item -LiteralPath $r.Path -Recurse -Force -ErrorAction Stop } catch { }
        if (Exists $r.Path) { Write-Host ("  FAILED   {0}" -f (Abbr $r.Path)) -ForegroundColor Red; $failed++ }
        else { Write-Host ("  DELETED  {0}" -f (Abbr $r.Path)) -ForegroundColor Green; $gone++; $freed += $r.KB }
    }
    Write-Host ''
    Write-Host ("{0} DELETED | {1} FAILED | {2} SKIPPED - removed {3} (size from scan; removal verified per item)" -f $gone, $failed, $skipped, (HK $freed)) -ForegroundColor White
    Log "delete deleted=$gone failed=$failed skipped=$skipped freed_kb=$freed"
}
function Read-Manifest($op) {
    $man = Join-Path (Join-Path $QRoot $op) 'manifest.tsv'
    if (-not (Exists $man)) { Die "Unknown operation '$op'. See: janitor list" }
    $rows = @()
    foreach ($l in (Get-Content -LiteralPath $man -Encoding UTF8)) {
        if (-not $l -or $l.StartsWith('#')) { continue }
        $c = $l -split $Tab
        $state = $c[0]
        if ($state -eq 'MOVED' -and -not (Exists $c[2])) { $state = 'MISSING' }   # removed by hand: tolerated
        $rows += [pscustomobject]@{ State = $state; Original = $c[1]; Dest = $c[2]; KB = $c[3]; Reason = $c[4]; Time = $c[5] }
    }
    return @{ Path = $man; Rows = $rows }
}
function Save-Manifest($m, $op) {
    $lines = @("# JANITOR $Version quarantine $op", "# state`toriginal`tdestination`tkb`treason`ttimestamp")
    foreach ($r in $m.Rows) { $lines += ($r.State, $r.Original, $r.Dest, $r.KB, $r.Reason, $r.Time) -join $Tab }
    Set-Content -LiteralPath $m.Path -Value $lines -Encoding UTF8
}
function Cmd-List() {
    if (-not (Exists $QRoot)) { Write-Host ("No quarantine yet ({0})." -f (Abbr $QRoot)); return }
    $any = $false
    foreach ($d in (Get-ChildItem -LiteralPath $QRoot -Directory -ErrorAction SilentlyContinue | Sort-Object Name -Descending)) {
        if (-not (Exists (Join-Path $d.FullName 'manifest.tsv'))) { continue }
        $any = $true; $m = Read-Manifest $d.Name; Save-Manifest $m $d.Name
        $sum = ($m.Rows | Group-Object State | ForEach-Object { '{0} {1}' -f $_.Count, $_.Name }) -join '  '
        Write-Host ("{0}  {1}" -f $d.Name, $sum)
    }
    if (-not $any) { Write-Host 'No quarantine operations.' }
}
function Cmd-Show($op) {
    if (-not $op) { Die 'Usage: janitor show OP' }
    $m = Read-Manifest $op; $i = 0
    foreach ($r in $m.Rows) { $i++; '{0,3}  {1,-8} {2}' -f $i, $r.State, $r.Original | Write-Host }
}
function Get-UniqueTarget($t) {
    $dir = Split-Path -Parent $t; $base = [IO.Path]::GetFileNameWithoutExtension($t); $ext = [IO.Path]::GetExtension($t); $n = 1
    while ($true) { $c = Join-Path $dir ('{0} (restored {1}){2}' -f $base, $n, $ext); if (-not (Exists $c)) { return $c }; $n++ }
}
function Cmd-Restore($args2) {
    if (-not $args2 -or $args2.Count -lt 1) { Die 'Usage: janitor restore OP [N ...]' }
    $op = $args2[0]; $picks = @($args2 | Select-Object -Skip 1)
    $m = Read-Manifest $op; $n = 0; $ok = 0; $miss = 0; $fail = 0
    foreach ($r in $m.Rows) {
        $n++
        if ($picks.Count -gt 0 -and ($picks -notcontains "$n")) { continue }
        if ($r.State -eq 'MISSING') { Write-Host ("  MISSING  {0} (removed from quarantine)" -f (Abbr $r.Original)); $miss++; continue }
        if ($r.State -ne 'MOVED') { continue }
        $target = $r.Original
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $target) | Out-Null
        if (Exists $target) { $target = Get-UniqueTarget $target }
        try { Move-Item -LiteralPath $r.Dest -Destination $target -ErrorAction Stop } catch { }
        if ((Exists $target) -and -not (Exists $r.Dest)) {
            $r.State = 'RESTORED'; $ok++
            $note = if ($target -ne $r.Original) { ' (original path was occupied)' } else { '' }
            Write-Host ("  RESTORED {0}{1}" -f (Abbr $target), $note) -ForegroundColor Green
        } else { Write-Host ("  FAILED   {0}" -f (Abbr $r.Original)) -ForegroundColor Red; $fail++ }
    }
    Save-Manifest $m $op
    Write-Host ''; Write-Host ("{0} RESTORED | {1} MISSING | {2} FAILED" -f $ok, $miss, $fail) -ForegroundColor White
    Log "restore $op ok=$ok missing=$miss failed=$fail"
}
function Cmd-Purge($op) {
    if (-not $op) { Die 'Usage: janitor purge OP' }
    $dir = Join-Path $QRoot $op
    if (-not (Exists $dir)) { Die "Unknown operation '$op'." }
    if (-not (Confirm-Action "Permanently delete quarantine operation $op? Items inside can no longer be restored.")) { Write-Host 'Cancelled.'; return }
    try { Remove-Item -LiteralPath $dir -Recurse -Force -ErrorAction Stop } catch { }
    if (Exists $dir) { Die 'FAILED: still present' } else { Write-Host "DELETED $op"; Log "purge $op" }
}
function Cmd-Diag() {
    Write-Host "JANITOR $Version diagnostics" -ForegroundColor White
    Write-Host ("Windows: {0} | PowerShell {1} | {2}" -f [Environment]::OSVersion.VersionString, $PSVersionTable.PSVersion, $env:PROCESSOR_ARCHITECTURE)
    Write-Host ("Cloud roots detected: {0}" -f ((($CloudRoots | Where-Object { Exists $_ }) -join ', ') -replace '^$', 'none'))
    Write-Host ("Quarantine root: {0} - class {1} - {2}" -f (Abbr $QRoot), (Get-StorageClass $QRoot), $(if (Exists $QRoot) { 'exists' } else { 'not created yet' }))
    Write-Host ("State: {0}" -f (Abbr $State))
}
function Cmd-Help() {
@"
JANITOR $Version - safe cleanup, quarantine and recovery (Windows CLI)
  janitor scan [quick|full]           bounded scan of temp, caches, crash dumps -> numbered candidates
  janitor dupes [FOLDER...]           exact duplicates (default: Videos Music Pictures Downloads; never your profile folder)
  janitor quarantine ID...|--all-safe move selected candidates into the reviewable quarantine (verified)
  janitor delete ID...                permanent delete (type DELETE to confirm)
  janitor list | show OP              quarantine operations / items
  janitor restore OP [N...]           restore all or selected items (collision-safe; missing items tolerated)
  janitor purge OP                    permanently delete one quarantine operation
  janitor diag                        environment check
Options: -Yes skips confirmation prompts   -Budget N seconds per root (default 6)
Unknown != junk. OneDrive/Dropbox/Google Drive/iCloud storage is never traversed, hashed or modified here.
"@ | Write-Host
}

$r2 = @($Rest | Where-Object { $_ })
switch ($Command.ToLower()) {
    'scan'       { Cmd-Scan ($r2 | Select-Object -First 1) }
    'dupes'      { Cmd-Dupes $r2 }
    { $_ -in 'quarantine', 'q' } { Cmd-Quarantine $r2 }
    'delete'     { Cmd-Delete $r2 }
    { $_ -in 'list', 'ls' } { Cmd-List }
    'show'       { Cmd-Show ($r2 | Select-Object -First 1) }
    'restore'    { Cmd-Restore $r2 }
    'purge'      { Cmd-Purge ($r2 | Select-Object -First 1) }
    'diag'       { Cmd-Diag }
    { $_ -in 'version', '--version' } { Write-Host $Version }
    default      { Cmd-Help }
}
