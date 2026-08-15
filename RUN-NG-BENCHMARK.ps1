# ==========================================================================
# NeuroGraph ANGP v4.3-EXT -- INTERACTIVE MULTI-SHARD TPS BENCHMARK
# ==========================================================================
# Config: 333 shards x 8 nodes/shard = 2664 nodes (optimal)
# Results saved automatically in benchmark-reports/
# Batch processing: 4 shards parallel x 2 Rayon threads/shard
#
# 37 Attacker Types (T0-T36) -- Behavioral Strategies:
#   T0  Random                T13 Rep-Farmer             T26 AntiCoordination
#   T1  Mimicry300            T14 Oscillating-Drift      T27 RepCamouflage
#   T2  Mimicry500            T15 Colluding-Committee    T28 LongPoison
#   T3  Adaptive-RepAware     T16 SlowPoison             T29 HonestMalSwitch
#   T4  Coordinated-Bias      T17 Eclipse                T30 ThrBoundary
#   T5  Gaussian              T18 MajRefManip            T31 RecoveryExploit
#   T6  FlipFlop              T19 SybilReplace           T32 SybilCycling
#   T7  Sleeper               T20 PatientByz             T33 ColludHonestMaj
#   T8  Progressive-Drift     T21 ThresholdGamer         T34 ConsensusTarget
#   T9  Outlier-Burst         T22 TrueFeedbackAdapt      T35 MultiVectorBoss
#   T10 Clone-Copy            T23 RepGradient            T36 WorstCaseCoord
#   T11 Byzantine             T24 DetectorMimicry
#   T12 Sybil-Cluster         T25 DistribInfluence
#
# USAGE:
#   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
#   .\RUN-NG-BENCHMARK.ps1
#
#   IMPORTANT: Run as a FILE (.\RUN-NG-BENCHMARK.ps1), do NOT paste into
#   the console -- the try/catch inside while-loop breaks the interactive parser.
# ==========================================================================

# --- Self-elevate execution policy (avoids "not digitally signed" error) ---
if ($PSVersionTable.PSVersion.Major -ge 5) {
    $currentPolicy = Get-ExecutionPolicy -Scope Process -ErrorAction SilentlyContinue
    if ($currentPolicy -eq 'Restricted' -or $currentPolicy -eq 'AllSigned') {
        Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force -ErrorAction SilentlyContinue
    }
}

$ErrorActionPreference = 'Continue'

# --- Cross-platform chcp (Windows-only) ---
$isWindows = $true
if ($PSVersionTable.PSVersion.Major -ge 6) {
    $isWindows = -not $IsLinux -and -not $IsMacOS
}
if ($isWindows) {
    chcp 65001 > $null 2>&1
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
}

# ===================== PRE-BUILD =====================
$originalPath = Get-Location

$ProjectDir = (Get-Location).Path
# --- Pre-compiled binary detection ---
$PrecompiledBinary = $null
$preBin = Join-Path $PSScriptRoot "bin\sim_stress_v43ext.exe"
if (Test-Path $preBin) {
    $PrecompiledBinary = $preBin
    Write-Host "[SETUP] Pre-compiled binary found: $preBin" -ForegroundColor Green
    $ProjectDir = $PSScriptRoot
} else {
    # Fallback: find project root via Cargo.toml
    $current = $PSScriptRoot
    while ($current -and -not (Test-Path (Join-Path $current "Cargo.toml"))) {
        $current = Split-Path $current -Parent
    }
    if (-not $current -or -not (Test-Path (Join-Path $current "Cargo.toml"))) {
        Write-Host "CRITICAL ERROR: No pre-compiled binary and Cargo.toml not found!" -ForegroundColor Red
        Write-Host "Run setup.ps1 first to download the binary." -ForegroundColor Yellow
        exit 1
    }
    $ProjectDir = $current
    Write-Host "[SETUP] Using source build from: $ProjectDir" -ForegroundColor Cyan
}

