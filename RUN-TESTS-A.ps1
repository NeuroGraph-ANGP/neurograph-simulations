#=============================================================================
# NeuroGraph ANGP v4.3.1-FIXED — TEST SUITE A
# 2664 Nodes | 37 Attacker Types (T0-T36) | Behavioral Strategies
# PowerShell — 37 attack types + individual options
# =============================================================================
#
# 37 ATTACKER TYPES (T0-T36):
#   T0-T15 (16 basic):
#     T0  = Random                  — random signals
#     T1  = Mimicry300              — copies honest signal (window 300)
#     T2  = Mimicry500              — copies honest signal (window 500)
#     T3  = Adaptive-RepAware       — adapts based on reputation
#     T4  = Coordinated-Bias        — coordinated bias among attackers
#     T5  = Gaussian                — subtle gaussian perturbation
#     T6  = FlipFlop                — alternates honest/attack
#     T7  = Sleeper                 — dormant until threshold, then attacks
#     T8  = Progressive-Drift       — slow, increasing drift
#     T9  = Outlier-Burst           — bursts of aberrant values
#     T10 = Clone-Copy              — clones an honest node's behavior
#     T11 = Byzantine               — full byzantine behavior
#     T12 = Sybil-Cluster           — cluster of fake identities
#     T13 = Rep-Farmer              — false reputation cultivation
#     T14 = Oscillating-Drift       — oscillating drift, hard to detect
#     T15 = Colluding-Committee     — coordinated attacker committee
#
#   T16-T21 (6 extended):
#     T16 = Slow Poisoning Consensus — 99.9% valid, 0.1% wrong votes
#     T17 = Eclipse Attack           — controls neighbors' view
#     T18 = Majority Reference Manipulation — 60% same wrong value
#     T19 = Sybil Replacement        — eliminated → new identity, rep reset
#     T20 = Patient Byzantine        — perfectly honest 5K steps, then full attack
#     T21 = Threshold Gamer          — avoids detection thresholds (7 thresholds)
#
#   T22-T36 (15 advanced):
#     T22 = True-Feedback-Adaptive   — observes rep feedback, self-adjusts
#     T23 = Reputation-Gradient       — perturbation-probe to learn rep function
#     T24 = Detector-Aware-Mimicry    — mimics honest mean/variance/model
#     T25 = Distributed-Influence     — 100 nodes × small bias, collective push
#     T26 = Anti-Coordination         — same goal, different predictions, avoid clustering
#     T27 = Reputation-Camouflage     — cycles excellent/attack, aggregate rep management
#     T28 = Long-Horizon-Poisoning    — 0.1% wrong over 5K/6K/7K steps
#     T29 = Honest-to-Malicious-Switching — random mode switches, no periodic model
#     T30 = Threshold-Boundary        — lives at threshold-ε, dynamic ε
#     T31 = Reputation-Recovery-Exploit — cycles attack→recovery→attack
#     T32 = Sybil-Identity-Cycling    — A degraded→B new→C new→... behavior transfer
#     T33 = Collusion-Honest-Looking-Majority — 30% atk: 10% aggressive + 20% camouflage
#     T34 = Consensus-Targeted        — optimizes |consensus_attacked - consensus_honest|
#     T35 = Multi-Vector-Adaptive     — boss fight: picks best strategy dynamically
#     T36 = Worst-Case-Coordinated    — perfect coordination, different predictions
#
# USAGE:
#   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
#   .\RUN-TESTS-A.ps1
#   .\RUN-TESTS-A.ps1 5        (run option 5 directly)
# =============================================================================

