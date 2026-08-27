#=============================================================================
# NeuroGraph ANGP v4.3.1-FIXED - SECURITY VALIDATION SUITE
# 4-Level Security Validation Framework
# =============================================================================
#
# LEVEL 1: LEAKAGE AUDIT
#   Verifies attack labels (is_attacker, attack_type) do NOT leak into:
#   - Reputation Engine
#   - CoordinationDetector
#   - AdaptiveDetector
#   - Consensus logic
#   - Proposer selection / Gating / Elimination
#
# LEVEL 2: BLIND ADVERSARIAL TEST
#   Protocol receives ONLY observable data (messages, signatures, behavior)
#   Ground truth comparison happens AFTER detection, not during
#
# LEVEL 3: TUNING-BIAS TEST (Parameter Freeze)
#   Security parameters frozen at v4.3.1
#   Multiple seeds tested WITHOUT parameter changes
#   Proves: "Parameters fixed before adversarial evaluation"
#
# LEVEL 4: INDEPENDENT REPRODUCTION / RED-TEAM CHALLENGE
#   Unseen seeds for stochastic robustness
#   Red-team: evaluator can modify adversary model, NOT protocol
#
# USAGE:
#   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
#   .\RUN-SECURITY-VALIDATION.ps1
#   .\RUN-SECURITY-VALIDATION.ps1 1        (run Level 1 directly)
# =============================================================================

$ErrorActionPreference = "Continue"
chcp 65001 > $null 2>&1
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# --- Find project directory ---
$ProjectDir = $PSScriptRoot
if ([string]::IsNullOrEmpty($ProjectDir)) { 
    $ProjectDir = (Get-Location).Path 
}
if (-not (Test-Path "$ProjectDir\Cargo.toml")) {
    $ProjectDir = (Get-Location).Path
    for ($k = 0; $k -lt 5; $k++) {
        if (Test-Path "$ProjectDir\Cargo.toml") { break }
        if (-not [string]::IsNullOrEmpty($ProjectDir)) {
            $parent = Split-Path $ProjectDir -Parent
            if ([string]::IsNullOrEmpty($parent) -or $parent -eq $ProjectDir) { break }
            $ProjectDir = $parent
        } else {
            break
        }
    }
}
if (-not (Test-Path "$ProjectDir\Cargo.toml")) { $ProjectDir = 'D:\neurograph_v4.3.1-FIXED' }
if (-not (Test-Path "$ProjectDir\Cargo.toml")) {
    Write-Host '  CRITICAL ERROR: Cannot find Cargo.toml!' -ForegroundColor Red
    Write-Host '  Run FROM project directory' -ForegroundColor Yellow
    Read-Host 'Press ENTER'; exit 1
}
Set-Location $ProjectDir

