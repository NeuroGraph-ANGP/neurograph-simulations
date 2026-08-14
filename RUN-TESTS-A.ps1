#=============================================================================
# NeuroGraph ANGP v4.3-EXT -- TEST SUITE A
# 2664 Nodes | 37 Attacker Types (T0-T36) | Behavioral Strategies
# PowerShell -- 4 step sets (10K/30K/50K/100K) x 9 attack levels
# ============================================================================
#
# 37 ATTACKER TYPES (T0-T36):
#   T0-T15 (16 base):
#     T0  = Random                  T8  = Progressive-Drift
#     T1  = Mimicry300              T9  = Outlier-Burst
#     T2  = Mimicry500              T10 = Clone-Copy
#     T3  = Adaptive-RepAware       T11 = Byzantine
#     T4  = Coordinated-Bias        T12 = Sybil-Cluster
#     T5  = Gaussian                T13 = Rep-Farmer
#     T6  = FlipFlop                T14 = Oscillating-Drift
#     T7  = Sleeper                 T15 = Colluding-Committee
#
#   T16-T21 (6 extended):
#     T16 = Slow Poisoning Consensus    T19 = Sybil Replacement
#     T17 = Eclipse Attack              T20 = Patient Byzantine
#     T18 = Majority Reference Manip    T21 = Threshold Gamer
#
#   T22-T36 (15 advanced):
#     T22 = True-Feedback-Adaptive      T30 = Threshold-Boundary
#     T23 = Reputation-Gradient        T31 = Recovery-Exploit
#     T24 = Detector-Aware-Mimicry     T32 = Sybil-Identity-Cycling
#     T25 = Distributed-Influence      T33 = Collud-Honest-Majority
#     T26 = Anti-Coordination          T34 = Consensus-Targeted
#     T27 = Reputation-Camouflage      T35 = Multi-Vector-Adaptive
#     T28 = Long-Horizon-Poisoning     T36 = Worst-Case-Coordinated
#     T29 = Honest-Malicious-Switch
#
# USAGE:
#   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
#   .\RUN-TESTS-A.ps1
#   .\RUN-TESTS-A.ps1 5        (run option 5 directly)
#   .\RUN-TESTS-A.ps1 all      (run all batch tests)
# ============================================================================

# --- Self-elevate execution policy ---
if ($PSVersionTable.PSVersion.Major -ge 5) {
    $cp = Get-ExecutionPolicy -Scope Process -ErrorAction SilentlyContinue
    if ($cp -eq 'Restricted' -or $cp -eq 'AllSigned') {
        Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force -ErrorAction SilentlyContinue
    }
}

$ErrorActionPreference = "Continue"
chcp 65001 > $null 2>&1
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# --- Find project folder (Cargo.toml) ---
$ProjectDir = $PSScriptRoot
if (-not (Test-Path "$ProjectDir\Cargo.toml")) {
    $ProjectDir = (Get-Location).Path
    for ($k = 0; $k -lt 5; $k++) {
        if (Test-Path "$ProjectDir\Cargo.toml") { break }
        $parent = Split-Path $ProjectDir -Parent
        if ($parent -eq $ProjectDir) { break }
        $ProjectDir = $parent
    }
}
if (-not (Test-Path "$ProjectDir\Cargo.toml")) { $ProjectDir = 'D:\neurograph_v4.3-ext' }
if (-not (Test-Path "$ProjectDir\Cargo.toml")) {
    Write-Host '  CRITICAL ERROR: Cargo.toml not found!' -ForegroundColor Red
    Write-Host '  Run this script FROM the project folder (where Cargo.toml is)' -ForegroundColor Yellow
    Read-Host 'Press ENTER'; exit 1
}
Set-Location $ProjectDir

