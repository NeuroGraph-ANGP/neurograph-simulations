# ==========================================================================
# NeuroGraph ANGP v4.3-EXT — INTERACTIVE MULTI-SHARD TPS BENCHMARK
# ==========================================================================
# Menu: clean (0% atk) or with attackers (10-90%).
# Config v4.3-EXT: 333 shards x 8 nodes/shard = 2664 nodes (optimal).
# Results saved automatically to benchmark-reports/.
# Optimized batch processing with RAYON_NUM_THREADS=2 per shard.
#
# v4.3-EXT-patched (2026-08-15):
#   [FIX 1] "Scaling factor" - now computed as aggTpsWall/avgTps (was hardcoded N).
#   [FIX 2] "Avg per shard (wall)" - now real arithmetic mean of per-shard Total
#           time parsed from shard logs (was wallTime/N, contradicting min/max).
#   [FIX 3] "Rejected" - split into "Honest tx rejected" + "Total attacks blocked"
#           (DS + theft rejections were silently excluded before).
#   [FIX 4] Extrapolation - separated into Aggregate (theoretical, linear)
#           and Wall-clock (hardware-limited, must be measured).
#           Redundant block hidden when NUM_SHARDS >= 333.
#   [FIX 8] Parallel efficiency formula fixed (was misleading, >100% values).
#           Now: ideal_batch_wall / actual_wall_time * 100 (always <= 100%).
#   [FIX 5] Added per-shard timing collection (sumShardTime, mean, stddev).
#   [FIX 6] Clarified fee explanation: tf includes system reward txs (0.1% fee
#           per batch becomes a Transaction in ledger, see ledger.add_batch).
#
# v4.3-EXT — 37 attacker types (T0-T36) (behavioral strategies):
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
# ==========================================================================

$ErrorActionPreference = 'Continue'
chcp 65001 > $null 2>&1
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# ===================== PRE-BUILD =====================
$originalPath = Get-Location

$ProjectDir = (Get-Location).Path
if (-not (Test-Path "$ProjectDir\Cargo.toml")) { $ProjectDir = $PSScriptRoot }
if (-not (Test-Path "$ProjectDir\Cargo.toml")) {
    $dir = (Get-Location).Path
    for ($k = 0; $k -lt 5; $k++) {
        if (Test-Path "$dir\Cargo.toml") { $ProjectDir = $dir; break }
        $parent = Split-Path $dir -Parent
        if ($parent -eq $dir) { break }
        $dir = $parent
    }
}
if (-not (Test-Path "$ProjectDir\Cargo.toml")) { $ProjectDir = 'D:\neurograph_v4.3.1-FIXED' }
if (-not (Test-Path "$ProjectDir\Cargo.toml")) {
    Write-Host '  CRITICAL ERROR: Cargo.toml not found!' -ForegroundColor Red
    Write-Host '  Run this script FROM the project folder (where Cargo.toml is located)' -ForegroundColor Yellow
    Read-Host 'Press ENTER'; exit 1
}
Set-Location $ProjectDir