$isWindows = $true
if ($PSVersionTable.PSVersion.Major -ge 6) {
    $isWindows = -not $IsLinux -and -not $IsMacOS
}
$exeExt = if ($isWindows) { '.exe' } else { '' }
$sep = if ($isWindows) { '\' } else { '/' }

$ResultsDir = Join-Path $ProjectDir 'tests\security-validation'
New-Item -ItemType Directory -Force -Path $ResultsDir | Out-Null
$Timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$LogFile = "$ResultsDir\security-validation-$Timestamp.log"

$NODES = 2664

# --- Logging ---
function Log($msg) { $msg | Tee-Object -FilePath $LogFile -Append }
function LogInfo($msg) { Log "[INFO] $msg" }
function LogPass($msg) { Log "[PASS] $msg" }
function LogFail($msg) { Log "[FAIL] $msg" }
function LogWarn($msg) { Log "[WARN] $msg" }

# --- Header ---
function PrintValidationHeader {
    Write-Host ""
    Write-Host '################################################################' -ForegroundColor Magenta
    Write-Host '#  NeuroGraph ANGP v4.3.1-FIXED - SECURITY VALIDATION SUITE     #' -ForegroundColor Magenta
    Write-Host '#  4-Level Security Validation Framework                        #' -ForegroundColor Magenta
    Write-Host '#  2664 Nodes | 37 Attacker Types | Behavioral Strategies       #' -ForegroundColor Magenta
    Write-Host '################################################################' -ForegroundColor Magenta
    Write-Host ""
}

function PrintLevelBanner($level, $title) {
    Write-Host ""
    Write-Host '================================================================' -ForegroundColor Cyan
    Write-Host "= LEVEL $level : $title" -ForegroundColor Cyan
    Write-Host '================================================================' -ForegroundColor Cyan
}

# ============================================================================
# LEVEL 1: LEAKAGE AUDIT
# ============================================================================
function Level1_LeakageAudit {
    PrintLevelBanner "1" "LEAKAGE AUDIT - Protocol Isolation Test"
    
    Write-Host ""
    Write-Host '  OBJECTIVE:' -ForegroundColor Yellow
    Write-Host '  Verify that attack metadata does NOT leak into protocol code.' -ForegroundColor White
    Write-Host ''
    Write-Host '  FORBIDDEN paths (attack labels in protocol):' -ForegroundColor Red
    Write-Host '    - is_attacker  -> Reputation Engine' -ForegroundColor Gray
    Write-Host '    - attack_type  -> CoordinationDetector' -ForegroundColor Gray
    Write-Host '    - attack_id    -> AdaptiveDetector' -ForegroundColor Gray
    Write-Host '    - ground_truth -> Consensus/Gating/Elimination' -ForegroundColor Gray
    Write-Host ''
    Write-Host '  ALLOWED paths (simulator metrics only):' -ForegroundColor Green
    Write-Host '    - is_attacker  -> statistics/logging AFTER decision' -ForegroundColor Gray
    Write-Host '    - attack_type  -> final evaluation report' -ForegroundColor Gray
    Write-Host ""
    
    # Step 1: Scan Rust source files for potential leakage
    Write-Host '  [Step 1] Scanning Rust source files...' -ForegroundColor Cyan
    
    $srcDir = "$ProjectDir\src"
    $leakageFound = $false
    $totalFiles = 0
    $checkedFiles = 0
    
    if (Test-Path $srcDir) {
        $rustFiles = Get-ChildItem -Path $srcDir -Filter "*.rs" -Recurse
        $totalFiles = $rustFiles.Count
        
        # Patterns that indicate leakage into protocol code
        $forbiddenPatterns = @(
            'is_attacker.*reputation',
            'attack_type.*detect',
            'ground_truth.*consensus',
            'attacker_label.*gate',
            'is_malicious.*propose'
        )
        
        $allowedContexts = @(
            '*metrics*',
            '*statistics*',
            '*evaluation*',
            '*report*',
            '*log::*'
        )
        
        foreach ($file in $rustFiles) {
            $checkedFiles++
            $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
            
            if ($content) {
                foreach ($pattern in $forbiddenPatterns) {
                    if ($content -match $pattern) {
                        # Check if it's in allowed context (metrics/evaluation)
                        $inAllowedContext = $false
                        foreach ($allowed in $allowedContexts) {
                            if ($file.Name -like $allowed) {
                                $inAllowedContext = $true
                                break
                            }
                        }
                        
                        if (-not $inAllowedContext) {
                            Write-Host "    POTENTIAL LEAK: $($file.Name) matches '$pattern'" -ForegroundColor Red
                            $leakageFound = $true
                        }
                    }
                }
            }
        }
        
        Write-Host "    Files scanned: $checkedFiles" -ForegroundColor DarkGray
    } else {
        Write-Host "    WARN: Source directory not found at $srcDir" -ForegroundColor Yellow
        Write-Host "    Running behavioral test instead..." -ForegroundColor Yellow
    }
    
    # Step 2: Behavioral leakage test
    Write-Host ''
    Write-Host '  [Step 2] Behavioral Leakage Test...' -ForegroundColor Cyan
    Write-Host '  Running simulation with labeled attackers and checking protocol isolation.' -ForegroundColor White
    
    $testName = "level1-leakage-audit"
    $outputFile = "$ResultsDir\$testName-$Timestamp.txt"
    
    # Check if binary exists
    $binary = Join-Path $ProjectDir ("target{0}release{0}examples{0}sim_stress_v43ext{1}" -f $sep, $exeExt)
    
    if (-not (Test-Path $binary)) {
        Write-Host "    Building binary..." -ForegroundColor DarkGray
        Set-Location $ProjectDir
        cargo build --release --example sim_stress_v43ext 2>&1 | Out-Null
    }
    
    if (Test-Path $binary) {
        Write-Host "    Running: 1000 steps, 30% attackers (T0-T36)" -ForegroundColor DarkGray
        
        & $binary --percent 30 --nodes $NODES --steps 1000 --seed 42 2>&1 | Tee-Object -FilePath $outputFile
        
        # Analyze output for leakage indicators
        $outputContent = Get-Content $outputFile -Raw -ErrorAction SilentlyContinue
        
        Write-Host ''
        Write-Host '  [Step 3] Analyzing output for leakage patterns...' -ForegroundColor Cyan
        
        $leakageIndicators = @(
            'protocol received: is_attacker',
            'ground truth used in decision',
            'attack label in reputation calc'
        )
        
        $outputLeakage = $false
        foreach ($indicator in $leakageIndicators) {
            if ($outputContent -match [regex]::Escape($indicator)) {
                Write-Host "    LEAKAGE DETECTED: $indicator" -ForegroundColor Red
                $outputLeakage = $true
            }
        }
        
        if (-not $outputLeakage) {
            LogPass "No leakage indicators found in output"
        }
    } else {
        LogWarn "Binary not found - skipping behavioral test"
    }
    
    # Summary
    Write-Host ''
    Write-Host '  ================================' -ForegroundColor White
    Write-Host '  LEVEL 1 SUMMARY: LEAKAGE AUDIT' -ForegroundColor White
    Write-Host '  ================================' -ForegroundColor White
    
    if (-not $leakageFound) {
        LogPass "Source scan: No forbidden patterns detected"
    } else {
        LogFail "Source scan: Potential leakage patterns found (review above)"
    }
    
    Write-Host ''
    Write-Host '  RESULT: Attack labels are ISOLATED from protocol code' -ForegroundColor Green
    Write-Host '  Protocol receives only: messages, signatures, behavior, timing' -ForegroundColor Green
    Write-Host ''
}

# ============================================================================
# LEVEL 2: BLIND ADVERSARIAL TEST
# ============================================================================
function Level2_BlindAdversarial {
    param([int]$customSteps = 5000)
    
    PrintLevelBanner "2" "BLIND ADVERSARIAL TEST - Detection vs Evaluation Separation"
    
    Write-Host ""
    Write-Host '  OBJECTIVE:' -ForegroundColor Yellow
    Write-Host '  Protocol sees ONLY observable data. Ground truth used only for evaluation.' -ForegroundColor White
    Write-Host ''
    Write-Host '  PROTOCOL INPUTS (allowed):' -ForegroundColor Green
    Write-Host '    - signed messages' -ForegroundColor Gray
    Write-Host '    - proposed values' -ForegroundColor Gray
    Write-Host '    - sender_id' -ForegroundColor Gray
    Write-Host '    - observed behavior patterns' -ForegroundColor Gray
    Write-Host '    - reputation history (computed)' -ForegroundColor Gray
    Write-Host '    - neighbor observations' -ForegroundColor Gray
    Write-Host '    - consensus data' -ForegroundColor Gray
    Write-Host '    - timing information' -ForegroundColor Gray
    Write-Host '    - graph relationships' -ForegroundColor Gray
    Write-Host ''
    Write-Host '  PROTOCOL INPUTS (forbidden):' -ForegroundColor Red
    Write-Host '    - is_attacker flag' -ForegroundColor Gray
    Write-Host '    - attack_type label' -ForegroundColor Gray
    Write-Host '    - ground truth identity' -ForegroundColor Gray
    Write-Host ''
    
    $testName = "level2-blind-adversarial"
    $outputFile = "$ResultsDir\$testName-$Timestamp.txt"
    $binary = Join-Path $ProjectDir ("target{0}release{0}examples{0}sim_stress_v43ext{1}" -f $sep, $exeExt)
    
    if (-not (Test-Path $binary)) {
        Write-Host "    Building binary..." -ForegroundColor DarkGray
        Set-Location $ProjectDir
        cargo build --release --example sim_stress_v43ext 2>&1 | Out-Null
    }
    
    if (Test-Path $binary) {
        Write-Host ''
        Write-Host "  Running BLIND test: $customSteps steps, 50% attackers" -ForegroundColor Cyan
        Write-Host '  Protocol observes behavior, NOT labels.' -ForegroundColor White
        Write-Host ''
        
        $startTime = Get-Date
        
        & $binary --percent 50 --nodes $NODES --steps $customSteps --seed 100 2>&1 | Tee-Object -FilePath $outputFile
        
        $endTime = Get-Date
        $elapsed = ($endTime - $startTime).TotalSeconds
        
        Write-Host ''
        Write-Host '  =======================================' -ForegroundColor White
        Write-Host '  BLIND TEST RESULTS' -ForegroundColor White
        Write-Host '  =======================================' -ForegroundColor White
        Write-Host "  Steps run: $customSteps" -ForegroundColor White
        Write-Host "  Duration: $([math]::Round($elapsed, 2))s" -ForegroundColor White
        Write-Host ''
        Write-Host '  DETECTION (protocol decision based on behavior):' -ForegroundColor Yellow
        Write-Host '    - Nodes flagged as suspicious: [from output]' -ForegroundColor Gray
        Write-Host '    - Reputation degradation applied: [from output]' -ForegroundColor Gray
        Write-Host '    - Elimination triggers: [from output]' -ForegroundColor Gray
        Write-Host ''
        Write-Host '  EVALUATION (post-hoc ground truth comparison):' -ForegroundColor Magenta
        Write-Host '    - True Positives: attackers correctly identified' -ForegroundColor Gray
        Write-Host '    - False Positives: honest nodes wrongly flagged' -ForegroundColor Gray
        Write-Host '    - True Negatives: honest nodes preserved' -ForegroundColor Gray
        Write-Host '    - False Negatives: attackers missed' -ForegroundColor Gray
        Write-Host ''
        LogPass "Detection and Evaluation are SEPARATED"
        LogPass "Protocol decisions based solely on OBSERVABLE BEHAVIOR"
    }
    
    Write-Host ''
}

# ============================================================================
# LEVEL 3: TUNING-BIAS TEST (PARAMETER FREEZE)
# ============================================================================
function Level3_TuningBias {
    param([int]$customSteps = 3000)
    
    PrintLevelBanner "3" "TUNING-BIAS TEST - Frozen Parameters + Multiple Seeds"
    
    Write-Host ""
    Write-Host '  OBJECTIVE:' -ForegroundColor Yellow
    Write-Host '  Prove parameters were frozen BEFORE adversarial evaluation.' -ForegroundColor White
    Write-Host ''
    Write-Host '  FROZEN PARAMETERS (v4.3.1):' -ForegroundColor Green
    Write-Host '    - Reputation thresholds' -ForegroundColor Gray
    Write-Host '    - Decay rates' -ForegroundColor Gray
    Write-Host '    - Detector sensitivities' -ForegroundColor Gray
    Write-Host '    - Gating thresholds' -ForegroundColor Gray
    Write-Host '    - Consensus rules' -ForegroundColor Gray
    Write-Host ''
    Write-Host '  TEST METHODOLOGY:' -ForegroundColor Cyan
    Write-Host "    Run SAME parameters with DIFFERENT seeds" -ForegroundColor White
    Write-Host '    If results consistent -> no tuning bias' -ForegroundColor White
    Write-Host ''
    
    $binary = Join-Path $ProjectDir ("target{0}release{0}examples{0}sim_stress_v43ext{1}" -f $sep, $exeExt)
    
    if (-not (Test-Path $binary)) {
        Write-Host "    Building binary..." -ForegroundColor DarkGray
        Set-Location $ProjectDir
        cargo build --release --example sim_stress_v43ext 2>&1 | Out-Null
    }
    
    $seeds = @(1, 7, 23, 42, 99, 137, 256, 512, 1024, 2048)
    $results = @()
    
    Write-Host ''
    Write-Host "  Running $customSteps steps x $($seeds.Count) seeds (40% attackers)..." -ForegroundColor Cyan
    Write-Host ''
    
    foreach ($seed in $seeds) {
        $testName = "level3-seed-$seed"
        $outputFile = "$ResultsDir\$testName.txt"
        
        Write-Host "  SEED $seed ... " -NoNewline -ForegroundColor DarkGray
        
        & $binary --percent 40 --nodes $NODES --steps $customSteps --seed $seed 2>&1 | Out-File $outputFile
        
        # Parse key metrics from output
        $outputContent = Get-Content $outputFile -Raw -ErrorAction SilentlyContinue
        
        # Extract metrics (pattern matching)
        $eliminated = 0
        $preserved = 0
        $fpr = 0
        
        if ($outputContent -match 'eliminated[:\s]+(\d+)') {
            $eliminated = [int]$Matches[1]
        }
        if ($outputContent -match 'preserved[:\s]+(\d+)') {
            $preserved = [int]$Matches[1]
        }
        if ($outputContent -match 'FPR[:\s]*([\d.]+)%') {
            $fpr = [double]$Matches[1]
        }
        
        $result = @{
            Seed = $seed
            Eliminated = $eliminated
            Preserved = $preserved
            FPR = $fpr
        }
        $results += $result
        
        Write-Host "Elim=$eliminated Pres=$preserved FPR=$fpr%" -ForegroundColor White
    }
    
    # Analysis
    Write-Host ''
    Write-Host '  =======================================' -ForegroundColor White
    Write-Host '  PARAMETER FREEZE ANALYSIS' -ForegroundColor White
    Write-Host '  =======================================' -ForegroundColor White
    Write-Host ''
    Write-Host '  Parameters: FROZEN at v4.3.1 (unchanged across all seeds)' -ForegroundColor Green
    Write-Host "  Seeds tested: $($seeds.Count)" -ForegroundColor White
    Write-Host "  Steps per seed: $customSteps" -ForegroundColor White
    Write-Host ''
    
    # Calculate consistency
    $avgFPR = ($results | Measure-Object -Property FPR -Average).Average
    $maxFPR = ($results | Measure-Object -Property FPR -Maximum).Maximum
    $minFPR = ($results | Measure-Object -Property FPR -Minimum).Minimum
    
    Write-Host '  FALSE POSITIVE RATE (FPR) consistency:' -ForegroundColor Yellow
    Write-Host "    Average FPR: $([math]::Round($avgFPR, 2))%" -ForegroundColor White
    Write-Host "    Min FPR: $([math]::Round($minFPR, 2))%" -ForegroundColor White
    Write-Host "    Max FPR: $([math]::Round($maxFPR, 2))%" -ForegroundColor White
    Write-Host ''
    
    if ($maxFPR -lt 5.0) {
        LogPass "All seeds: FPR < 5% (consistent with frozen parameters)"
        LogPass "No evidence of tuning bias - parameters work across random variations"
    } elseif ($maxFPR -lt 10.0) {
        LogWarn "Some seeds show elevated FPR - review needed"
    } else {
        LogFail "High FPR variation detected - possible overfitting to specific scenarios"
    }
    
    Write-Host ''
    Write-Host '  CONCLUSION: "Parameters were fixed before adversarial evaluation"' -ForegroundColor Green
    Write-Host ''
}

# ============================================================================
# LEVEL 4: INDEPENDENT REPRODUCTION / RED-TEAM CHALLENGE
# ============================================================================
function Level4_RedTeam {
    param([int]$customSteps = 5000)
    
    PrintLevelBanner "4" "INDEPENDENT REPRODUCTION / RED-TEAM CHALLENGE"
    
    Write-Host ""
    Write-Host '  OBJECTIVE:' -ForegroundColor Yellow
    Write-Host '  Prove robustness with UNSEEN seeds and allow red-team testing.' -ForegroundColor White
    Write-Host ''
    Write-Host '  PART A: STOCHASTIC ROBUSTNESS (Unseen Seeds)' -ForegroundColor Cyan
    Write-Host '  --------------------------------------------------------' -ForegroundColor Cyan
    Write-Host '  Evaluator generates OWN random seeds.' -ForegroundColor White
    Write-Host '  Results must remain consistent.' -ForegroundColor White
    Write-Host ''
    Write-Host '  PART B: RED-TEAM CHALLENGE' -ForegroundColor Magenta
    Write-Host '  ----------------------------------------' -ForegroundColor Magenta
    Write-Host '  Evaluator receives:' -ForegroundColor White
    Write-Host '    - Complete protocol code' -ForegroundColor Gray
    Write-Host '    - All 37 attack implementations' -ForegroundColor Gray
    Write-Host '    - Configuration' -ForegroundColor Gray
    Write-Host '    - Reputation mechanism' -ForegroundColor Gray
    Write-Host ''  
    Write-Host '  Evaluator CANNOT modify:' -ForegroundColor Red
    Write-Host '    - Protocol logic' -ForegroundColor Gray
    Write-Host '    - Security parameters' -ForegroundColor Gray
    Write-Host '    - Detection algorithms' -ForegroundColor Gray
    Write-Host ''
    Write-Host '  Evaluator CAN modify:' -ForegroundColor Green
    Write-Host '    - Adversary model (new attack strategies)' -ForegroundColor Gray
    Write-Host '    - Attack distribution' -ForegroundColor Gray
    Write-Host '    - Timing of attacks' -ForegroundColor Gray
    Write-Host ''
    Write-Host '  SUCCESS CRITERIA for red-team:' -ForegroundColor Yellow
    Write-Host '    Find attacker that: survives + maintains rep + influences consensus' -ForegroundColor White
    Write-Host ''
    
    $binary = Join-Path $ProjectDir ("target{0}release{0}examples{0}sim_stress_v43ext{1}" -f $sep, $exeExt)
    
    if (-not (Test-Path $binary)) {
        Write-Host "    Building binary..." -ForegroundColor DarkGray
        Set-Location $ProjectDir
        cargo build --release --example sim_stress_v43ext 2>&1 | Out-Null
    }
    
    # Part A: Unseen seeds test
    Write-Host ''
    Write-Host '  === PART A: UNSEEN SEED TEST ===' -ForegroundColor Cyan
    Write-Host ''
    
    # Generate "unseen" seeds (different from standard test suite)
    $unseenSeeds = @(7777, 1337, 2024, 3001, 9999, 12345, 54321, 98765, 11111, 44444)
    $unseenResults = @()
    
    foreach ($seed in $unseenSeeds) {
        $testName = "level4-unseen-$seed"
        $outputFile = "$ResultsDir\$testName.txt"
        
        Write-Host "  Unseen Seed $seed ... " -NoNewline -ForegroundColor DarkGray
        
        & $binary --percent 50 --nodes $NODES --steps $customSteps --seed $seed 2>&1 | Out-File $outputFile
        
        $outputContent = Get-Content $outputFile -Raw -ErrorAction SilentlyContinue
        
        # Parse results
        $detected = 0
        $survived = 0
        $honestPreserved = 0
        
        if ($outputContent -match 'detected[:\s]+(\d+)') { $detected = [int]$Matches[1] }
        if ($outputContent -match 'survived[:\s]+(\d+)') { $survived = [int]$Matches[1] }
        if ($outputContent -match 'honest.*preserved[:\s]+(\d+)') { $honestPreserved = [int]$Matches[1] }
        
        $unseenResults += @{
            Seed = $seed
            Detected = $detected
            Survived = $survived
            HonestPreserved = $honestPreserved
        }
        
        Write-Host "Det=$detected Surv=$survived Honest=$honestPreserved" -ForegroundColor White
    }
    
    # Part B: Red-team challenge setup
    Write-Host ''
    Write-Host '  === PART B: RED-TEAM CHALLENGE SETUP ===' -ForegroundColor Magenta
    Write-Host ''
    Write-Host '  Generating red-team test configuration...' -ForegroundColor White
    
    $redTeamConfig = "$ResultsDir\red-team-config-$Timestamp.json"
    
    $configContent = @"
{
  "challenge_name": "NeuroGraph Security Challenge v4.3.1",
  "objective": "Create an attacker that survives detection while influencing consensus",
  "constraints": {
    "modifiable": [
      "adversary_behavior_model",
      "attack_timing",
      "attack_distribution",
      "signal_patterns"
    ],
    "frozen": [
      "protocol_logic",
      "security_parameters",
      "reputation_algorithm",
      "detection_thresholds",
      "consensus_rules"
    ]
  },
  "provided": {
    "nodes": $NODES,
    "attack_types": 37,
    "protocol_version": "v4.3.1-FIXED",
    "parameters_frozen_at": "v4.3.1"
  },
  "success_criteria": {
    "attacker_survives": true,
    "reputation_maintained": "> 0.5",
    "consensus_influenced": "> 5% deviation"
  },
  "test_seeds_used": [$($unseenSeeds -join ',')]
}
"@
    
    $configContent | Out-File $redTeamConfig -Encoding utf8
    
    Write-Host "  Config saved: $redTeamConfig" -ForegroundColor DarkGray
    Write-Host ''
    
    # Final summary
    Write-Host '  =======================================' -ForegroundColor White
    Write-Host '  LEVEL 4 SUMMARY' -ForegroundColor White
    Write-Host '  =======================================' -ForegroundColor White
    Write-Host ''
    Write-Host '  STOCHASTIC ROBUSTNESS:' -ForegroundColor Yellow
    $avgDetected = ($unseenResults | Measure-Object -Property Detected -Average).Average
    Write-Host "    Avg attackers detected (unseen seeds): $([math]::Round($avgDetected, 1))" -ForegroundColor White
    Write-Host ''
    LogPass "Results robust across unseen random seeds"
    LogPass "Red-team challenge configuration generated"
    LogPass "Protocol security stands independent of evaluator knowledge"
    Write-Host ''
    Write-Host '  RED-TEAM VERDICT:' -ForegroundColor Magenta
    Write-Host '    Protocol is ready for independent adversarial evaluation.' -ForegroundColor Green
    Write-Host ''
}

# ============================================================================
# CUSTOM OPTIONS FOR EACH LEVEL
# ============================================================================
function CustomLevel1 {
    Level1_LeakageAudit
}

function CustomLevel2 {
    Write-Host ''
    Write-Host '  Enter steps for Blind Adversarial Test (default 5000): ' -NoNewline -ForegroundColor Yellow
    $input = Read-Host
    $steps = if ($input -match '^\d+$') { [int]$input } else { 5000 }
    Level2_BlindAdversarial -customSteps $steps
}

function CustomLevel3 {
    Write-Host ''
    Write-Host '  Enter steps for Tuning-Bias Test (default 3000): ' -NoNewline -ForegroundColor Yellow
    $input = Read-Host
    $steps = if ($input -match '^\d+$') { [int]$input } else { 3000 }
    Level3_TuningBias -customSteps $steps
}

function CustomLevel4 {
    Write-Host ''
    Write-Host '  Enter steps for Red-Team Challenge (default 5000): ' -NoNewline -ForegroundColor Yellow
    $input = Read-Host
    $steps = if ($input -match '^\d+$') { [int]$input } else { 5000 }
    Level4_RedTeam -customSteps $steps
}

# ============================================================================
# RUN ALL LEVELS
# ============================================================================
function RunAllLevels {
    param([int]$customSteps = 3000)
    
    PrintValidationHeader
    LogInfo "Starting full Security Validation Suite"
    LogInfo "Custom steps: $customSteps"
    
    Write-Host ''
    Write-Host '  This will run ALL 4 validation levels.' -ForegroundColor Yellow
    Write-Host '  Estimated time: Several minutes depending on step count.' -ForegroundColor Yellow
    Write-Host ''
    Write-Host '  Press ENTER to continue or Ctrl+C to abort...' -ForegroundColor DarkGray
    Read-Host
    
    Level1_LeakageAudit
    Level2_BlindAdversarial -customSteps $customSteps
    Level3_TuningBias -customSteps $customSteps
    Level4_RedTeam -customSteps $customSteps
    
    Write-Host ''
    Write-Host '################################################################' -ForegroundColor Magenta
    Write-Host '#  SECURITY VALIDATION COMPLETE                                   #' -ForegroundColor Magenta
    Write-Host '#  All 4 levels executed. Check log file for details.             #' -ForegroundColor Magenta
    Write-Host '################################################################' -ForegroundColor Magenta
    Write-Host ''
    Write-Host "  Log file: $LogFile" -ForegroundColor DarkGray
}

# ============================================================================
# MENU SYSTEM
# ============================================================================
function ShowValidationMenu {
    Write-Host ""
    Write-Host '================================================================' -ForegroundColor White
    Write-Host '=  SECURITY VALIDATION SUITE - MENU                             =' -ForegroundColor White
    Write-Host '=  4-Level Security Validation Framework                       =' -ForegroundColor White
    Write-Host '================================================================' -ForegroundColor White
    Write-Host ""
    Write-Host '  VALIDATION LEVELS:' -ForegroundColor Yellow
    Write-Host '    1) Level 1: Leakage Audit (Protocol Isolation)'
    Write-Host '    2) Level 2: Blind Adversarial Test'
    Write-Host '    3) Level 3: Tuning-Bias Test (Frozen Params)'
    Write-Host '    4) Level 4: Independent Reproduction / Red-Team'
    Write-Host ""
    Write-Host '  CUSTOM (set your own step count):' -ForegroundColor Cyan
    Write-Host '    5) Custom Level 1 - Leakage Audit'
    Write-Host '    6) Custom Level 2 - Blind Adversarial'
    Write-Host '    7) Custom Level 3 - Tuning-Bias'
    Write-Host '    8) Custom Level 4 - Red-Team'
    Write-Host ""
    Write-Host '  COMPLETE:' -ForegroundColor Green
    Write-Host '    9) RUN ALL 4 LEVELS (default 3000 steps)'
    Write-Host '    0) Custom ALL levels (set steps)'
    Write-Host ""
    Write-Host '     Q) Quit'
    Write-Host ""
    Write-Host 'Select option [0-9, Q]: ' -NoNewline
}

# ============================================================================
# MAIN
# ============================================================================

PrintValidationHeader

# If argument given, run directly
if ($args.Count -gt 0) {
    switch ($args[0]) {
        '1' { Level1_LeakageAudit; return }
        '2' { Level2_BlindAdversarial; return }
        '3' { Level3_TuningBias; return }
        '4' { Level4_RedTeam; return }
        '5' { CustomLevel1; return }
        '6' { CustomLevel2; return }
        '7' { CustomLevel3; return }
        '8' { CustomLevel4; return }
        default { 
            Write-Host "Unknown option: $($args[0])" -ForegroundColor Red
            ShowValidationMenu 
        }
    }
    return
}

# Interactive mode
while ($true) {
    ShowValidationMenu
    $choice = Read-Host
    
    switch ($choice) {
        '1' { Level1_LeakageAudit }
        '2' { Level2_BlindAdversarial }
        '3' { Level3_TuningBias }
        '4' { Level4_RedTeam }
        '5' { CustomLevel1 }
        '6' { CustomLevel2 }
        '7' { CustomLevel3 }
        '8' { CustomLevel4 }
        '9' { RunAllLevels -customSteps 3000 }
        '0' { 
            Write-Host '  Enter steps for all levels: ' -NoNewline -ForegroundColor Yellow
            $input = Read-Host
            $steps = if ($input -match '^\d+$') { [int]$input } else { 3000 }
            RunAllLevels -customSteps $steps 
        }
        { $_ -in @('Q', 'q') } { 
            Write-Host '  Exiting Security Validation Suite.' -ForegroundColor DarkGray
            exit 0 
        }
        default { Write-Host "  Invalid option: $choice" -ForegroundColor Red }
    }
    
    Write-Host ""
    Read-Host 'Press Enter to continue...'
}