$exeExt = if ($isWindows) { '.exe' } else { '' }
$sep = if ($isWindows) { '\' } else { '/' }

# --- CPU physical core detection (PS 5.1 compatible) ---
$coreCount = $null
try {
    $cpus = Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue
    if ($cpus) { $coreCount = ($cpus | Measure-Object -Property NumberOfCores -Sum).Sum }
} catch {}
if (-not $coreCount) { $coreCount = $env:NUMBER_OF_PROCESSORS }
if (-not $coreCount) { $coreCount = '?' }
$osName = if ($isWindows) { 'Windows' } else { 'Linux/macOS' }

if ($PrecompiledBinary) {
    $simBinary = $PrecompiledBinary
    Write-Host "[BUILD] Using pre-compiled binary: $simBinary" -ForegroundColor Green
} else {
    Write-Host "[BUILD] Compiling from source..." -ForegroundColor Cyan
    Push-Location $ProjectDir
    try {
        cargo build --release --example sim_stress_v43ext 2>&1 | ForEach-Object { Write-Host $_ }
        if ($LASTEXITCODE -ne 0) { throw "cargo build failed with exit code $LASTEXITCODE" }
    } finally {
        Pop-Location
    }
    $sep = [System.IO.Path]::DirectorySeparatorChar
    $exeExt = if ($IsWindows -or $env:OS -match "Windows") { ".exe" } else { "" }
    $simBinary = Join-Path $ProjectDir ("target{0}release{0}examples{0}sim_stress_v43ext{1}" -f $sep, $exeExt)
    if (-not (Test-Path $simBinary)) {
        Write-Host "CRITICAL ERROR: Binary not found at $simBinary" -ForegroundColor Red
        exit 1
    }
    Write-Host "[BUILD] Compiled: $simBinary" -ForegroundColor Green
}

# ===================== PRESETS =====================
# All presets use 10,000 steps by default
$presets = @{
    # --- CLEAN (0% attackers) ---
    '1'  = @{ Shards=333; Nodes=8;  Percent=0;  Steps=10000 }
    '2'  = @{ Shards=100; Nodes=8;  Percent=0;  Steps=10000 }
    '3'  = @{ Shards=200; Nodes=8;  Percent=0;  Steps=10000 }
    '4'  = @{ Shards=444; Nodes=8;  Percent=0;  Steps=10000 }
    '5'  = @{ Shards=222; Nodes=8;  Percent=0;  Steps=10000 }
    # --- WITH ATTACKERS ---
    '6'  = @{ Shards=333; Nodes=8;  Percent=10; Steps=10000 }
    '7'  = @{ Shards=333; Nodes=8;  Percent=30; Steps=10000 }
    '8'  = @{ Shards=333; Nodes=8;  Percent=50; Steps=10000 }
    '9'  = @{ Shards=100; Nodes=8;  Percent=10; Steps=10000 }
    '10' = @{ Shards=200; Nodes=8;  Percent=10; Steps=10000 }
}

$reportDir = Join-Path $ProjectDir 'benchmark-reports'
if (-not (Test-Path $reportDir)) { New-Item -ItemType Directory -Path $reportDir | Out-Null }

# ===================== ATTACKER TYPE DEFINITIONS =====================
$attackerTypes = @(
    @{ Id='T0';  Name='Random';                Desc='Submits random proposals; no strategy, pure noise' },
    @{ Id='T1';  Name='Mimicry300';            Desc='Copies top-300 honest nodes'' predictions with slight drift' },
    @{ Id='T2';  Name='Mimicry500';            Desc='Copies top-500 honest nodes'' predictions with slight drift' },
    @{ Id='T3';  Name='Adaptive-RepAware';     Desc='Adapts behavior based on reputation scores of neighbors' },
    @{ Id='T4';  Name='Coordinated-Bias';      Desc='Multiple nodes coordinate to bias consensus in one direction' },
    @{ Id='T5';  Name='Gaussian';              Desc='Generates proposals from a Gaussian distribution centered off-consensus' },
    @{ Id='T6';  Name='FlipFlop';              Desc='Alternates between honest and malicious behavior each step' },
    @{ Id='T7';  Name='Sleeper';               Desc='Acts honestly for N steps, then switches to attack mode' },
    @{ Id='T8';  Name='Progressive-Drift';     Desc='Gradually drifts predictions away from consensus over time' },
    @{ Id='T9';  Name='Outlier-Burst';         Desc='Sends burst of extreme outlier proposals at intervals' },
    @{ Id='T10'; Name='Clone-Copy';            Desc='Copies another node''s proposal exactly (identity theft)' },
    @{ Id='T11'; Name='Byzantine';             Desc='Classic BFT: sends different values to different peers' },
    @{ Id='T12'; Name='Sybil-Cluster';         Desc='Creates multiple fake identities that reinforce each other' },
    @{ Id='T13'; Name='Rep-Farmer';            Desc='Exploits reputation system to inflate own score artificially' },
    @{ Id='T14'; Name='Oscillating-Drift';     Desc='Oscillates predictions sinusoidally around consensus median' },
    @{ Id='T15'; Name='Colluding-Committee';   Desc='Group of nodes collude to control a VRF committee selection' },
    @{ Id='T16'; Name='SlowPoison';            Desc='Subtly shifts consensus over many steps; nearly undetectable' },
    @{ Id='T17'; Name='Eclipse';               Desc='Isolates a target node by surrounding it with attacker peers' },
    @{ Id='T18'; Name='MajRefManip';           Desc='Manipulates majority reference to shift finalization choices' },
    @{ Id='T19'; Name='SybilReplace';          Desc='Replaces honest nodes'' identities with Sybil copies over time' },
    @{ Id='T20'; Name='PatientByz';            Desc='Waits for critical round then executes Byzantine attack' },
    @{ Id='T21'; Name='ThresholdGamer';        Desc='Stays just below detection threshold while maximizing damage' },
    @{ Id='T22'; Name='TrueFeedbackAdapt';     Desc='Uses feedback from detection system to evade it adaptively' },
    @{ Id='T23'; Name='RepGradient';           Desc='Climbs reputation gradient to maximize influence on consensus' },
    @{ Id='T24'; Name='DetectorMimicry';       Desc='Mimics the behavior of the detection algorithm to avoid flags' },
    @{ Id='T25'; Name='DistribInfluence';      Desc='Distributes attack influence across many small manipulations' },
    @{ Id='T26'; Name='AntiCoordination';      Desc='Prevents honest nodes from coordinating by disrupting signals' },
    @{ Id='T27'; Name='RepCamouflage';         Desc='Maintains high reputation while occasionally injecting attacks' },
    @{ Id='T28'; Name='LongPoison';            Desc='Slow poisoning over extended horizon (1000+ steps) before striking' },
    @{ Id='T29'; Name='HonestMalSwitch';       Desc='Switches between honest and malicious based on network conditions' },
    @{ Id='T30'; Name='ThrBoundary';           Desc='Operates exactly at detection threshold boundary to maximize evasion' },
    @{ Id='T31'; Name='RecoveryExploit';       Desc='Exploits recovery mechanisms after a crash to inject bad state' },
    @{ Id='T32'; Name='SybilCycling';          Desc='Cycles through Sybil identities to avoid long-term detection' },
    @{ Id='T33'; Name='ColludHonestMaj';       Desc='Colludes while appearing as honest majority to observers' },
    @{ Id='T34'; Name='ConsensusTarget';       Desc='Targets specific consensus rounds to maximize finalization impact' },
    @{ Id='T35'; Name='MultiVectorBoss';       Desc='Combines multiple attack vectors simultaneously for maximum damage' },
    @{ Id='T36'; Name='WorstCaseCoord';        Desc='Worst-case coordinated attack: all attackers act in perfect sync' }
)

# ===================== HELPER FUNCTIONS =====================
function Log-Report($txt, [string]$Color) {
    if ($Color) {
        Write-Host $txt -ForegroundColor $Color
    } else {
        Write-Host $txt
    }
    $script:allReportLines += $txt
}

# ===================== MAIN MENU (LOOP) =====================

while ($true) {

    Write-Host ''
    Write-Host '=============================================================' -ForegroundColor Cyan
    Write-Host '  NeuroGraph ANGP v4.3-EXT -- MULTI-SHARD TPS BENCHMARK' -ForegroundColor Cyan
    Write-Host '  333 shards x 8 nodes/shard = 2664 nodes (optimal)' -ForegroundColor Gray
    Write-Host '  37 Attacker Types (T0-T36) | Behavioral Strategies' -ForegroundColor Gray
    Write-Host '  Batch 4 shards x 2 Rayon threads/shard = 8 threads/batch' -ForegroundColor DarkCyan
    Write-Host '=============================================================' -ForegroundColor Cyan
    Write-Host ''
    Write-Host '  CLEAN (no attackers, 0%)' -ForegroundColor Green
    Write-Host '    [1]  333 shards x 8 nodes/shard   (2664 total, 10K steps) -- OPTIMAL' -ForegroundColor White
    Write-Host '    [2]  100 shards x 8 nodes/shard   (800 total,  10K steps)' -ForegroundColor White
    Write-Host '    [3]  200 shards x 8 nodes/shard   (1600 total, 10K steps)' -ForegroundColor White
    Write-Host '    [4]  444 shards x 8 nodes/shard   (3552 total, 10K steps)' -ForegroundColor White
    Write-Host '    [5]  222 shards x 8 nodes/shard   (1776 total, 10K steps)' -ForegroundColor White
    Write-Host ''
    Write-Host '  WITH ATTACKERS (37 types T0-T36)' -ForegroundColor Red
    Write-Host '    [6]  333 shards x 8 nodes/shard   (2664 total, 10% atk, 10K steps)' -ForegroundColor White
    Write-Host '    [7]  333 shards x 8 nodes/shard   (2664 total, 30% atk, 10K steps)' -ForegroundColor White
    Write-Host '    [8]  333 shards x 8 nodes/shard   (2664 total, 50% atk, 10K steps)' -ForegroundColor White
    Write-Host '    [9]  100 shards x 8 nodes/shard   (800 total,  10% atk, 10K steps)' -ForegroundColor White
    Write-Host '   [10]  200 shards x 8 nodes/shard  (1600 total, 10% atk, 10K steps)' -ForegroundColor White
    Write-Host ''
    Write-Host '    [11] Custom (configure everything manually)' -ForegroundColor Yellow
    Write-Host '   [99] List all 37 attacker types with descriptions' -ForegroundColor DarkCyan
    Write-Host '    [0]  Exit' -ForegroundColor DarkGray
    Write-Host ''
    $choice = Read-Host '  Option'

    # ---- EXIT ----
    if ($choice -eq '0') {
        Write-Host ''
        Write-Host '  Goodbye!' -ForegroundColor Cyan
        Set-Location $originalPath
        exit 0
    }
    # ---- LIST ATTACKER TYPES (detailed, English) ----
    if ($choice -eq '99') {
        Write-Host ''
        Write-Host '  ============================================================' -ForegroundColor Cyan
        Write-Host '  37 Attacker Types (T0-T36) -- Behavioral Strategies' -ForegroundColor Cyan
        Write-Host '  ============================================================' -ForegroundColor Cyan
        Write-Host ''
        Write-Host '  FOUNDATION (T0-T15) -- 16 base strategies:' -ForegroundColor Yellow
        for ($ai = 0; $ai -lt 16; $ai++) {
            $at = $attackerTypes[$ai]
            Write-Host ("    {0,-4} {1,-24} {2}" -f $at.Id, $at.Name, $at.Desc) -ForegroundColor White
        }
        Write-Host ''
        Write-Host '  EXTENSION-1 (T16-T21) -- 6 advanced strategies:' -ForegroundColor Yellow
        for ($ai = 16; $ai -lt 22; $ai++) {
            $at = $attackerTypes[$ai]
            Write-Host ("    {0,-4} {1,-24} {2}" -f $at.Id, $at.Name, $at.Desc) -ForegroundColor White
        }
        Write-Host ''
        Write-Host '  EXTENSION-2 (T22-T36) -- 15 advanced strategies:' -ForegroundColor Yellow
        for ($ai = 22; $ai -lt 37; $ai++) {
            $at = $attackerTypes[$ai]
            Write-Host ("    {0,-4} {1,-24} {2}" -f $at.Id, $at.Name, $at.Desc) -ForegroundColor White
        }
        Write-Host ''
        Write-Host '  Total: 37 attacker types (T0-T36)' -ForegroundColor Green
        Write-Host ''
        Read-Host '  Press ENTER to continue'
        continue
    }
    # ---- CUSTOM ----
    if ($choice -eq '11') {
        Write-Host ''
        Write-Host '  --- CUSTOM ---' -ForegroundColor Yellow
        $cShards = Read-Host '  Shards (1-500)'
        $cNodes = Read-Host '  Nodes per shard [default: 8]'
        $si = Read-Host '  Steps [default: 10000]'
        $pi = Read-Host '  Attackers % [default: 10]'
        $cSteps = if ($si) { [int]$si } else { 10000 }
        $cPercent = if ($pi) { [int]$pi } else { 10 }
        if (-not $cNodes) { $cNodes = 8 }
        $validShards = $false; try { $cShards = [int]$cShards; $validShards = $true } catch {}
        $validNodes = $false; try { $cNodes = [int]$cNodes; $validNodes = $true } catch {}
        if (-not $validShards -or $cShards -lt 1 -or $cShards -gt 500) {
            Write-Host '  Shards: must be between 1 and 500' -ForegroundColor Red
            Start-Sleep -Seconds 2; continue
        }
        if (-not $validNodes -or $cNodes -lt 1) {
            Write-Host '  Nodes: minimum 1' -ForegroundColor Red
            Start-Sleep -Seconds 2; continue
        }
        $NUM_SHARDS = $cShards; $NODES = $cNodes; $STEPS = $cSteps; $PERCENT = $cPercent
    }
    # ---- PRESETS ----
    elseif ($presets.ContainsKey($choice)) {
        $p = $presets[$choice]
        $NUM_SHARDS = $p.Shards; $NODES = $p.Nodes; $PERCENT = $p.Percent; $STEPS = $p.Steps
    }
    else {
        Write-Host '  Invalid option.' -ForegroundColor Red
        Start-Sleep -Seconds 1; continue
    }

    # ===================== RUN TEST =====================

    # Batch 4 shards in parallel, 2 Rayon threads per shard
    $BATCH_SIZE = 4

    $SHARD_IPS = @()
    for ($idx = 0; $idx -lt $NUM_SHARDS; $idx++) {
        $oct3 = [m[Math]::Floor($idx / 254) + 1
        $oct4 = ($idx % 254) + 1
        $port = 8100 + $idx
        $SHARD_IPS += ('10.0.{0}.{1}:{2}' -f $oct3, $oct4, $port)
    }

    $allReportLines = @()

    try {
        $batchCount = [m[Math]::Ceiling($NUM_SHARDS / $BATCH_SIZE)
        $totalNodes = $NUM_SHARDS * $NODES
        $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'

        Log-Report ''
        Log-Report '============================================================'
        $hdr = '  NeuroGraph ANGP v4.3-EXT  -  {0} SHARDS x {1} NODES/SHARD  |  {2} total nodes  |  {3}% attackers  |  {4} steps' -f $NUM_SHARDS, $NODES, $totalNodes, $PERCENT, $STEPS
        Log-Report $hdr
        Log-Report ('  Date: {0}' -f $timestamp)
        Log-Report '  37 attacker types (T0-T36): T0-T15 (16 base) + T16-T21 (6 ext1) + T22-T36 (15 ext2)' -ForegroundColor Gray
        Log-Report '============================================================'

        $LogDir = Join-Path $ProjectDir ('shard-logs-{0}s-{1}n-{2}atk' -f $NUM_SHARDS, $NODES, $PERCENT)
        if (-not (Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir | Out-Null }
        Remove-Item (Join-Path $LogDir 'shard_*.log') -Force -ErrorAction SilentlyContinue
        Remove-Item (Join-Path $LogDir '*.tmp') -Force -ErrorAction SilentlyContinue
        Remove-Item (Join-Path $LogDir '*.bat') -Force -ErrorAction SilentlyContinue
        Remove-Item (Join-Path $LogDir '*.sh') -Force -ErrorAction SilentlyContinue

        Log-Report ''
        Log-Report ("  SYSTEM: {0} CPU cores  {1}" -f $coreCount, $osName)
        Log-Report ("  BINARY: {0}" -f $simBinary)
        Log-Report ("  LOGS:  {0}" -f $LogDir)
        Log-Report ''
        Log-Report '  CONFIG:'
        Log-Report ("    Shards:                   {0}" -f $NUM_SHARDS)
        Log-Report ("    Nodes per shard:          {0}" -f $NODES)
        Log-Report ("    Total nodes:              {0}" -f $totalNodes)
        Log-Report ("    Batch size (parallel):    {0}" -f $BATCH_SIZE)
        Log-Report ("    Batches total:            {0}" -f $batchCount)
        Log-Report ("    Steps:                    {0}" -f $STEPS)
        Log-Report ("    Attackers:                {0}% (37 types: T0-T36)" -f $PERCENT)
        Log-Report '    RAYON_NUM_THREADS:        2 per shard'
        Log-Report ("    Batch config:             {0} shards x 2 Rayon = {1} threads/batch" -f $BATCH_SIZE, ($BATCH_SIZE * 2))
        Log-Report ''
        Log-Report '============================================================'

        Log-Report ('[1/3] Running {0} shards in {1} batches of {2}...' -f $NUM_SHARDS, $batchCount, $BATCH_SIZE)
        Log-Report ''

        $wallStart = [System.Diagnostics.Stopwatch]::StartNew()
        $okCount = 0
        $failCount = 0
        $globalBatchNum = 0

        for ($batchStart = 0; $batchStart -lt $NUM_SHARDS; $batchStart += $BATCH_SIZE) {
            $batchEnd = [Math]::Min($batchStart + $BATCH_SIZE, $NUM_SHARDS)
            $globalBatchNum++
            $pctDone = [math]::Round(($batchStart / $NUM_SHARDS) * 100)
            $wallSoFar = [math]::Round($wallStart.Elapsed.TotalSeconds)

            $bmsg = '  [{0}/{1}] Shards {2}..{3}  ({4}%  |  {5}s elapsed)' -f $globalBatchNum, $batchCount, $batchStart, ($batchEnd - 1), $pctDone, $wallSoFar
            Write-Host $bmsg -ForegroundColor DarkCyan

            $jobs = @()

            for ($i = $batchStart; $i -lt $batchEnd; $i++) {
                $logFile = Join-Path $LogDir ("shard_{0}.log" -f $i)
                $ip = $SHARD_IPS[$i]
                $tmpOut = Join-Path $LogDir ("s{0}_out.tmp" -f $i)
                $tmpErr = Join-Path $LogDir ("s{0}_err.tmp" -f $i)

                # --- Cross-platform shard execution ---
                if ($isWindows) {
                    $batFile = Join-Path $LogDir ("run_{0}.bat" -f $i)
                    $batLines = @(
                        '@echo off',
                        ('set SHARD_ID={0}' -f $i),
                        ('set SHARD_IP={0}' -f $ip),
                        'set RAYON_NUM_THREADS=2',
                        ('"{0}" --nodes {1} --steps {2} --percent {3} 1>"{4}" 2>"{5}"' -f $simBinary, $NODES, $STEPS, $PERCENT, $tmpOut, $tmpErr)
                    )
                    [System.IO.File]::WriteAllText($batFile, ($batLines -join "`r`n"), [System.Text.Encoding]::ASCII)

                    $psi = New-Object System.Diagnostics.ProcessStartInfo
                    $psi.FileName = 'cmd.exe'
                    $psi.Arguments = '/c "' + $batFile + '"'
                    $psi.UseShellExecute = $false
                    $psi.CreateNoWindow = $true
                    $proc = [System.Diagnostics.Process]::Start($psi)
                    $jobs += @{ Id=$i; Process=$proc; LogFile=$logFile; TmpOut=$tmpOut; TmpErr=$tmpErr; ScriptFile=$batFile }
                } else {
                    $shFile = Join-Path $LogDir ("run_{0}.sh" -f $i)
                    $shLines = @(
                        '#!/bin/bash',
                        ('export SHARD_ID={0}' -f $i),
                        ('export SHARD_IP={0}' -f $ip),
                        'export RAYON_NUM_THREADS=2',
                        ('"{0}" --nodes {1} --steps {2} --percent {3} 1>"{4}" 2>"{5}"' -f $simBinary, $NODES, $STEPS, $PERCENT, $tmpOut, $tmpErr)
                    )
                    [System.IO.File]::WriteAllText($shFile, ($shLines -join "`n"), [System.Text.Encoding]::UTF8)
                    & chmod +x $shFile

                    $psi = New-Object System.Diagnostics.ProcessStartInfo
                    $psi.FileName = '/bin/bash'
                    $psi.Arguments = '"' + $shFile + '"'
                    $psi.UseShellExecute = $false
                    $psi.CreateNoWindow = $true
                    $proc = [System.Diagnostics.Process]::Start($psi)
                    $jobs += @{ Id=$i; Process=$proc; LogFile=$logFile; TmpOut=$tmpOut; TmpErr=$tmpErr; ScriptFile=$shFile }
                }
            }

            foreach ($job in $jobs) {
                $sid = $job.Id; $proc = $job.Process
                $sw = [System.Diagnostics.Stopwatch]::StartNew()
                while (-not $proc.HasExited) {
                    if ($sw.Elapsed.TotalSeconds -ge 5) {
                        $sec = [m[Math]::Floor($sw.Elapsed.TotalSeconds)
                        Write-Host ("`r    shard {0}: {1}s" -f $sid, $sec) -NoNewline -ForegroundColor DarkGray
                    }
                    Start-Sleep -Milliseconds 500
                }
                $sw.Stop()
                if ($sw.Elapsed.TotalSeconds -ge 5) {
                    Write-Host ("`r    shard {0}: {1}s              " -f $sid, $sw.Elapsed.TotalSeconds.ToString('F1')) -ForegroundColor DarkGray
                }

                $stdout = ''
                $stderr = ''
                if (Test-Path $job.TmpOut) { $stdout = [System.IO.File]::ReadAllText($job.TmpOut); Remove-Item $job.TmpOut -Force -ErrorAction SilentlyContinue }
                if (Test-Path $job.TmpErr) { $stderr = [System.IO.File]::ReadAllText($job.TmpErr); Remove-Item $job.TmpErr -Force -ErrorAction SilentlyContinue }

                if ($proc.ExitCode -ne 0) {
                    $failCount++
                } else {
                    $okCount++
                }
                Set-Content -Path $job.LogFile -Value ($stdout + $stderr) -Encoding UTF8
                Remove-Item $job.ScriptFile -Force -ErrorAction SilentlyContinue
            }

            Write-Host ('         OK: {0}  FAIL: {1}' -f $okCount, $failCount) -ForegroundColor Gray
            Write-Host ''
        }

        $wallElapsed = $wallStart.Elapsed.TotalSeconds
        $wallStart.Stop()

        Log-Report '[2/3] Parsing results...'
        Log-Report ''

        $totalFinalized = 0; $totalGenerated = 0; $totalRejected = 0; $sumTps = 0
        $maxTime = 0; $minTime = [double]::MaxValue; $failedShards = 0

        # Security metric accumulators
        $sumFPR = 0.0; $fprCount = 0
        $sumABR = 0.0; $abrCount = 0
        $totalDSBlocked = 0; $totalDSTotal = 0; $dsCount = 0
        $totalTheftBlocked = 0; $totalTheftTotal = 0; $theftCount = 0

        for ($i = 0; $i -lt $NUM_SHARDS; $i++) {
            $logFile = Join-Path $LogDir ("shard_{0}.log" -f $i)
            if (-not (Test-Path $logFile)) { $failedShards++; continue }
            $content = Get-Content $logFile -Raw
            # --- TPS (multiple format variants) ---
            $tps = 0
            if ($content -match 'Overall TPS:\s*([0-9\.]+)') { $tps = [long]$Matches[1] }
            elseif ($content -match 'TPS:\s*([0-9\.]+)') { $tps = [long]$Matches[1] }
            elseif ($content -match 'tps=([0-9\.]+)') { $tps = [long]$Matches[1] }
            elseif ($content -match '([0-9\.]+)\s*TPS') { $tps = [long]$Matches[1] }
            # --- Finalized ---
            $finalized = 0
            if ($content -match 'Finalized:\s*([0-9]+)') { $finalized = [long]$Matches[1] }
            elseif ($content -match 'finalized=([0-9]+)') { $finalized = [long]$Matches[1] }
            elseif ($content -match 'Finali[sz]ed.*?([0-9]+)') { $finalized = [long]$Matches[1] }
            # --- Generated ---
            $generated = 0
            if ($content -match 'Generated:\s*([0-9]+)') { $generated = [long]$Matches[1] }
            elseif ($content -match 'generated=([0-9]+)') { $generated = [long]$Matches[1] }
            # --- Rejected ---
            $rejected = 0
            if ($content -match 'Rejected:\s*([0-9]+)') { $rejected = [long]$Matches[1] }
            elseif ($content -match 'rejected=([0-9]+)') { $rejected = [long]$Matches[1] }
            # --- Total time ---
            $totalTime = 0.0
            if ($content -match 'Total time:\s*([0-9\.]+)\s*s') { $totalTime = [double]$Matches[1] }
            elseif ($content -match 'total_time=([0-9\.]+)') { $totalTime = [double]$Matches[1] }
            elseif ($content -match 'elapsed.*?([0-9\.]+)\s*s') { $totalTime = [double]$Matches[1] }
            if ($tps -eq 0 -and $finalized -eq 0) {
                $failedShards++
                # Diagnostic: dump first 5 lines so user can see actual binary output format
                if ($failedShards -le 3) {
                    $diagLines = ($content -split "`n" | Select-Object -First 5)
                    Write-Host ("  [DIAG] shard {0} -- no TPS/Finalized match. First 5 lines of log:" -f $i) -ForegroundColor Yellow
                    foreach ($dl in $diagLines) { Write-Host ("    {0}" -f $dl.Trim()) -ForegroundColor DarkYellow }
                }
                continue
            }
            $totalFinalized += $finalized; $totalGenerated += $generated; $totalRejected += $rejected; $sumTps += $tps
            if ($totalTime -gt $maxTime) { $maxTime = $totalTime }
            if ($totalTime -lt $minTime) { $minTime = $totalTime }

            # Parse security metrics
            # FPR -- try multiple format variants from binary output
            if ($content -match 'False Positive Rate \(FPR\):\s*([0-9\.]+)%') {
                $sumFPR += [double]$Matches[1]; $fprCount++
            } elseif ($content -match 'FPR:\s*([0-9\.]+)%') {
                $sumFPR += [double]$Matches[1]; $fprCount++
            } elseif ($content -match 'honest_fpr=([0-9\.]+)') {
                $sumFPR += [double]$Matches[1]; $fprCount++
            }
            # ABR -- try multiple format variants
            if ($content -match 'Attack Blocking Rate \(ABR\):\s*([0-9\.]+)%') {
                $sumABR += [double]$Matches[1]; $abrCount++
            } elseif ($content -match 'ABR:\s*([0-9\.]+)%') {
                $sumABR += [double]$Matches[1]; $abrCount++
            } elseif ($content -match 'attack_block_rate=([0-9\.]+)') {
                $sumABR += [double]$Matches[1]; $abrCount++
            }
            # Double-spend -- try multiple format variants
            if ($content -match 'Double-spend blocked:\s*(\d+)\s*/\s*(\d+)') {
                $totalDSBlocked += [long]$Matches[1]; $totalDSTotal += [long]$Matches[2]; $dsCount++
            } elseif ($content -match 'double_spend_blocked=(\d+)/(\d+)') {
                $totalDSBlocked += [long]$Matches[1]; $totalDSTotal += [long]$Matches[2]; $dsCount++
            } elseif ($content -match 'Double.?spend.*?(\d+)\s*/\s*(\d+)') {
                $totalDSBlocked += [long]$Matches[1]; $totalDSTotal += [long]$Matches[2]; $dsCount++
            }
            # Theft -- try multiple format variants
            if ($content -match 'Theft blocked:\s*(\d+)\s*/\s*(\d+)') {
                $totalTheftBlocked += [long]$Matches[1]; $totalTheftTotal += [long]$Matches[2]; $theftCount++
            } elseif ($content -match 'theft_blocked=(\d+)/(\d+)') {
                $totalTheftBlocked += [long]$Matches[1]; $totalTheftTotal += [long]$Matches[2]; $theftCount++
            } elseif ($content -match 'Theft.*?(\d+)\s*/\s*(\d+)') {
                $totalTheftBlocked += [long]$Matches[1]; $totalTheftTotal += [long]$Matches[2]; $theftCount++
            }
        }

        # Compute averaged security metrics
        $avgFPR = if ($fprCount -gt 0) { [math]::Round($sumFPR / $fprCount, 4) } else { -1 }
        $avgABR = if ($abrCount -gt 0) { [math]::Round($sumABR / $abrCount, 2) } else { -1 }
        $dsPct = if ($totalDSTotal -gt 0) { [math]::Round($totalDSBlocked * 100.0 / $totalDSTotal, 2) } else { -1 }
        $theftPct = if ($totalTheftTotal -gt 0) { [math]::Round($totalTheftBlocked * 100.0 / $totalTheftTotal, 2) } else { -1 }

        $goodShards = $NUM_SHARDS - $failedShards
        Log-Report ("  Shards OK: {0} / {1}" -f $goodShards, $NUM_SHARDS)
        if ($failedShards -gt 0) { Log-Report ("  Shards FAILED: {0}" -f $failedShards) }
        Log-Report ''

        if ($goodShards -gt 0) { $avgTps = [math]::Round($sumTps / $goodShards) } else { $avgTps = 0 }
        if ($wallElapsed -gt 0) { $aggTpsWall = [math]::Round($totalFinalized / $wallElapsed) } else { $aggTpsWall = 0 }
        if ($maxTime -gt 0) { $aggTpsFullPar = [math]::Round($totalFinalized / $maxTime) } else { $aggTpsFullPar = 0 }
        $tps333Full = [math]::Round($avgTps * 333.0)
        if ($totalGenerated -gt 0) { $finRate = [math]::Round($totalFinalized * 100.0 / $totalGenerated, 2) } else { $finRate = 0 }
        if ($sumTps -gt 0) { $scalingEff = [math]::Round($aggTpsFullPar * 100.0 / $sumTps, 1) } else { $scalingEff = 0 }

        Log-Report '[3/3] FINAL RESULTS'
        Log-Report ''
        Log-Report '============================================================'
        Log-Report ('  NeuroGraph ANGP v4.3-EXT  -  {0} SHARDS x {1} NODES/SHARD  ({2} total)' -f $NUM_SHARDS, $NODES, $totalNodes)
        Log-Report '============================================================'
        Log-Report ''
        Log-Report '  SYSTEM:'
        Log-Report ("    CPU cores:               {0}" -f $coreCount)
        Log-Report ("    Shards:                   {0} (OK: {1})" -f $NUM_SHARDS, $goodShards)
        Log-Report ("    Nodes per shard:          {0}" -f $NODES)
        Log-Report ("    Total nodes:              {0}" -f $totalNodes)
        Log-Report ("    Batch size:               {0} (2 threads/shard)" -f $BATCH_SIZE)
        Log-Report ("    Steps:                    {0}" -f $STEPS)
        Log-Report ("    Attackers:                {0}% (37 types: T0-T36)" -f $PERCENT)
        Log-Report ''
        Log-Report '  TRANSACTIONS:'
        Log-Report ('    Total generated:         {0:N0}' -f $totalGenerated)
        Log-Report ('    Total finalized:         {0:N0}' -f $totalFinalized)
        Log-Report ('    Total rejected:           {0:N0}' -f $totalRejected)
        Log-Report ("    Finalization rate:        {0}%" -f $finRate)
        Log-Report ''
        Log-Report '  TIMING:'
        Log-Report ('    Wall-clock total:         {0:N1}s ({1:N1} min)' -f $wallElapsed, ($wallElapsed / 60))
        Log-Report ('    Avg per shard (wall):    {0}s' -f ([math]::Round($wallElapsed / $NUM_SHARDS, 2)))
        if ($minTime -lt [double]::MaxValue) { Log-Report ('    Min shard time:           {0:N2}s' -f $minTime) }
        Log-Report ('    Max shard time:           {0:N2}s' -f $maxTime)
        Log-Report ''
        Log-Report '  +=============================================================+'
        Log-Report '  |                    TPS RESULTS                                |'
        Log-Report '  +=============================================================+'
        Log-Report ('  | Avg TPS / shard:               {0,12:N0} TPS                  |' -f $avgTps)
        Log-Report ('  | Sum independent TPS ({0}x):       {1,12:N0} TPS                  |' -f $goodShards, $sumTps)
        Log-Report '  |                                                             |'
        Log-Report ('  | AGGREGATE TPS (wall-clock):     {0,12:N0} TPS                  |' -f $aggTpsWall)
        Log-Report '  |                                                             |'
        Log-Report ('  |   ({0} shards on {1}+ cores simultaneous)' -f $NUM_SHARDS, $coreCount)
        Log-Report '  |                                                             |'
        Log-Report ('  | Scaling factor:                 {0,12:N0} x                    |' -f $NUM_SHARDS)
        Log-Report ('  | Scaling efficiency:             {0,12:N1}%                    |' -f $scalingEff)
        Log-Report '  +=============================================================+'
        Log-Report ''
        Log-Report '  EXTRAPOLATION to whitepaper (333 shards, 8 nodes/shard):' -ForegroundColor Magenta
        Log-Report ('    This bench (1 shard):    ~{0:N0} TPS' -f $avgTps)
        Log-Report ('    This bench ({0} shards):  ~{1:N0} TPS' -f $goodShards, ([long]$avgTps * $goodShards))
        Log-Report ('    Projected 333 shards:    ~{0:N0} TPS (v4.3-EXT optimal)' -f $tps333Full)
        Log-Report ''
        if ($PERCENT -eq 0) {
            Log-Report '  MODE: CLEAN (0% attackers)' -Color Green
        } else {
            Log-Report ('  SECURITY (37 attacker types T0-T36, {0}% attackers):' -f $PERCENT) -Color Green
            if ($dsPct -ge 0) {
                Log-Report ('    Double-spend blocked:       {0}/{1} ({2}%)' -f $totalDSBlocked, $totalDSTotal, $dsPct) -Color Green
            } else {
                Log-Report '    Double-spend blocked:       N/A (not found in logs)' -Color DarkGray
            }
            if ($theftPct -ge 0) {
                Log-Report ('    Theft blocked:              {0}/{1} ({2}%)' -f $totalTheftBlocked, $totalTheftTotal, $theftPct) -Color Green
            } else {
                Log-Report '    Theft blocked:              N/A (not found in logs)' -Color DarkGray
            }
            if ($avgFPR -ge 0) {
                Log-Report ('    Honest FPR:                {0}%' -f $avgFPR) -Color Green
            } else {
                Log-Report '    Honest FPR:                N/A' -Color DarkGray
            }
            if ($avgABR -ge 0) {
                Log-Report ('    ABR:                       {0}%' -f $avgABR) -Color Green
            } else {
                Log-Report '    ABR:                       N/A' -Color DarkGray
            }
        }
        Log-Report ("  Shard logs: {0}" -f $LogDir) -Color DarkGray
        Log-Report '============================================================'

        $atkLabel = if ($PERCENT -eq 0) { 'clean' } else { ('atk{0}' -f $PERCENT) }
        $reportFile = Join-Path $reportDir ('TPS-v4.3ext-{0}s-{1}n-{2}-{3}.txt' -f $NUM_SHARDS, $NODES, $atkLabel, (Get-Date -Format 'yyyyMMdd-HHmmss'))
        $allReportLines | Set-Content -Path $reportFile -Encoding UTF8
        Write-Host ('  REPORT SAVED: {0}' -f $reportFile) -ForegroundColor Green

        # ---- HISTORY ----
        $allReports = Get-ChildItem (Join-Path $reportDir 'TPS-*.txt') | Sort-Object Name
        if ($allReports.Count -gt 0) {
            Log-Report ''
            Log-Report '  TEST HISTORY:' -Color Magenta
            Log-Report '  +------+-------+------+-------+-------+--------+--------+------------------+'
            Log-Report '  | Shard| Nodes | Atk% |  TPS  | Wall  |  Agg   | Date                |'
            Log-Report '  +------+-------+------+-------+-------+--------+--------+------------------+'
            foreach ($rp in $allReports) {
                $rc = Get-Content $rp.FullName -Raw
                $rS = '?'; if ($rc -match '(\d+)\s+SHARDS') { $rS = $Matches[1] }
                $rN = '?'; if ($rc -match '(\d+)\s+NODES/SHARD') { $rN = $Matches[1] }
                $rA = '?'; if ($rc -match 'Attackers:\s+(\d+)%') { $rA = $Matches[1] }
                # --- TPS (try multiple patterns for locale/format robustness) ---
                $rT = '?'
                if ($rc -match 'Avg TPS / shard:\s*([\d,]+)\s*TPS') { $rT = $Matches[1] }
                elseif ($rc -match 'Avg TPS / shard:\s*(\d+)\s*TPS') { $rT = $Matches[1] }
                elseif ($rc -match 'Avg TPS.*?([\d,]+)\s*TPS') { $rT = $Matches[1] }
                # --- Wall-clock ---
                $rW = '?'
                if ($rc -match 'Wall-clock total:\s*([\d\.]+)\s*s') { $rW = $Matches[1] + 's' }
                elseif ($rc -match 'Wall.?clock.*?([\d\.]+)\s*s') { $rW = $Matches[1] + 's' }
                # --- Aggregate TPS ---
                $rAg = '?'
                if ($rc -match 'AGGREGATE TPS \(wall-clock\):\s*([\d,]+)\s*TPS') { $rAg = $Matches[1] }
                elseif ($rc -match 'AGGREGATE TPS \(wall-clock\):\s*(\d+)\s*TPS') { $rAg = $Matches[1] }
                elseif ($rc -match 'AGGREGATE TPS.*?wall.*?([\d,]+)\s*TPS') { $rAg = $Matches[1] }
                $rD = $rp.BaseName -replace 'TPS-','' -replace '-',' '
                $rl = '  | {0,-4} | {1,-5} | {2,-4} | {3,-5} | {4,-6} | {5,-6} | {6,-16} |' -f $rS, $rN, $rA, $rT, $rW, $rAg, $rD
                Log-Report $rl
                # Diagnostic: if TPS/Wall/Agg all failed, show snippet from report
                if ($rT -eq '?' -and $rW -eq '?' -and $rAg -eq '?') {
                    Write-Host '  [DIAG-HISTORY] Regex did not match TPS/Wall/Agg. Snippet from report:' -ForegroundColor Yellow
                    $snip = ($rc -split "`n" | Where-Object { $_ -match 'TPS|Wall|AGGREGATE|shard' } | Select-Object -First 5)
                    foreach ($sl in $snip) { Write-Host ("    {0}" -f $sl.Trim()) -ForegroundColor DarkYellow }
                }
            }
            Log-Report '  +------+-------+------+-------+-------+--------+--------+------------------+'
        }
    } catch {
        Write-Host ''
        Write-Host ("ERROR: {0}" -f $_.Exception.Message) -ForegroundColor Red
        Write-Host ("Stack: {0}" -f $_.ScriptStackTrace) -ForegroundColor Red
    }

    # ---- TEST DONE ----
    Write-Host ''
    Write-Host '  -----------------------------------------------------------' -ForegroundColor DarkGray
    Write-Host '  Test complete. Menu reappears below.' -ForegroundColor DarkGray
    Write-Host '  -----------------------------------------------------------' -ForegroundColor DarkGray
    Start-Sleep -Seconds 1
} # end while ($true)