$isWindows = $true
if ($PSVersionTable.PSVersion.Major -ge 6) {
    $isWindows = -not $IsLinux -and -not $IsMacOS
}
$exeExt = if ($isWindows) { '.exe' } else { '' }
$sep = if ($isWindows) { '\' } else { '/' }

$ResultsDir = Join-Path $ProjectDir 'tests\results-a'
New-Item -ItemType Directory -Force -Path $ResultsDir | Out-Null
$Timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$LogFile = "$ResultsDir\test-suite-a-$Timestamp.log"

# --- Logging functions ---
function Log($msg) { $msg | Tee-Object -FilePath $LogFile -Append }
function LogInfo($msg) { Log "[INFO] $msg" }
function LogSuccess($msg) { Log "[SUCCESS] $msg" }
function LogError($msg) { Log "[ERROR] $msg" }

# --- Main header ---
function PrintHeader {
    Write-Host ''
    Write-Host '================================================================' -ForegroundColor Cyan
    Write-Host '= NeuroGraph ANGP v4.3-EXT -- TEST SUITE A                  =' -ForegroundColor Cyan
    Write-Host '= Security & Stress Tests                                   =' -ForegroundColor Cyan
    Write-Host '= 37 Attacker Types (T0-T36) | Behavioral Strategies        =' -ForegroundColor Cyan
    Write-Host '= 2664 Nodes (333 shards x 8 nodes/shard)                   =' -ForegroundColor Cyan
    Write-Host '================================================================' -ForegroundColor Cyan
    Write-Host ''
}

# --- Attacker type details ---
function PrintAtackerTypes {
    Write-Host ''
    Write-Host '  37 ATTACKER TYPES (T0-T36):' -ForegroundColor Yellow
    Write-Host '  -----------------------------------------------------------' -ForegroundColor DarkGray
    Write-Host '  T0-T15 (16 base):' -ForegroundColor White
    Write-Host '    T0  = Random              T8  = Progressive-Drift' -ForegroundColor Gray
    Write-Host '    T1  = Mimicry300          T9  = Outlier-Burst' -ForegroundColor Gray
    Write-Host '    T2  = Mimicry500          T10 = Clone-Copy' -ForegroundColor Gray
    Write-Host '    T3  = Adaptive-RepAware   T11 = Byzantine' -ForegroundColor Gray
    Write-Host '    T4  = Coordinated-Bias    T12 = Sybil-Cluster' -ForegroundColor Gray
    Write-Host '    T5  = Gaussian            T13 = Rep-Farmer' -ForegroundColor Gray
    Write-Host '    T6  = FlipFlop            T14 = Oscillating-Drift' -ForegroundColor Gray
    Write-Host '    T7  = Sleeper             T15 = Colluding-Committee' -ForegroundColor Gray
    Write-Host ''
    Write-Host '  T16-T21 (6 extended):' -ForegroundColor White
    Write-Host '    T16 = Slow Poisoning Consensus    T19 = Sybil Replacement' -ForegroundColor Gray
    Write-Host '    T17 = Eclipse Attack              T20 = Patient Byzantine' -ForegroundColor Gray
    Write-Host '    T18 = Majority Reference Manip    T21 = Threshold Gamer' -ForegroundColor Gray
    Write-Host ''
    Write-Host '  T22-T36 (15 advanced):' -ForegroundColor White
    Write-Host '    T22 = True-Feedback-Adaptive      T30 = Threshold-Boundary' -ForegroundColor Gray
    Write-Host '    T23 = Reputation-Gradient        T31 = Recovery-Exploit' -ForegroundColor Gray
    Write-Host '    T24 = Detector-Aware-Mimicry     T32 = Sybil-Identity-Cycling' -ForegroundColor Gray
    Write-Host '    T25 = Distributed-Influence      T33 = Collud-Honest-Majority' -ForegroundColor Gray
    Write-Host '    T26 = Anti-Coordination          T34 = Consensus-Targeted' -ForegroundColor Gray
    Write-Host '    T27 = Reputation-Camouflage      T35 = Multi-Vector-Adaptive' -ForegroundColor Gray
    Write-Host '    T28 = Long-Horizon-Poisoning     T36 = Worst-Case-Coordinated' -ForegroundColor Gray
    Write-Host '    T29 = Honest-Malicious-Switch' -ForegroundColor Gray
    Write-Host '  -----------------------------------------------------------' -ForegroundColor DarkGray
    Write-Host ''
}

function PrintBanner($title) {
    Write-Host ''
    Write-Host '================================================================' -ForegroundColor Cyan
    Write-Host "= $title" -ForegroundColor Cyan
    Write-Host '================================================================' -ForegroundColor Cyan
}

# --- Build / verify binary ---
function EnsureBinary {
    if ($PrecompiledBinary) {
        return $PrecompiledBinary
    }
    $binary = Join-Path $ProjectDir ("target{0}release{0}examples{0}sim_stress_v43ext{1}" -f $sep, $exeExt)
    if (-not (Test-Path $binary)) {
        LogInfo 'Building sim_stress_v43ext...'
        Set-Location $ProjectDir
        cargo build --release --example sim_stress_v43ext 2>&1 | Tee-Object -FilePath $LogFile -Append
        if ($LASTEXITCODE -ne 0) {
            LogError 'Build FAILED!'
            exit 1
        }
        LogSuccess 'Build completed successfully!'
    }
    return $binary
}

# --- Run individual test ---
function RunStressTest($testName, $percent, $nodes, $steps) {
    $outputFile = "$ResultsDir\$testName-$Timestamp.txt"
    PrintBanner "Running: $testName"
    LogInfo ('Params: --percent {0} --nodes {1} --steps {2}' -f $percent, $nodes, $steps)
    LogInfo ('37 attacker types (T0-T36) distributed proportionally at {0}%' -f $percent)
    $binary = EnsureBinary
    $startTime = Get-Date
    & $binary --percent $percent --nodes $nodes --steps $steps 2>&1 | Tee-Object -FilePath $outputFile
    $endTime = Get-Date
    $elapsed = ($endTime - $startTime).TotalSeconds
    LogInfo ('Test finished in {0:N2}s' -f $elapsed)
}

# ============================================================================
# TEST OPTIONS -- 4 STEP SETS x 9 ATTACK LEVELS
# ============================================================================

function Option1 { PrintBanner 'OPTION 1: 10K STEPS -- Low ATTACK (10%)'; RunStressTest 'sec-10k-10pct' 10 $NODES 10000 }
function Option2 { PrintBanner 'OPTION 2: 10K STEPS -- Moderate ATTACK (20%)'; RunStressTest 'sec-10k-20pct' 20 $NODES 10000 }
function Option3 { PrintBanner 'OPTION 3: 10K STEPS -- Medium ATTACK (30%)'; RunStressTest 'sec-10k-30pct' 30 $NODES 10000 }
function Option4 { PrintBanner 'OPTION 4: 10K STEPS -- Significant ATTACK (40%)'; RunStressTest 'sec-10k-40pct' 40 $NODES 10000 }
function Option5 { PrintBanner 'OPTION 5: 10K STEPS -- High ATTACK (50%)'; RunStressTest 'sec-10k-50pct' 50 $NODES 10000 }
function Option6 { PrintBanner 'OPTION 6: 10K STEPS -- Intense ATTACK (60%)'; RunStressTest 'sec-10k-60pct' 60 $NODES 10000 }
function Option7 { PrintBanner 'OPTION 7: 10K STEPS -- Severe ATTACK (70%)'; RunStressTest 'sec-10k-70pct' 70 $NODES 10000 }
function Option8 { PrintBanner 'OPTION 8: 10K STEPS -- Critical ATTACK (80%)'; RunStressTest 'sec-10k-80pct' 80 $NODES 10000 }
function Option9 { PrintBanner 'OPTION 9: 10K STEPS -- Extreme ATTACK (90%)'; RunStressTest 'sec-10k-90pct' 90 $NODES 10000 }
function Option11 { PrintBanner 'OPTION 11: 30K STEPS -- Low ATTACK (10%)'; RunStressTest 'sec-30k-10pct' 10 $NODES 30000 }
function Option12 { PrintBanner 'OPTION 12: 30K STEPS -- Moderate ATTACK (20%)'; RunStressTest 'sec-30k-20pct' 20 $NODES 30000 }
function Option13 { PrintBanner 'OPTION 13: 30K STEPS -- Medium ATTACK (30%)'; RunStressTest 'sec-30k-30pct' 30 $NODES 30000 }
function Option14 { PrintBanner 'OPTION 14: 30K STEPS -- Significant ATTACK (40%)'; RunStressTest 'sec-30k-40pct' 40 $NODES 30000 }
function Option15 { PrintBanner 'OPTION 15: 30K STEPS -- High ATTACK (50%)'; RunStressTest 'sec-30k-50pct' 50 $NODES 30000 }
function Option16 { PrintBanner 'OPTION 16: 30K STEPS -- Intense ATTACK (60%)'; RunStressTest 'sec-30k-60pct' 60 $NODES 30000 }
function Option17 { PrintBanner 'OPTION 17: 30K STEPS -- Severe ATTACK (70%)'; RunStressTest 'sec-30k-70pct' 70 $NODES 30000 }
function Option18 { PrintBanner 'OPTION 18: 30K STEPS -- Critical ATTACK (80%)'; RunStressTest 'sec-30k-80pct' 80 $NODES 30000 }
function Option19 { PrintBanner 'OPTION 19: 30K STEPS -- Extreme ATTACK (90%)'; RunStressTest 'sec-30k-90pct' 90 $NODES 30000 }
function Option21 { PrintBanner 'OPTION 21: 50K STEPS -- Low ATTACK (10%)'; RunStressTest 'sec-50k-10pct' 10 $NODES 50000 }
function Option22 { PrintBanner 'OPTION 22: 50K STEPS -- Moderate ATTACK (20%)'; RunStressTest 'sec-50k-20pct' 20 $NODES 50000 }
function Option23 { PrintBanner 'OPTION 23: 50K STEPS -- Medium ATTACK (30%)'; RunStressTest 'sec-50k-30pct' 30 $NODES 50000 }
function Option24 { PrintBanner 'OPTION 24: 50K STEPS -- Significant ATTACK (40%)'; RunStressTest 'sec-50k-40pct' 40 $NODES 50000 }
function Option25 { PrintBanner 'OPTION 25: 50K STEPS -- High ATTACK (50%)'; RunStressTest 'sec-50k-50pct' 50 $NODES 50000 }
function Option26 { PrintBanner 'OPTION 26: 50K STEPS -- Intense ATTACK (60%)'; RunStressTest 'sec-50k-60pct' 60 $NODES 50000 }
function Option27 { PrintBanner 'OPTION 27: 50K STEPS -- Severe ATTACK (70%)'; RunStressTest 'sec-50k-70pct' 70 $NODES 50000 }
function Option28 { PrintBanner 'OPTION 28: 50K STEPS -- Critical ATTACK (80%)'; RunStressTest 'sec-50k-80pct' 80 $NODES 50000 }
function Option29 { PrintBanner 'OPTION 29: 50K STEPS -- Extreme ATTACK (90%)'; RunStressTest 'sec-50k-90pct' 90 $NODES 50000 }
function Option31 { PrintBanner 'OPTION 31: 100K STEPS -- Low ATTACK (10%)'; RunStressTest 'sec-100k-10pct' 10 $NODES 100000 }
function Option32 { PrintBanner 'OPTION 32: 100K STEPS -- Moderate ATTACK (20%)'; RunStressTest 'sec-100k-20pct' 20 $NODES 100000 }
function Option33 { PrintBanner 'OPTION 33: 100K STEPS -- Medium ATTACK (30%)'; RunStressTest 'sec-100k-30pct' 30 $NODES 100000 }
function Option34 { PrintBanner 'OPTION 34: 100K STEPS -- Significant ATTACK (40%)'; RunStressTest 'sec-100k-40pct' 40 $NODES 100000 }
function Option35 { PrintBanner 'OPTION 35: 100K STEPS -- High ATTACK (50%)'; RunStressTest 'sec-100k-50pct' 50 $NODES 100000 }
function Option36 { PrintBanner 'OPTION 36: 100K STEPS -- Intense ATTACK (60%)'; RunStressTest 'sec-100k-60pct' 60 $NODES 100000 }
function Option37 { PrintBanner 'OPTION 37: 100K STEPS -- Severe ATTACK (70%)'; RunStressTest 'sec-100k-70pct' 70 $NODES 100000 }
function Option38 { PrintBanner 'OPTION 38: 100K STEPS -- Critical ATTACK (80%)'; RunStressTest 'sec-100k-80pct' 80 $NODES 100000 }
function Option39 { PrintBanner 'OPTION 39: 100K STEPS -- Extreme ATTACK (90%)'; RunStressTest 'sec-100k-90pct' 90 $NODES 100000 }

function Option41 { PrintBanner 'OPTION 41: CLEAN RUN -- 10K STEPS (0% attackers)'; RunStressTest 'clean-10k-steps' 0 $NODES 10000 }
function Option42 { PrintBanner 'OPTION 42: CLEAN RUN -- 30K STEPS (0% attackers)'; RunStressTest 'clean-30k-steps' 0 $NODES 30000 }
function Option43 { PrintBanner 'OPTION 43: CLEAN RUN -- 50K STEPS (0% attackers)'; RunStressTest 'clean-50k-steps' 0 $NODES 50000 }
function Option44 { PrintBanner 'OPTION 44: CLEAN RUN -- 100K STEPS (0% attackers)'; RunStressTest 'clean-100k-steps' 0 $NODES 100000 }

# --- Custom option ---
function Option50 {
    PrintBanner 'OPTION 50: CUSTOM -- Configure everything manually'
    Write-Host ''
    Write-Host '  Configure test parameters:' -ForegroundColor Yellow
    Write-Host ''
    $cNodes = Read-Host '  Nodes [default: 2664]'
    $cSteps = Read-Host '  Steps [default: 10000]'
    $cPercent = Read-Host '  Attackers % (0-99) [default: 10]'
    if (-not $cNodes) { $cNodes = 2664 }
    if (-not $cSteps) { $cSteps = 10000 }
    if (-not $cPercent) { $cPercent = 10 }
    try { $cNodes = [int]$cNodes } catch { LogError 'Invalid nodes!'; return }
    try { $cSteps = [int]$cSteps } catch { LogError 'Invalid steps!'; return }
    try { $cPercent = [int]$cPercent } catch { LogError 'Invalid percent!'; return }
    if ($cNodes -lt 1) { LogError 'Nodes: minimum 1'; return }
    if ($cSteps -lt 1) { LogError 'Steps: minimum 1'; return }
    if ($cPercent -lt 0 -or $cPercent -gt 99) { LogError 'Percent: must be 0-99'; return }
    $testName = 'custom-{0}n-{1}s-{2}pct' -f $cNodes, $cSteps, $cPercent
    RunStressTest $testName $cPercent $cNodes $cSteps
}

# --- Quick tests (500 steps) ---
function Option51 { PrintBanner 'OPTION 51: QUICK 10% atk (500 steps)'; RunStressTest 'quick-10pct' 10 $NODES 500 }
function Option52 { PrintBanner 'OPTION 52: QUICK 20% atk (500 steps)'; RunStressTest 'quick-20pct' 20 $NODES 500 }
function Option53 { PrintBanner 'OPTION 53: QUICK 50% atk (500 steps)'; RunStressTest 'quick-50pct' 50 $NODES 500 }

# --- Batch: 10K all 10%-90% ---
function Option60 {
    PrintBanner 'OPTION 60: BATCH 10K -- All levels 10%-90%'
    foreach ($p in @(10,20,30,40,50,60,70,80,90)) {
        RunStressTest ('batch-10k-{0}pct' -f $p) $p $NODES 10000
    }
    LogSuccess 'Batch 10K complete'
}

# --- Batch: 30K all 10%-90% ---
function Option61 {
    PrintBanner 'OPTION 61: BATCH 30K -- All levels 10%-90%'
    foreach ($p in @(10,20,30,40,50,60,70,80,90)) {
        RunStressTest ('batch-30k-{0}pct' -f $p) $p $NODES 30000
    }
    LogSuccess 'Batch 30K complete'
}

# --- Batch: 50K all 10%-90% ---
function Option62 {
    PrintBanner 'OPTION 62: BATCH 50K -- All levels 10%-90%'
    foreach ($p in @(10,20,30,40,50,60,70,80,90)) {
        RunStressTest ('batch-50k-{0}pct' -f $p) $p $NODES 50000
    }
    LogSuccess 'Batch 50K complete'
}

# --- Batch: 100K all 10%-90% ---
function Option63 {
    PrintBanner 'OPTION 63: BATCH 100K -- All levels 10%-90%'
    foreach ($p in @(10,20,30,40,50,60,70,80,90)) {
        RunStressTest ('batch-100k-{0}pct' -f $p) $p $NODES 100000
    }
    LogSuccess 'Batch 100K complete'
}

# --- Batch: COMPLETE -- all 4 step sets x all 9 levels ---
function Option64 {
    PrintBanner 'OPTION 64: FULL BATCH -- 4 sets x 9 levels = 36 tests'
    LogInfo '10K steps...'
    foreach ($p in @(10,20,30,40,50,60,70,80,90)) { RunStressTest ('full-10k-{0}pct' -f $p) $p $NODES 10000 }
    LogInfo '30K steps...'
    foreach ($p in @(10,20,30,40,50,60,70,80,90)) { RunStressTest ('full-30k-{0}pct' -f $p) $p $NODES 30000 }
    LogInfo '50K steps...'
    foreach ($p in @(10,20,30,40,50,60,70,80,90)) { RunStressTest ('full-50k-{0}pct' -f $p) $p $NODES 50000 }
    LogInfo '100K steps...'
    foreach ($p in @(10,20,30,40,50,60,70,80,90)) { RunStressTest ('full-100k-{0}pct' -f $p) $p $NODES 100000 }
    LogSuccess 'Full batch (36 tests) complete!'
}

# ============================================================================
# MENU SYSTEM
# ============================================================================

function ShowMenu {
    Write-Host ''
    Write-Host '================================================================' -ForegroundColor White
    Write-Host '=   NeuroGraph ANGP v4.3-EXT -- TEST SUITE A -- MENU        =' -ForegroundColor White
    Write-Host '=   37 Attacker Types (T0-T36) | Behavioral Strategies     =' -ForegroundColor White
    Write-Host '=   2664 Nodes (333 shards x 8 nodes/shard)                 =' -ForegroundColor White
    Write-Host '================================================================' -ForegroundColor White
    Write-Host ''
    Write-Host '  10K STEPS (10,000 steps, 37 atk types T0-T36)' -ForegroundColor Yellow
    Write-Host '     1)  Low            (10%)' -ForegroundColor White
    Write-Host '     2)  Moderate       (20%)' -ForegroundColor White
    Write-Host '     3)  Medium         (30%)' -ForegroundColor White
    Write-Host '     4)  Significant    (40%)' -ForegroundColor White
    Write-Host '     5)  High           (50%)' -ForegroundColor White
    Write-Host '     6)  Intense        (60%)' -ForegroundColor White
    Write-Host '     7)  Severe         (70%)' -ForegroundColor White
    Write-Host '     8)  Critical       (80%)' -ForegroundColor White
    Write-Host '     9)  Extreme        (90%)' -ForegroundColor White
    Write-Host ''
    Write-Host '  30K STEPS (30,000 steps, 37 atk types T0-T36)' -ForegroundColor Yellow
    Write-Host '    11)  Low            (10%)' -ForegroundColor White
    Write-Host '    12)  Moderate       (20%)' -ForegroundColor White
    Write-Host '    13)  Medium         (30%)' -ForegroundColor White
    Write-Host '    14)  Significant    (40%)' -ForegroundColor White
    Write-Host '    15)  High           (50%)' -ForegroundColor White
    Write-Host '    16)  Intense        (60%)' -ForegroundColor White
    Write-Host '    17)  Severe         (70%)' -ForegroundColor White
    Write-Host '    18)  Critical       (80%)' -ForegroundColor White
    Write-Host '    19)  Extreme        (90%)' -ForegroundColor White
    Write-Host ''
    Write-Host '  50K STEPS (50,000 steps, 37 atk types T0-T36)' -ForegroundColor Yellow
    Write-Host '    21)  Low            (10%)' -ForegroundColor White
    Write-Host '    22)  Moderate       (20%)' -ForegroundColor White
    Write-Host '    23)  Medium         (30%)' -ForegroundColor White
    Write-Host '    24)  Significant    (40%)' -ForegroundColor White
    Write-Host '    25)  High           (50%)' -ForegroundColor White
    Write-Host '    26)  Intense        (60%)' -ForegroundColor White
    Write-Host '    27)  Severe         (70%)' -ForegroundColor White
    Write-Host '    28)  Critical       (80%)' -ForegroundColor White
    Write-Host '    29)  Extreme        (90%)' -ForegroundColor White
    Write-Host ''
    Write-Host ' 100K STEPS (100,000 steps, 37 atk types T0-T36)' -ForegroundColor Yellow
    Write-Host '    31)  Low            (10%)' -ForegroundColor White
    Write-Host '    32)  Moderate       (20%)' -ForegroundColor White
    Write-Host '    33)  Medium         (30%)' -ForegroundColor White
    Write-Host '    34)  Significant    (40%)' -ForegroundColor White
    Write-Host '    35)  High           (50%)' -ForegroundColor White
    Write-Host '    36)  Intense        (60%)' -ForegroundColor White
    Write-Host '    37)  Severe         (70%)' -ForegroundColor White
    Write-Host '    38)  Critical       (80%)' -ForegroundColor White
    Write-Host '    39)  Extreme        (90%)' -ForegroundColor White
    Write-Host ''
    Write-Host '  CLEAN (0% attackers)' -ForegroundColor Green
    Write-Host '    41) Clean 10K     42) Clean 30K     43) Clean 50K     44) Clean 100K' -ForegroundColor White
    Write-Host ''
    Write-Host '  CUSTOM' -ForegroundColor Cyan
    Write-Host '    50) Custom (nodes, steps, attack 0-99%)' -ForegroundColor White
    Write-Host ''
    Write-Host '  QUICK (500 steps, fast check)' -ForegroundColor Cyan
    Write-Host '    51) Quick 10%    52) Quick 20%    53) Quick 50%' -ForegroundColor White
    Write-Host ''
    Write-Host '  BATCH' -ForegroundColor Magenta
    Write-Host '    60) Batch 10K (9 tests)    61) Batch 30K (9 tests)' -ForegroundColor White
    Write-Host '    62) Batch 50K (9 tests)    63) Batch 100K (9 tests)' -ForegroundColor White
    Write-Host '    64) Full Batch (36 tests: 4 sets x 9 levels)' -ForegroundColor White
    Write-Host ''
    Write-Host '    99) Show 37 attacker types (T0-T36)' -ForegroundColor DarkCyan
    Write-Host '     0) Exit' -ForegroundColor DarkGray
    Write-Host ''
    Write-Host 'Choose option: ' -NoNewline
}

# ============================================================================
# MAIN
# ============================================================================

PrintHeader
EnsureBinary | Out-Null
Write-Host '  Binary ready.' -ForegroundColor Green
Write-Host ('  Results saved to: {0}' -f $ResultsDir) -ForegroundColor DarkGray
Write-Host ''

$NODES = 2664

# If argument given on command line, run directly
if ($args.Count -gt 0) {
    switch ($args[0]) {
        '1' { Option1; break }
        '2' { Option2; break }
        '3' { Option3; break }
        '4' { Option4; break }
        '5' { Option5; break }
        '6' { Option6; break }
        '7' { Option7; break }
        '8' { Option8; break }
        '9' { Option9; break }
        '11' { Option11; break }
        '12' { Option12; break }
        '13' { Option13; break }
        '14' { Option14; break }
        '15' { Option15; break }
        '16' { Option16; break }
        '17' { Option17; break }
        '18' { Option18; break }
        '19' { Option19; break }
        '21' { Option21; break }
        '22' { Option22; break }
        '23' { Option23; break }
        '24' { Option24; break }
        '25' { Option25; break }
        '26' { Option26; break }
        '27' { Option27; break }
        '28' { Option28; break }
        '29' { Option29; break }
        '31' { Option31; break }
        '32' { Option32; break }
        '33' { Option33; break }
        '34' { Option34; break }
        '35' { Option35; break }
        '36' { Option36; break }
        '37' { Option37; break }
        '38' { Option38; break }
        '39' { Option39; break }
        '41' { Option41; break }
        '42' { Option42; break }
        '43' { Option43; break }
        '44' { Option44; break }
        '50' { Option50; break }
        '51' { Option51; break }
        '52' { Option52; break }
        '53' { Option53; break }
        '60' { Option60; break }
        '61' { Option61; break }
        '62' { Option62; break }
        '63' { Option63; break }
        '64' { Option64; break }
        '99' { PrintAtackerTypes; break }
        'all'{ Option64; break }
        default { LogError ('Invalid option: {0}' -f $args[0]) }
    }
    return
}

# Interactive mode
while ($true) {
    ShowMenu
    $choice = Read-Host

    switch ($choice) {
        '0'  { LogInfo 'Exiting...'; exit 0 }
        '1' { Option1 }
        '2' { Option2 }
        '3' { Option3 }
        '4' { Option4 }
        '5' { Option5 }
        '6' { Option6 }
        '7' { Option7 }
        '8' { Option8 }
        '9' { Option9 }
        '11' { Option11 }
        '12' { Option12 }
        '13' { Option13 }
        '14' { Option14 }
        '15' { Option15 }
        '16' { Option16 }
        '17' { Option17 }
        '18' { Option18 }
        '19' { Option19 }
        '21' { Option21 }
        '22' { Option22 }
        '23' { Option23 }
        '24' { Option24 }
        '25' { Option25 }
        '26' { Option26 }
        '27' { Option27 }
        '28' { Option28 }
        '29' { Option29 }
        '31' { Option31 }
        '32' { Option32 }
        '33' { Option33 }
        '34' { Option34 }
        '35' { Option35 }
        '36' { Option36 }
        '37' { Option37 }
        '38' { Option38 }
        '39' { Option39 }
        '41' { Option41 }
        '42' { Option42 }
        '43' { Option43 }
        '44' { Option44 }
        '50' { Option50 }
        '51' { Option51 }
        '52' { Option52 }
        '53' { Option53 }
        '60' { Option60 }
        '61' { Option61 }
        '62' { Option62 }
        '63' { Option63 }
        '64' { Option64 }
        '99' { PrintAtackerTypes }
        default { LogError ('Invalid option: {0}' -f $choice) }
    }

    Write-Host ''
    Read-Host 'Press Enter to continue...'
}