$ErrorActionPreference = "Continue"
chcp 65001 > $null 2>&1
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# --- Find project directory (Cargo.toml) ---
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
if (-not (Test-Path "$ProjectDir\Cargo.toml")) { $ProjectDir = 'D:\neurograph_v4.3.1-FIXED' }
if (-not (Test-Path "$ProjectDir\Cargo.toml")) {
    Write-Host '  CRITICAL ERROR: Cannot find Cargo.toml!' -ForegroundColor Red
    Write-Host '  Run the script FROM the project directory (where Cargo.toml is)' -ForegroundColor Yellow
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

$NODES = 2664

# --- Logging functions ---
function Log($msg) { $msg | Tee-Object -FilePath $LogFile -Append }
function LogInfo($msg) { Log "[INFO] $msg" }
function LogSuccess($msg) { Log "[OK] $msg" }
function LogError($msg) { Log "[ERROR] $msg" }

# --- Main header ---
function PrintHeader {
    Write-Host ""
    Write-Host '================================================================' -ForegroundColor Cyan
    Write-Host '= NeuroGraph ANGP v4.3.1-FIXED — TEST SUITE A              =' -ForegroundColor Cyan
    Write-Host '= Security & Stress Tests                                   =' -ForegroundColor Cyan
    Write-Host '= 37 Attacker Types (T0-T36) | Behavioral Strategies        =' -ForegroundColor Cyan
    Write-Host '= 2664 Nodes (333 shards x 8 nodes/shard)                  =' -ForegroundColor Cyan
    Write-Host '================================================================' -ForegroundColor Cyan
    Write-Host ""
}

# --- Attacker type details ---
function PrintAttackerTypes {
    Write-Host ""
    Write-Host '  37 ATTACKER TYPES (T0-T36):' -ForegroundColor Yellow
    Write-Host '  ─────────────────────────────────────────────────────────' -ForegroundColor DarkGray
    Write-Host '  T0-T15 (16 basic):' -ForegroundColor White
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
    Write-Host '  ─────────────────────────────────────────────────────────' -ForegroundColor DarkGray
    Write-Host ""
}

function PrintBanner($title) {
    Write-Host ""
    Write-Host '================================================================' -ForegroundColor Cyan
    Write-Host "= $title" -ForegroundColor Cyan
    Write-Host '================================================================' -ForegroundColor Cyan
}

# --- Build / verify binary ---
function EnsureBinary {
    Write-Host '[INFO] Checking binary...' -ForegroundColor DarkGray
    Set-Location $ProjectDir
    $buildOutput = cargo build --release --example sim_stress_v43ext 2>&1
    $buildExit = $LASTEXITCODE
    # Log everything to file, but only show errors on screen
    $buildOutput | Add-Content -Path $LogFile
    if ($buildExit -ne 0) {
        Write-Host '[ERROR] Build failed!' -ForegroundColor Red
        $buildOutput | Where-Object { $_ -match 'error' } | Write-Host
        Add-Content -Path $LogFile -Value '[ERROR] Build failed!'
        exit 1
    }
    Write-Host '[OK] Binary ready.' -ForegroundColor Green
}

# --- Run individual test ---
function RunStressTest($testName, $percent, $nodes, $steps) {
    $outputFile = "$ResultsDir\$testName-$Timestamp.txt"

    PrintBanner "Running: $testName"
    LogInfo ("Params: --percent {0} --nodes {1} --steps {2}" -f $percent, $nodes, $steps)
    if ($percent -gt 0) {
        LogInfo ("37 attacker types (T0-T36) distributed proportionally at {0}%" -f $percent)
    } else {
        LogInfo 'Clean run — 0% attackers'
    }

    EnsureBinary
    $binary = Join-Path $ProjectDir ("target{0}release{0}examples{0}sim_stress_v43ext{1}" -f $sep, $exeExt)

    $startTime = Get-Date

    & $binary --percent $percent --nodes $nodes --steps $steps 2>&1 | Tee-Object -FilePath $outputFile

    $endTime = Get-Date
    $elapsed = ($endTime - $startTime).TotalSeconds

    LogInfo ("Test completed in {0:N2}s" -f $elapsed)
}

# ============================================================================
# TEST OPTIONS — INDIVIDUAL
# ============================================================================

# ── 10K STEPS ──────────────────────────────────────────────────────────────
function Option1  { PrintBanner '10K STEPS + 10% ATTACK';  RunStressTest '10k-10pct'  10 $NODES 10000 }
function Option2  { PrintBanner '10K STEPS + 20% ATTACK';  RunStressTest '10k-20pct'  20 $NODES 10000 }
function Option3  { PrintBanner '10K STEPS + 30% ATTACK';  RunStressTest '10k-30pct'  30 $NODES 10000 }
function Option4  { PrintBanner '10K STEPS + 40% ATTACK';  RunStressTest '10k-40pct'  40 $NODES 10000 }
function Option5  { PrintBanner '10K STEPS + 50% ATTACK';  RunStressTest '10k-50pct'  50 $NODES 10000 }
function Option6  { PrintBanner '10K STEPS + 60% ATTACK';  RunStressTest '10k-60pct'  60 $NODES 10000 }
function Option7  { PrintBanner '10K STEPS + 70% ATTACK';  RunStressTest '10k-70pct'  70 $NODES 10000 }
function Option8  { PrintBanner '10K STEPS + 80% ATTACK';  RunStressTest '10k-80pct'  80 $NODES 10000 }
function Option9  { PrintBanner '10K STEPS + 90% ATTACK';  RunStressTest '10k-90pct'  90 $NODES 10000 }

# ── 30K STEPS ──────────────────────────────────────────────────────────────
function Option10 { PrintBanner '30K STEPS + 10% ATTACK';  RunStressTest '30k-10pct'  10 $NODES 30000 }
function Option11 { PrintBanner '30K STEPS + 20% ATTACK';  RunStressTest '30k-20pct'  20 $NODES 30000 }
function Option12 { PrintBanner '30K STEPS + 30% ATTACK';  RunStressTest '30k-30pct'  30 $NODES 30000 }
function Option13 { PrintBanner '30K STEPS + 40% ATTACK';  RunStressTest '30k-40pct'  40 $NODES 30000 }
function Option14 { PrintBanner '30K STEPS + 50% ATTACK';  RunStressTest '30k-50pct'  50 $NODES 30000 }
function Option15 { PrintBanner '30K STEPS + 60% ATTACK';  RunStressTest '30k-60pct'  60 $NODES 30000 }
function Option16 { PrintBanner '30K STEPS + 70% ATTACK';  RunStressTest '30k-70pct'  70 $NODES 30000 }
function Option17 { PrintBanner '30K STEPS + 80% ATTACK';  RunStressTest '30k-80pct'  80 $NODES 30000 }
function Option18 { PrintBanner '30K STEPS + 90% ATTACK';  RunStressTest '30k-90pct'  90 $NODES 30000 }

# ── 50K STEPS ──────────────────────────────────────────────────────────────
function Option19 { PrintBanner '50K STEPS + 10% ATTACK';  RunStressTest '50k-10pct'  10 $NODES 50000 }
function Option20 { PrintBanner '50K STEPS + 20% ATTACK';  RunStressTest '50k-20pct'  20 $NODES 50000 }
function Option21 { PrintBanner '50K STEPS + 30% ATTACK';  RunStressTest '50k-30pct'  30 $NODES 50000 }
function Option22 { PrintBanner '50K STEPS + 40% ATTACK';  RunStressTest '50k-40pct'  40 $NODES 50000 }
function Option23 { PrintBanner '50K STEPS + 50% ATTACK';  RunStressTest '50k-50pct'  50 $NODES 50000 }
function Option24 { PrintBanner '50K STEPS + 60% ATTACK';  RunStressTest '50k-60pct'  60 $NODES 50000 }
function Option25 { PrintBanner '50K STEPS + 70% ATTACK';  RunStressTest '50k-70pct'  70 $NODES 50000 }
function Option26 { PrintBanner '50K STEPS + 80% ATTACK';  RunStressTest '50k-80pct'  80 $NODES 50000 }
function Option27 { PrintBanner '50K STEPS + 90% ATTACK';  RunStressTest '50k-90pct'  90 $NODES 50000 }

# ── 100K STEPS ─────────────────────────────────────────────────────────────
function Option28 { PrintBanner '100K STEPS + 10% ATTACK'; RunStressTest '100k-10pct' 10 $NODES 100000 }
function Option29 { PrintBanner '100K STEPS + 20% ATTACK'; RunStressTest '100k-20pct' 20 $NODES 100000 }
function Option30 { PrintBanner '100K STEPS + 30% ATTACK'; RunStressTest '100k-30pct' 30 $NODES 100000 }
function Option31 { PrintBanner '100K STEPS + 40% ATTACK'; RunStressTest '100k-40pct' 40 $NODES 100000 }
function Option32 { PrintBanner '100K STEPS + 50% ATTACK'; RunStressTest '100k-50pct' 50 $NODES 100000 }
function Option33 { PrintBanner '100K STEPS + 60% ATTACK'; RunStressTest '100k-60pct' 60 $NODES 100000 }
function Option34 { PrintBanner '100K STEPS + 70% ATTACK'; RunStressTest '100k-70pct' 70 $NODES 100000 }
function Option35 { PrintBanner '100K STEPS + 80% ATTACK'; RunStressTest '100k-80pct' 80 $NODES 100000 }
function Option36 { PrintBanner '100K STEPS + 90% ATTACK'; RunStressTest '100k-90pct' 90 $NODES 100000 }

# ── CLEAN (0% attackers) ──────────────────────────────────────────────────
function Option40 { PrintBanner 'CLEAN — 10K STEPS (0% attackers)';  RunStressTest 'clean-10k'  0 $NODES 10000 }
function Option41 { PrintBanner 'CLEAN — 30K STEPS (0% attackers)';  RunStressTest 'clean-30k'  0 $NODES 30000 }
function Option42 { PrintBanner 'CLEAN — 50K STEPS (0% attackers)';  RunStressTest 'clean-50k'  0 $NODES 50000 }
function Option43 { PrintBanner 'CLEAN — 100K STEPS (0% attackers)'; RunStressTest 'clean-100k' 0 $NODES 100000 }

# ── CUSTOM ─────────────────────────────────────────────────────────────────
function Option50 {
    PrintBanner 'CUSTOM — Set parameters'
    Write-Host ''
    Write-Host '  Set Steps (simulation step count):' -ForegroundColor Yellow
    Write-Host '  Examples: 500, 10000, 30000, 50000, 100000, 500000' -ForegroundColor DarkGray
    Write-Host '  Steps: ' -NoNewline
    $customSteps = Read-Host
    if (-not $customSteps -or $customSteps -notmatch '^\d+$' -or [int]$customSteps -lt 1) {
        LogError 'Invalid steps — must be a positive integer'
        return
    }
    Write-Host ''
    Write-Host '  Set Attacker density (0-99%):' -ForegroundColor Yellow
    Write-Host '  0 = clean run (no attackers)' -ForegroundColor DarkGray
    Write-Host '  10 = 10% attackers ... 90 = 90% attackers' -ForegroundColor DarkGray
    Write-Host '  Density (%): ' -NoNewline
    $customPercent = Read-Host
    if (-not $customPercent -or $customPercent -notmatch '^\d+$' -or [int]$customPercent -lt 0 -or [int]$customPercent -gt 99) {
        LogError 'Invalid density — must be between 0 and 99'
        return
    }
    $customSteps = [int]$customSteps
    $customPercent = [int]$customPercent
    $testLabel = "custom-${customSteps}s-${customPercent}pct"
    if ($customPercent -eq 0) {
        PrintBanner "CUSTOM: $customSteps steps — CLEAN (0% attackers)"
    } else {
        PrintBanner "CUSTOM: $customSteps steps + $customPercent% attack"
    }
    RunStressTest $testLabel $customPercent $NODES $customSteps
}

# ============================================================================
# MENU SYSTEM
# ============================================================================

function ShowMenu {
    Write-Host ""
    Write-Host '================================================================' -ForegroundColor White
    Write-Host '=   NeuroGraph ANGP v4.3.1-FIXED — TEST SUITE A — MENU    =' -ForegroundColor White
    Write-Host '=   37 Attacker Types (T0-T36) | Behavioral Strategies     =' -ForegroundColor White
    Write-Host '=   2664 Nodes (333 shards x 8 nodes/shard)                =' -ForegroundColor White
    Write-Host '================================================================' -ForegroundColor White
    Write-Host ""
    Write-Host '  10K STEPS + ATTACKERS                                       ' -ForegroundColor Yellow
    Write-Host '     1) 10K + 10%     2) 10K + 20%     3) 10K + 30%'
    Write-Host '     4) 10K + 40%     5) 10K + 50%     6) 10K + 60%'
    Write-Host '     7) 10K + 70%     8) 10K + 80%     9) 10K + 90%'
    Write-Host ""
    Write-Host '  30K STEPS + ATTACKERS                                       ' -ForegroundColor Yellow
    Write-Host '    10) 30K + 10%    11) 30K + 20%    12) 30K + 30%'
    Write-Host '    13) 30K + 40%    14) 30K + 50%    15) 30K + 60%'
    Write-Host '    16) 30K + 70%    17) 30K + 80%    18) 30K + 90%'
    Write-Host ""
    Write-Host '  50K STEPS + ATTACKERS                                       ' -ForegroundColor Yellow
    Write-Host '    19) 50K + 10%    20) 50K + 20%    21) 50K + 30%'
    Write-Host '    22) 50K + 40%    23) 50K + 50%    24) 50K + 60%'
    Write-Host '    25) 50K + 70%    26) 50K + 80%    27) 50K + 90%'
    Write-Host ""
    Write-Host '  100K STEPS + ATTACKERS                                      ' -ForegroundColor Yellow
    Write-Host '    28) 100K + 10%   29) 100K + 20%   30) 100K + 30%'
    Write-Host '    31) 100K + 40%   32) 100K + 50%   33) 100K + 60%'
    Write-Host '    34) 100K + 70%   35) 100K + 80%   36) 100K + 90%'
    Write-Host ""
    Write-Host '  CLEAN (0% attackers — no attack simulation)                 ' -ForegroundColor Green
    Write-Host '    40) Clean 10K     41) Clean 30K     42) Clean 50K'
    Write-Host '    43) Clean 100K'
    Write-Host ""
    Write-Host '  CUSTOM                                                      ' -ForegroundColor Cyan
    Write-Host '    50) Custom — set steps + attacker density (0-99%)'
    Write-Host ""
    Write-Host '    99) Show 37 attacker types (T0-T36)'
    Write-Host '     0) Exit'
    Write-Host ""
    Write-Host 'Select option [0-50, 99]: ' -NoNewline
}

# ============================================================================
# MAIN
# ============================================================================

PrintHeader
EnsureBinary | Out-Null
Write-Host '  Binary ready.' -ForegroundColor Green
Write-Host ""

# If argument given on command line, run directly
if ($args.Count -gt 0) {
    switch ($args[0]) {
        '1'  { Option1; break }
        '2'  { Option2; break }
        '3'  { Option3; break }
        '4'  { Option4; break }
        '5'  { Option5; break }
        '6'  { Option6; break }
        '7'  { Option7; break }
        '8'  { Option8; break }
        '9'  { Option9; break }
        '10' { Option10; break }
        '11' { Option11; break }
        '12' { Option12; break }
        '13' { Option13; break }
        '14' { Option14; break }
        '15' { Option15; break }
        '16' { Option16; break }
        '17' { Option17; break }
        '18' { Option18; break }
        '19' { Option19; break }
        '20' { Option20; break }
        '21' { Option21; break }
        '22' { Option22; break }
        '23' { Option23; break }
        '24' { Option24; break }
        '25' { Option25; break }
        '26' { Option26; break }
        '27' { Option27; break }
        '28' { Option28; break }
        '29' { Option29; break }
        '30' { Option30; break }
        '31' { Option31; break }
        '32' { Option32; break }
        '33' { Option33; break }
        '34' { Option34; break }
        '35' { Option35; break }
        '36' { Option36; break }
        '40' { Option40; break }
        '41' { Option41; break }
        '42' { Option42; break }
        '43' { Option43; break }
        '50' { Option50; break }
        '99' { PrintAttackerTypes; break }
        default { LogError ("Invalid option: {0}" -f $args[0]); ShowMenu }
    }
    return
}

# Interactive mode
while ($true) {
    ShowMenu
    $choice = Read-Host

    switch ($choice) {
        '0'  { LogInfo 'Exiting...'; exit 0 }
        '1'  { Option1 }
        '2'  { Option2 }
        '3'  { Option3 }
        '4'  { Option4 }
        '5'  { Option5 }
        '6'  { Option6 }
        '7'  { Option7 }
        '8'  { Option8 }
        '9'  { Option9 }
        '10' { Option10 }
        '11' { Option11 }
        '12' { Option12 }
        '13' { Option13 }
        '14' { Option14 }
        '15' { Option15 }
        '16' { Option16 }
        '17' { Option17 }
        '18' { Option18 }
        '19' { Option19 }
        '20' { Option20 }
        '21' { Option21 }
        '22' { Option22 }
        '23' { Option23 }
        '24' { Option24 }
        '25' { Option25 }
        '26' { Option26 }
        '27' { Option27 }
        '28' { Option28 }
        '29' { Option29 }
        '30' { Option30 }
        '31' { Option31 }
        '32' { Option32 }
        '33' { Option33 }
        '34' { Option34 }
        '35' { Option35 }
        '36' { Option36 }
        '40' { Option40 }
        '41' { Option41 }
        '42' { Option42 }
        '43' { Option43 }
        '50' { Option50 }
        '99' { PrintAttackerTypes }
        default { LogError ("Invalid option: {0}" -f $choice) }
    }

    Write-Host ""
    Read-Host 'Press Enter to continue...'
}