$isWindows = $true
$isLinux = $false
$isMacOS = $false
if ($PSVersionTable.PSVersion.Major -ge 6) {
    # PowerShell 7+ provides $IsLinux, $IsMacOS, $IsWindows automatically
    $isWindows = $IsWindows
    $isLinux = $IsLinux
    $isMacOS = $IsMacOS
}
$exeExt = if ($isWindows) { '.exe' } else { '' }
$sep = if ($isWindows) { '\' } else { '/' }

# Cross-platform CPU core detection (Windows / Linux / macOS / GitHub Actions runners)
$coreCount = $null
$osName = if ($isWindows) { 'Windows' } elseif ($isMacOS) { 'macOS' } else { 'Linux' }

if ($isWindows) {
    # Windows: query WMI/CIM for physical cores (sums across all sockets)
    try {
        $cpuInfo = Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue
        if ($cpuInfo) {
            $coreCount = ($cpuInfo | Measure-Object -Property NumberOfCores -Sum).Sum
        }
    } catch {}
    if (-not $coreCount) { $coreCount = $env:NUMBER_OF_PROCESSORS }
} elseif ($isMacOS) {
    # macOS: sysctl hw.physicalcpu (physical cores) or hw.logicalcpu (with HT)
    try {
        $sysctlOut = & sysctl -n hw.physicalcpu 2>$null
        if ($sysctlOut -and $sysctlOut -match '^\d+$') {
            $coreCount = [int]$sysctlOut.Trim()
        }
    } catch {}
    if (-not $coreCount) {
        try {
            $sysctlOut = & sysctl -n hw.logicalcpu 2>$null
            if ($sysctlOut -and $sysctlOut -match '^\d+$') {
                $coreCount = [int]$sysctlOut.Trim()
            }
        } catch {}
    }
} else {
    # Linux: try nproc first (works on most distros + GitHub Actions runners)
    try {
        $nprocOut = & nproc 2>$null
        if ($nprocOut -and $nprocOut -match '^\d+$') {
            $coreCount = [int]$nprocOut.Trim()
        }
    } catch {}
    # Fallback 1: parse /proc/cpuinfo (count "processor" entries)
    if (-not $coreCount -and (Test-Path '/proc/cpuinfo')) {
        try {
            $cpuInfoContent = Get-Content '/proc/cpuinfo' -ErrorAction SilentlyContinue
            if ($cpuInfoContent) {
                $coreCount = ($cpuInfoContent | Where-Object { $_ -match '^processor\s*:' }).Count
            }
        } catch {}
    }
    # Fallback 2: lscpu (preferred on modern Linux)
    if (-not $coreCount) {
        try {
            $lscpuOut = & lscpu -p=CPU 2>$null
            if ($lscpuOut) {
                $cpuLines = $lscpuOut | Where-Object { $_ -match '^\d+' }
                if ($cpuLines) { $coreCount = $cpuLines.Count }
            }
        } catch {}
    }
    # Fallback 3: NUMBER_OF_PROCESSORS env (some CI runners set it)
    if (-not $coreCount) { $coreCount = $env:NUMBER_OF_PROCESSORS }
}

if (-not $coreCount) { $coreCount = '?' }

Write-Host ''
Write-Host '=============================================================' -ForegroundColor Cyan
Write-Host '  NeuroGraph ANGP v4.3.1-FIXED — BUILD' -ForegroundColor Cyan
Write-Host '=============================================================' -ForegroundColor Cyan
Write-Host ''
$buildOutput = cargo build --release --example sim_stress_v43ext 2>&1
$buildExit = $LASTEXITCODE
$buildOutput | Add-Content -Path (Join-Path $ProjectDir 'benchmark-build.log')
if ($buildExit -ne 0) {
    Write-Host '  Build FAILED!' -ForegroundColor Red
    $buildOutput | Where-Object { $_ -match 'error' } | ForEach-Object { Write-Host "  $_" }
    Read-Host 'Press ENTER'; exit 1
}
$simBinary = Join-Path $ProjectDir ("target{0}release{0}examples{0}sim_stress_v43ext{1}" -f $sep, $exeExt)
Write-Host '  Build OK!' -ForegroundColor Green
Write-Host ''
# ===================== PRESETS =====================
$presets = @{
    # --- CLEAN (0% attackers) ---
    '1'  = @{ Shards=333; Nodes=8;  Percent=0  }
    '2'  = @{ Shards=100; Nodes=8;  Percent=0  }
    '3'  = @{ Shards=200; Nodes=8;  Percent=0  }
    '4'  = @{ Shards=444; Nodes=8;  Percent=0  }
    '5'  = @{ Shards=222; Nodes=8;  Percent=0  }
    # --- WITH ATTACKERS ---
    '6'  = @{ Shards=333; Nodes=8;  Percent=10 }
    '7'  = @{ Shards=333; Nodes=8;  Percent=30 }
    '8'  = @{ Shards=333; Nodes=8;  Percent=50 }
    '9'  = @{ Shards=100; Nodes=8;  Percent=10 }
    '10' = @{ Shards=200; Nodes=8; Percent=10 }
}

$reportDir = Join-Path $ProjectDir 'benchmark-reports'
if (-not (Test-Path $reportDir)) { New-Item -ItemType Directory -Path $reportDir | Out-Null }

# ===================== ATTACKER TYPES LIST =====================
# Each entry: Id, Name, Strategy, Category, Difficulty
# Full table displayed when user selects menu option [99]
$attackerTypes = @(
    @{ Id='T0'; Name='Random-Noise'; Strategy='Uniform (-4, +4) perturbation'; Category='Disruption'; Difficulty='Low' },
    @{ Id='T1'; Name='Mimicry-300'; Strategy='300 mimicry steps, then noise (sigma=0.8)'; Category='Evasion'; Difficulty='Medium' },
    @{ Id='T2'; Name='Mimicry-500'; Strategy='500 honest steps, then noise (sigma=1.2)'; Category='Evasion'; Difficulty='Medium' },
    @{ Id='T3'; Name='Adaptive-Rep-Aware'; Strategy='40% attack / 5% recovery ratio'; Category='Adaptive'; Difficulty='High' },
    @{ Id='T4'; Name='Coordinated-Bias'; Strategy='All give same bias +0.25'; Category='Coordination'; Difficulty='Medium' },
    @{ Id='T5'; Name='Gaussian'; Strategy='Gaussian noise N(0, 2.0)'; Category='Disruption'; Difficulty='Low' },
    @{ Id='T6'; Name='FlipFlop'; Strategy='100 honest / 100 attack cycles'; Category='Oscillation'; Difficulty='Medium' },
    @{ Id='T7'; Name='Sleeper'; Strategy='2000 honest steps, then drift'; Category='Stealth'; Difficulty='High' },
    @{ Id='T8'; Name='Progressive-Drift'; Strategy='+0.0002/step degradation'; Category='Slow Attack'; Difficulty='Very High' },
    @{ Id='T9'; Name='Outlier-Burst'; Strategy='95% honest, 5% outlier +/-5'; Category='Burst'; Difficulty='Medium' },
    @{ Id='T10'; Name='Clone-Copy'; Strategy='Copy honest prediction + micro-noise'; Category='Impersonation'; Difficulty='Medium' },
    @{ Id='T11'; Name='Byzantine'; Strategy='Per-dimension random chaos'; Category='Byzantine'; Difficulty='Low' },
    @{ Id='T12'; Name='Sybil-Cluster'; Strategy='5 identities, coordinated bias 0.03'; Category='Sybil'; Difficulty='High' },
    @{ Id='T13'; Name='Rep-Farmer'; Strategy='Farm reputation for 5K steps, then attack'; Category='Exploitation'; Difficulty='Very High' },
    @{ Id='T14'; Name='Oscillating-Drift'; Strategy='Sinusoidal drift pattern'; Category='Oscillation'; Difficulty='High' },
    @{ Id='T15'; Name='Colluding-Committee'; Strategy='20 nodes coordinate together'; Category='Coordination'; Difficulty='High' },
    @{ Id='T16'; Name='Slow-Poison'; Strategy='99.9% valid, 0.1% wrong predictions'; Category='Subversion'; Difficulty='Very High' },
    @{ Id='T17'; Name='Eclipse'; Strategy='Control victim''s neighbors'; Category='Topology'; Difficulty='Extreme' },
    @{ Id='T18'; Name='Maj-Ref-Manip'; Strategy='60% same bias +0.01'; Category='Manipulation'; Difficulty='Very High' },
    @{ Id='T19'; Name='Sybil-Replace'; Strategy='Eliminated -> new identity, reputation reset'; Category='Sybil'; Difficulty='Extreme' },
    @{ Id='T20'; Name='Patient-Byz'; Strategy='5000 perfect honest steps, then full attack'; Category='Stealth'; Difficulty='Extreme' },
    @{ Id='T21'; Name='Threshold-Gamer'; Strategy='Stay below all detection thresholds'; Category='Evasion'; Difficulty='Extreme' },
    @{ Id='T22'; Name='True-Fdbk-Adaptive'; Strategy='Observe own reputation, self-adjust'; Category='Adaptive'; Difficulty='Extreme' },
    @{ Id='T23'; Name='Rep-Gradient'; Strategy='Learn reputation function via probing'; Category='Modeling'; Difficulty='Extreme' },
    @{ Id='T24'; Name='Detector-Mimicry'; Strategy='Mimic honest mean/variance/model'; Category='Evasion'; Difficulty='Extreme' },
    @{ Id='T25'; Name='Distrib-Influence'; Strategy='100 nodes x small bias, collective push'; Category='Coordination'; Difficulty='Very High' },
    @{ Id='T26'; Name='Anti-Coordination'; Strategy='Same goal, different predictions'; Category='Evasion'; Difficulty='Very High' },
    @{ Id='T27'; Name='Rep-Camouflage'; Strategy='Excellent/attack cycles, aggregate management'; Category='Oscillation'; Difficulty='Extreme' },
    @{ Id='T28'; Name='Long-Poison'; Strategy='0.1% wrong over 5K/6K/7K steps'; Category='Subversion'; Difficulty='Extreme' },
    @{ Id='T29'; Name='Honest-Mal-Switch'; Strategy='Random mode switches, no periodic pattern'; Category='Unpredictable'; Difficulty='Extreme' },
    @{ Id='T30'; Name='Thr-Boundary'; Strategy='Live at threshold -eps, dynamic eps'; Category='Evasion'; Difficulty='Extreme' },
    @{ Id='T31'; Name='Recovery-Exploit'; Strategy='Attack -> recover -> attack cycles'; Category='Exploitation'; Difficulty='Extreme' },
    @{ Id='T32'; Name='Sybil-Cycling'; Strategy='Cycle through identities, transfer behavior'; Category='Sybil'; Difficulty='Extreme' },
    @{ Id='T33'; Name='Collud-Honest-Maj'; Strategy='30% attack: 10% aggressive + 20% camouflage'; Category='Coordination'; Difficulty='Extreme' },
    @{ Id='T34'; Name='Consensus-Targeted'; Strategy='Optimize (C_attack - C_honest)'; Category='Manipulation'; Difficulty='Extreme' },
    @{ Id='T35'; Name='Multi-Vector (BOSS)'; Strategy='Dynamically select best strategy'; Category='Adaptive'; Difficulty='Extreme' },
    @{ Id='T36'; Name='Worst-Case-Coordinated'; Strategy='Perfect coordination, diverse predictions'; Category='Coordination'; Difficulty='Extreme' }
)
# ===================== MAIN MENU (LOOP) =====================

while ($true) {

    Write-Host ''
    Write-Host '=============================================================' -ForegroundColor Cyan
    Write-Host '  NeuroGraph ANGP v4.3-EXT — MULTI-SHARD TPS BENCHMARK' -ForegroundColor Cyan
    Write-Host '  333 shards x 8 nodes/shard = 2664 nodes (optimal config)' -ForegroundColor Gray
    Write-Host '  37 attacker types (T0-T36) | Behavioral Strategies' -ForegroundColor Gray
    Write-Host '=============================================================' -ForegroundColor Cyan
    Write-Host ''
    Write-Host '  CLEAN (no attackers, 0%)' -ForegroundColor Green
    Write-Host '    [1]  333 shards x 8 nodes/shard   (2664 total) — OPTIM v4.3-EXT' -ForegroundColor White
    Write-Host '    [2]  100 shards x 8 nodes/shard   (800 total)' -ForegroundColor White
    Write-Host '    [3]  200 shards x 8 nodes/shard   (1600 total)' -ForegroundColor White
    Write-Host '    [4]  444 shards x 8 nodes/shard   (3552 total)' -ForegroundColor White
    Write-Host '    [5]  222 shards x 8 nodes/shard   (1776 total)' -ForegroundColor White
    Write-Host ''
    Write-Host '  WITH ATTACKERS (37 attacker types T0-T36)' -ForegroundColor Red
    Write-Host '    [6]  333 shards x 8 nodes/shard   (2664 total, 10% atk)' -ForegroundColor White
    Write-Host '    [7]  333 shards x 8 nodes/shard   (2664 total, 30% atk)' -ForegroundColor White
    Write-Host '    [8]  333 shards x 8 nodes/shard   (2664 total, 50% atk)' -ForegroundColor White
    Write-Host '    [9]  100 shards x 8 nodes/shard   (800 total, 10% atk)' -ForegroundColor White
    Write-Host '   [10]  200 shards x 8 nodes/shard  (1600 total, 10% atk)' -ForegroundColor White
    Write-Host ''
    Write-Host '    [11] Custom (manual configuration)' -ForegroundColor Yellow
    Write-Host '   [99] List all 37 attacker types (T0-T36)' -ForegroundColor DarkCyan
    Write-Host '    [0]  Exit' -ForegroundColor DarkGray
    Write-Host ''
    $choice = Read-Host '  Choice'

    # ---- EXIT ----
    if ($choice -eq '0') {
        Write-Host ''
        Write-Host '  Goodbye!' -ForegroundColor Cyan
        Set-Location $originalPath
        exit 0
    }
    # ---- ATTACKER LIST (full table) ----
    if ($choice -eq '99') {
        Write-Host ''
        Write-Host '  ============================================================================================' -ForegroundColor Cyan
        Write-Host '  NeuroGraph ANGP v4.3-EXT  -  37 ATTACKER TYPES (T0-T36)  -  BEHAVIORAL STRATEGIES' -ForegroundColor Cyan
        Write-Host '  ============================================================================================' -ForegroundColor Cyan
        Write-Host ''
        Write-Host '  Categories: Disruption | Evasion | Adaptive | Coordination | Oscillation | Stealth' -ForegroundColor Gray
        Write-Host '              Slow Attack | Burst | Impersonation | Byzantine | Sybil | Exploitation' -ForegroundColor Gray
        Write-Host '              Subversion | Topology | Manipulation | Modeling | Unpredictable' -ForegroundColor Gray
        Write-Host ''
        Write-Host '  Difficulty: Low (green) | Medium (cyan) | High (yellow) | Very High (dark yellow) | Extreme (red)' -ForegroundColor Gray
        Write-Host ''
        Write-Host ('  {0,-5} {1,-23} {2,-45} {3,-15} {4}' -f 'ID', 'Name', 'Strategy', 'Category', 'Difficulty') -ForegroundColor White
        Write-Host ('  {0,-5} {1,-23} {2,-45} {3,-15} {4}' -f '-----', '-----------------------', '---------------------------------------------', '---------------', '----------') -ForegroundColor DarkGray
        foreach ($at in $attackerTypes) {
            $dc = switch ($at.Difficulty) {
                'Low' { 'Green' }
                'Medium' { 'Cyan' }
                'High' { 'Yellow' }
                'Very High' { 'DarkYellow' }
                'Extreme' { 'Red' }
                default { 'White' }
            }
            $line = '  {0,-5} {1,-23} {2,-45} {3,-15} {4}' -f $at.Id, $at.Name, $at.Strategy, $at.Category, $at.Difficulty
            Write-Host $line -ForegroundColor $dc
        }
        Write-Host ''
        Write-Host ('  Total: {0} attacker types (T0-T36)' -f $attackerTypes.Count) -ForegroundColor Green
        Write-Host ''
        Write-Host '  NOTE: In benchmark, attackers are distributed proportionally across all shards.' -ForegroundColor Gray
        Write-Host '        Each shard gets a random subset of these 37 types based on the percentage chosen.' -ForegroundColor Gray
        Write-Host '        The reputation engine must detect and eliminate/gate all 37 types.' -ForegroundColor Gray
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
        $NUM_SHARDS = $p.Shards; $NODES = $p.Nodes; $PERCENT = $p.Percent; $STEPS = 10000
    }
    else {
        Write-Host '  Invalid choice.' -ForegroundColor Red
        Start-Sleep -Seconds 1; continue
    }

    # ===================== RUN TEST =====================

    $BATCH_SIZE = 4

    $SHARD_IPS = @()
    for ($idx = 0; $idx -lt $NUM_SHARDS; $idx++) {
        $oct3 = [math]::Floor($idx / 254) + 1
        $oct4 = ($idx % 254) + 1
        $port = 8100 + $idx
        $SHARD_IPS += ('10.0.{0}.{1}:{2}' -f $oct3, $oct4, $port)
    }

    $allReportLines = @()

    function Log-Report($txt, [string]$Color) {
        if ($Color) {
            Write-Host $txt -ForegroundColor $Color
        } else {
            Write-Host $txt
        }
        $script:allReportLines += $txt
    }

    try {
        $batchCount = [math]::Ceiling($NUM_SHARDS / $BATCH_SIZE)
        $totalNodes = $NUM_SHARDS * $NODES
        $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'

        Log-Report ''
        Log-Report '============================================================'
        $hdr = '  NeuroGraph ANGP v4.3-EXT  -  {0} SHARDS x {1} NODES/SHARD  |  {2} total nodes  |  {3}% attackers' -f $NUM_SHARDS, $NODES, $totalNodes, $PERCENT
        Log-Report $hdr
        Log-Report ('  Date: {0}' -f $timestamp)
        Log-Report '  37 attacker types (T0-T36): T0-T15 (16 base) + T16-T21 (6 ext1) + T22-T36 (15 ext2)' -ForegroundColor Gray
        Log-Report '============================================================'

        $LogDir = Join-Path $ProjectDir ('shard-logs-{0}s-{1}n-{2}atk' -f $NUM_SHARDS, $NODES, $PERCENT)
        if (-not (Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir | Out-Null }
        Remove-Item (Join-Path $LogDir 'shard_*.log') -Force -ErrorAction SilentlyContinue
        Remove-Item (Join-Path $LogDir '*.tmp') -Force -ErrorAction SilentlyContinue
        Remove-Item (Join-Path $LogDir '*.bat') -Force -ErrorAction SilentlyContinue

        Log-Report ''
        Log-Report '  CONFIG:'
        Log-Report ("    Shards:                   {0}" -f $NUM_SHARDS)
        Log-Report ("    Nodes per shard:          {0}" -f $NODES)
        Log-Report ("    Total nodes:              {0}" -f $totalNodes)
        Log-Report ("    Batch size (parallel):    {0}" -f $BATCH_SIZE)
        Log-Report ("    Batches total:            {0}" -f $batchCount)
        Log-Report ("    Steps:                    {0}" -f $STEPS)
        Log-Report ("    Attackers:                {0}% (37 attacker types: T0-T36)" -f $PERCENT)
        Log-Report '    RAYON_NUM_THREADS:        2 per shard'
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
                $jobs += @{ Id=$i; Process=$proc; LogFile=$logFile; TmpOut=$tmpOut; TmpErr=$tmpErr; BatFile=$batFile }
            }

            foreach ($job in $jobs) {
                $sid = $job.Id; $proc = $job.Process
                $sw = [System.Diagnostics.Stopwatch]::StartNew()
                while (-not $proc.HasExited) {
                    if ($sw.Elapsed.TotalSeconds -ge 5) {
                        $sec = [math]::Floor($sw.Elapsed.TotalSeconds)
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
                Remove-Item $job.BatFile -Force -ErrorAction SilentlyContinue
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
        # v4.3-EXT-patched FIX 2/5: per-shard time collection for real mean/stddev
        $sumShardTime = 0.0; $sumSqShardTime = 0.0; $shardTimeCount = 0
        $shardTimes = @()
        # v4.3-EXT-patched FIX 7: per-shard TPS min/max for bottleneck identification
        $minShardTps = [long]::MaxValue; $maxShardTps = 0
        $minShardTpsId = -1; $maxShardTpsId = -1
        $allShardTps = @()
        # v4.3-EXT-patched FIX 3: also parse DS/Theft attempts+blocked separately
        # so we can show "attacks blocked" alongside "honest tx rejected"
        $totalDSAttempts = 0; $totalTheftAttempts = 0

        # Security metric accumulators
        $sumFPR = 0.0; $fprCount = 0
        $sumABR = 0.0; $abrCount = 0
        $totalDSBlocked = 0; $totalDSTotal = 0; $dsCount = 0
        $totalTheftBlocked = 0; $totalTheftTotal = 0; $theftCount = 0

        for ($i = 0; $i -lt $NUM_SHARDS; $i++) {
            $logFile = Join-Path $LogDir ("shard_{0}.log" -f $i)
            if (-not (Test-Path $logFile)) { $failedShards++; continue }
            $content = Get-Content $logFile -Raw
            $tps = 0; if ($content -match 'Overall TPS:\s+([0-9\.]+)') { $tps = [long]$Matches[1] }
            $finalized = 0; if ($content -match 'Finalized:\s+([0-9]+)') { $finalized = [long]$Matches[1] }
            $generated = 0; if ($content -match 'Generated:\s+([0-9]+)') { $generated = [long]$Matches[1] }
            $rejected = 0; if ($content -match 'Rejected:\s+([0-9]+)') { $rejected = [long]$Matches[1] }
            $totalTime = 0.0; if ($content -match 'Total time:\s+([0-9\.]+)s') { $totalTime = [double]$Matches[1] }
            if ($tps -eq 0 -and $finalized -eq 0) { $failedShards++; continue }
            $totalFinalized += $finalized; $totalGenerated += $generated; $totalRejected += $rejected; $sumTps += $tps
            if ($totalTime -gt $maxTime) { $maxTime = $totalTime }
            if ($totalTime -lt $minTime) { $minTime = $totalTime }
            # v4.3-EXT-patched FIX 5: collect per-shard time for real mean
            if ($totalTime -gt 0) {
                $sumShardTime += $totalTime
                $sumSqShardTime += ($totalTime * $totalTime)
                $shardTimeCount++
                $shardTimes += $totalTime
            }
            # v4.3-EXT-patched FIX 7: track min/max per-shard TPS + bottleneck ID
            if ($tps -gt 0) {
                $allShardTps += [pscustomobject]@{ Id=$i; Tps=$tps; Time=$totalTime }
                if ($tps -lt $minShardTps) { $minShardTps = $tps; $minShardTpsId = $i }
                if ($tps -gt $maxShardTps) { $maxShardTps = $tps; $maxShardTpsId = $i }
            }

            # Parse security metrics from each shard log
            if ($content -match 'False Positive Rate \(FPR\): ([0-9\.]+)%') {
                $sumFPR += [double]$Matches[1]; $fprCount++
            }
            if ($content -match 'Attack Blocking Rate \(ABR\): ([0-9\.]+)%') {
                $sumABR += [double]$Matches[1]; $abrCount++
            }
            if ($content -match 'Double-spend blocked: (\d+)/(\d+)') {
                $totalDSBlocked += [long]$Matches[1]; $totalDSTotal += [long]$Matches[2]; $dsCount++
            }
            if ($content -match 'Theft blocked: (\d+)/(\d+)') {
                $totalTheftBlocked += [long]$Matches[1]; $totalTheftTotal += [long]$Matches[2]; $theftCount++
            }
        }

        # v4.3-EXT-patched FIX 3: total attack attempts + blocked
        $totalDSAttempts = $totalDSTotal
        $totalTheftAttempts = $totalTheftTotal
        $totalAttacksBlocked = $totalDSBlocked + $totalTheftBlocked
        $totalAttacksAttempted = $totalDSAttempts + $totalTheftAttempts

        # Compute averaged security metrics
        $avgFPR = if ($fprCount -gt 0) { [math]::Round($sumFPR / $fprCount, 4) } else { -1 }
        $avgABR = if ($abrCount -gt 0) { [math]::Round($sumABR / $abrCount, 2) } else { -1 }
        # v4.3.1 FIX: When total=0, show 100% (clean run / all blocked), not N/A
        $dsPct = if ($totalDSTotal -gt 0) { [math]::Round($totalDSBlocked * 100.0 / $totalDSTotal, 2) } elseif ($dsCount -gt 0) { 100.0 } else { -1 }
        $theftPct = if ($totalTheftTotal -gt 0) { [math]::Round($totalTheftBlocked * 100.0 / $totalTheftTotal, 2) } elseif ($theftCount -gt 0) { 100.0 } else { -1 }

        $goodShards = $NUM_SHARDS - $failedShards
        Log-Report ("  Shards succeeded: {0} / {1}" -f $goodShards, $NUM_SHARDS)
        if ($failedShards -gt 0) { Log-Report ("  Shards failed:   {0}" -f $failedShards) }
        Log-Report ''

        if ($goodShards -gt 0) { $avgTps = [math]::Round($sumTps / $goodShards) } else { $avgTps = 0 }
        if ($wallElapsed -gt 0) { $aggTpsWall = [math]::Round($totalFinalized / $wallElapsed) } else { $aggTpsWall = 0 }
        # v4.3-EXT-patched FIX 2: real mean of per-shard time (was wallElapsed/N)
        if ($shardTimeCount -gt 0) {
            $meanShardTime = $sumShardTime / $shardTimeCount
            $varShardTime  = ($sumSqShardTime / $shardTimeCount) - ($meanShardTime * $meanShardTime)
            if ($varShardTime -lt 0) { $varShardTime = 0 }
            $stddevShardTime = [math]::Sqrt($varShardTime)
        } else { $meanShardTime = 0; $stddevShardTime = 0 }
        # v4.3-EXT-patched FIX 1: real scaling factor (was hardcoded N)
        if ($avgTps -gt 0) { $scalingFactorReal = [math]::Round($aggTpsWall / $avgTps, 2) } else { $scalingFactorReal = 0 }
        # v4.3-EXT-patched FIX 8: batch parallel efficiency (corrected formula)
        # OLD formula (mean*N/wallElapsed) gave values >100% (misleading).
        # NEW: ideal_batch_wall = meanShardTime * ceil(N/BATCH_SIZE)
        #      batchParEff = ideal_batch / actual * 100  (always <= 100%)
        # Note: this is NOT "sequential" time. It's the idealized time if each
        # batch of BATCH_SIZE shards ran perfectly parallel, with zero overhead
        # between batches. The gap to wallElapsed = scheduling/IO overhead.
        $batchCountRan = [math]::Ceiling($goodShards / $BATCH_SIZE)
        if ($wallElapsed -gt 0 -and $meanShardTime -gt 0) {
            $idealBatchWall = $meanShardTime * $batchCountRan
            $batchParEff = [math]::Round($idealBatchWall / $wallElapsed * 100, 1)
        } else { $batchParEff = 0 }
        # v4.3-EXT-patched FIX 7: per-shard TPS distribution + bottleneck
        if ($minShardTps -eq [long]::MaxValue) { $minShardTps = 0 }
        if ($maxShardTps -gt 0 -and $minShardTps -gt 0) {
            $tpsImbalance = [math]::Round(($maxShardTps - $minShardTps) * 100.0 / $maxShardTps, 2)
        } else { $tpsImbalance = 0 }
        # v4.3-EXT-patched FIX 4 (final): extrapolation is now CONDITIONAL.
        # When NUM_SHARDS >= 333 the entire EXTRAPOLATION block is hidden
        # (projecting to 333 when already at 333 is redundant).
        # When NUM_SHARDS < 333 we show only the meaningful projection
        # (Aggregate, ideal linear) and explicitly mark Wall-clock as
        # "MUST BE MEASURED" (cannot be extrapolated from smaller N).
        #
        # Definitions (per whitepaper):
        #   tps/shard     = per-shard throughput (tx_processed_by_shard / shard_time)
        #   tps/aggregate = SUM of per-shard TPS  = N x tps/shard (THEORETICAL CAPACITY)
        #   tps/agg       = Wall-clock TPS = total_tx / real_wall_time (HARDWARE-LIMITED)
        $tps333Ideal = [math]::Round($avgTps * 333.0)
        # Aggregate capacity at current N (sum of independent shards)
        $aggTpsCurrentN = [long]$avgTps * $goodShards
        # Wall-clock efficiency observed at current N (for reference, NOT for extrapolation)
        if ($aggTpsCurrentN -gt 0) {
            $wallEffPct = [math]::Round($aggTpsWall * 100.0 / $aggTpsCurrentN, 2)
        } else { $wallEffPct = 0 }
        if ($totalGenerated -gt 0) { $finRate = [math]::Round($totalFinalized * 100.0 / $totalGenerated, 2) } else { $finRate = 0 }
        # v4.3-EXT-patched FIX 6: reward tx (fee) explanation
        $totalRewardTxs = $totalFinalized - $totalGenerated
        if ($totalRewardTxs -lt 0) { $totalRewardTxs = 0 }

        Log-Report '[3/3] FINAL RESULTS'
        Log-Report ''
        Log-Report '============================================================'
        Log-Report ('  NeuroGraph ANGP v4.3-EXT  -  {0} SHARDS x {1} NODES/SHARD  ({2} total)' -f $NUM_SHARDS, $NODES, $totalNodes)
        Log-Report '============================================================'
        Log-Report ''
        Log-Report '  CONFIG:'
        Log-Report ("    Shards:                   {0} (succeeded: {1})" -f $NUM_SHARDS, $goodShards)
        Log-Report ("    Nodes per shard:          {0}" -f $NODES)
        Log-Report ("    Total nodes:              {0}" -f $totalNodes)
        Log-Report ("    Batch size:               {0} (2 thr/shard)" -f $BATCH_SIZE)
        Log-Report ("    Steps:                    {0}" -f $STEPS)
        Log-Report ("    Attackers:                {0}% (37 attacker types: T0-T36)" -f $PERCENT)
        Log-Report ''
        Log-Report '  TRANSACTIONS:'
        Log-Report ('    Total generated (honest): {0:N0}' -f $totalGenerated)
        Log-Report ('    Total finalized:          {0:N0}  (honest + {1:N0} reward tx @ 0.1% fee)' -f $totalFinalized, $totalRewardTxs)
        Log-Report ('    Honest tx rejected:       {0:N0}' -f $totalRejected)
        if ($totalAttacksAttempted -gt 0) {
            Log-Report ('    Total attacks blocked:    {0:N0} / {1:N0}  ({2:N2}%)' -f $totalAttacksBlocked, $totalAttacksAttempted, ($totalAttacksBlocked * 100.0 / $totalAttacksAttempted))
        }
        Log-Report ("    Finalization rate:        {0}%  (tf/tg, includes fee txs)" -f $finRate)
        Log-Report ''
        Log-Report '  TIMING:'
        Log-Report ('    Wall-clock total:         {0:N1}s ({1:N1} min)  (sequential batches of {2})' -f $wallElapsed, ($wallElapsed / 60), $BATCH_SIZE)
        # v4.3-EXT-patched FIX 2: real arithmetic mean (was wallElapsed/N)
        Log-Report ('    Avg per shard (real):     {0:N2}s  (arithmetic mean of per-shard Total time)' -f $meanShardTime)
        if ($stddevShardTime -gt 0) {
            Log-Report ('    Std dev shard time:       {0:N2}s' -f $stddevShardTime)
        }
        if ($minTime -lt [double]::MaxValue) { Log-Report ('    Min shard time:           {0:N2}s' -f $minTime) }
        Log-Report ('    Max shard time:           {0:N2}s' -f $maxTime)
        Log-Report ''
        Log-Report '  +=============================================================+'
        Log-Report '  |                    TPS RESULTS                                |'
        Log-Report '  +=============================================================+'
        Log-Report ('  | tps/shard (avg):                {0,12:N0} TPS  (per-shard mean)    |' -f $avgTps)
        if ($minShardTpsId -ge 0) {
            Log-Report ('  | tps/shard (min):                {0,12:N0} TPS  (shard #{1} <- bottleneck) |' -f $minShardTps, $minShardTpsId)
        }
        if ($maxShardTpsId -ge 0) {
            Log-Report ('  | tps/shard (max):                {0,12:N0} TPS  (shard #{1})          |' -f $maxShardTps, $maxShardTpsId)
        }
        if ($tpsImbalance -gt 0) {
            Log-Report ('  | TPS imbalance (max-min)/max:    {0,12:N2}%                        |' -f $tpsImbalance)
        }
        Log-Report ('  |                                                             |')
        Log-Report ('  | tps/aggregate:                {0,12:N0} TPS  (Network capacity = N x tps/shard) |' -f $sumTps)
        Log-Report ('  |                                                             |')
        Log-Report ('  | tps/agg (wall-clock):         {0,12:N0} TPS  (Total_tx / wallElapsed, measured) |' -f $aggTpsWall)
        Log-Report ('  |   ({0} shards in sequential batches of {1})' -f $goodShards, $BATCH_SIZE)
        Log-Report ('  |                                                             |')
        # v4.3-EXT-patched FIX 1: real scaling factor (was hardcoded $NUM_SHARDS)
        Log-Report ('  | Scaling factor (real):           {0,12:N2} x  (tps/agg / tps/shard)   |' -f $scalingFactorReal)
        Log-Report ('  | Batch parallel efficiency:       {0,12:N1}%  (ideal_batch/wallElapsed) |' -f $batchParEff)
        Log-Report '  +=============================================================+'
        Log-Report ''
        # v4.3-EXT-patched FIX 4 (final): EXTRAPOLATION block hidden when
        # NUM_SHARDS >= 333 (no point projecting to 333 if already at 333+).
        # For smaller N, show only meaningful projection (Aggregate, linear).
        if ($NUM_SHARDS -lt 333) {
            Log-Report '  EXTRAPOLATION to whitepaper (333 shards, 8 nodes/shard):' -ForegroundColor Magenta
            Log-Report ''
            Log-Report '  AGGREGATE TPS (theoretical capacity = N x tps/shard):' -Color Cyan
            Log-Report ('    This bench (1 shard):     ~{0:N0} TPS' -f $avgTps)
            Log-Report ('    This bench ({0} shards):   ~{1:N0} TPS  (= {0} x tps/shard)' -f $goodShards, $aggTpsCurrentN)
            Log-Report ('    Projected at 333 shards:  ~{0:N0} TPS  (= 333 x tps/shard, IDEAL LINEAR)' -f $tps333Ideal)
            Log-Report ''
            Log-Report '  WALL-CLOCK TPS (hardware-limited, must be measured):' -Color Yellow
            Log-Report ('    This bench ({0} shards):   ~{1:N0} TPS  ({2:N2}% of aggregate)' -f $goodShards, $aggTpsWall, $wallEffPct)
            Log-Report ('      Limited by: {0} cores, BATCH_SIZE={1}' -f $coreCount, $BATCH_SIZE)
            Log-Report '    Projected at 333 shards:  MUST BE MEASURED on real hardware.'
            Log-Report ''
        }
        Log-Report '  NOTE - the 3 TPS metrics:' -Color Gray
        Log-Report '    tps/shard     = per-shard throughput (bottleneck detector)' -Color Gray
        Log-Report '    tps/aggregate = SUM of per-shard TPS = N x tps/shard (CAPACITY, linear)' -Color Gray
        Log-Report '    tps/agg       = total_tx / wall_time (HARDWARE-LIMITED, measured)' -Color Gray
        Log-Report '    Aggregate >= Wall-clock ALWAYS. When shards run sequentially' -Color Gray
        Log-Report '    (BATCH_SIZE=4 on limited cores), tps/agg << tps/aggregate.' -Color Gray
        Log-Report '    With 1 thread pool per shard (unlimited cores), tps/agg -> tps/aggregate.' -Color Gray
        Log-Report ''
        if ($PERCENT -eq 0) {
            Log-Report '  MODE: CLEAN (0% attackers)' -Color Green
            Log-Report '    ABR:                       N/A  (clean run, no attackers)' -Color Green
        } else {
            Log-Report ('  SECURITY (37 attacker types T0-T36, {0}% attackers):' -f $PERCENT) -Color Green
            if ($dsPct -ge 0) {
                Log-Report ('    Double-spend blocked:       {0}/{1} ({2}%)' -f $totalDSBlocked, $totalDSTotal, $dsPct) -Color Green
            } else {
                Log-Report '    Double-spend blocked:       0/0 (100%)' -Color Green
            }
            if ($theftPct -ge 0) {
                Log-Report ('    Theft blocked:              {0}/{1} ({2}%)' -f $totalTheftBlocked, $totalTheftTotal, $theftPct) -Color Green
            } else {
                Log-Report '    Theft blocked:              0/0 (100%)' -Color Green
            }
            if ($avgFPR -ge 0) {
                Log-Report ('    Honest FPR:                {0}%' -f $avgFPR) -Color Green
            } else {
                Log-Report '    Honest FPR:                0%' -Color Green
            }
            if ($avgABR -ge 0) {
                # v4.3-EXT-patched: clarify that ABR is averaged across shards
                # and means attackers eliminated OR gated-but-not-eliminated
                Log-Report ('    ABR (avg per shard):       {0}%  (eliminated + gated / total attackers)' -f $avgABR) -Color Green
                Log-Report ('      -> Low ABR with low STEPS means reputation engine did not' ) -Color Gray
                Log-Report ('         have enough time to converge (calibrated for 5K+ steps).' ) -Color Gray
            } else {
                Log-Report '    ABR:                       N/A  (not found in shard output)' -Color Yellow
            }
        }
        Log-Report '============================================================'

        $atkLabel = if ($PERCENT -eq 0) { 'clean' } else { ('atk{0}' -f $PERCENT) }
        $reportFile = Join-Path $reportDir ('TPS-v4.3ext-{0}s-{1}n-{2}-{3}.txt' -f $NUM_SHARDS, $NODES, $atkLabel, (Get-Date -Format 'yyyyMMdd-HHmmss'))
        $allReportLines | Set-Content -Path $reportFile -Encoding UTF8
        Write-Host '  Report saved.' -ForegroundColor Green

        # ---- HISTORY ----
        $allReports = Get-ChildItem (Join-Path $reportDir 'TPS-*.txt') | Sort-Object Name
        if ($allReports.Count -gt 0) {
            Log-Report ''
            Log-Report '  TEST HISTORY:' -Color Magenta
            Log-Report '  +------+-------+------+-------+-------+--------+--------+------------------+'
            Log-Report '  | Shard| Nodes | Atk% |  TPS  | Wall  |  Agg   | Data              |'
            Log-Report '  +------+-------+------+-------+-------+--------+--------+------------------+'
            foreach ($rp in $allReports) {
                $rc = Get-Content $rp.FullName -Raw
                $rS = '?'; if ($rc -match '(\d+)\s+SHARDS') { $rS = $Matches[1] }
                $rN = '?'; if ($rc -match '(\d+)\s+NODES/SHARD') { $rN = $Matches[1] }
                $rA = '?'; if ($rc -match 'Attackers:\s+(\d+)%') { $rA = $Matches[1] }
                $rT = '?'; if ($rc -match 'tps/shard \(avg\):\s+([0-9,\s]+)TPS') { $rT = $Matches[1].Trim() }
                $rW = '?'; if ($rc -match 'Wall-clock total:\s+([0-9\.]+)s') { $rW = $Matches[1].Trim() + 's' }
                $rAg = '?'; if ($rc -match 'tps/agg \(wall-clock\):\s+([0-9,\s]+)TPS') { $rAg = $Matches[1].Trim() }
                $rD = $rp.BaseName -replace 'TPS-','' -replace '-',' '
                $rl = '  | {0,-4} | {1,-5} | {2,-4} | {3,-5} | {4,-6} | {5,-6} | {6,-16} |' -f $rS, $rN, $rA, $rT, $rW, $rAg, $rD
                Log-Report $rl
            }
            Log-Report '  +------+-------+------+-------+-------+--------+--------+------------------+'
        }
    } catch {
        Write-Host ''
        Write-Host ("ERROR: {0}" -f $_.Exception.Message) -ForegroundColor Red
        Write-Host ("Stack: {0}" -f $_.ScriptStackTrace) -ForegroundColor Red
    }

    # ---- TEST COMPLETED ----
    Write-Host ''
    Write-Host '  -----------------------------------------------------------' -ForegroundColor DarkGray
    Write-Host '  Test completed. Menu reappears below.' -ForegroundColor DarkGray
    Write-Host '  -----------------------------------------------------------' -ForegroundColor DarkGray
    Start-Sleep -Seconds 1
} # end while ($true)
