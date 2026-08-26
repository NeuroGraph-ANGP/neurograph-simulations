#=============================================================================
# NeuroGraph ANGP v4.3.1-FIXED - TEST SUITE A
# 2664 Nodes | 37 Attacker Types | PowerShell
# =============================================================================

$ErrorActionPreference = "Continue"
chcp 65001 > $null 2>&1

$ProjectDir = $PSScriptRoot
if (-not (Test-Path "$ProjectDir\Cargo.toml")) {
    $ProjectDir = (Get-Location).Path
}
if (-not (Test-Path "$ProjectDir\Cargo.toml")) { 
    Write-Host "ERROR: Cannot find Cargo.toml!" -ForegroundColor Red 
    Read-Host "Press ENTER"; exit 1 
}
Set-Location $ProjectDir

$ResultsDir = Join-Path $ProjectDir "tests\results-a"
New-Item -ItemType Directory -Force -Path $ResultsDir | Out-Null
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$LogFile = "$ResultsDir\test-suite-a-$Timestamp.log"
$NODES = 2664

function Log($msg) { $msg | Tee-Object -FilePath $LogFile -Append }
function LogInfo($msg) { Log "[INFO] $msg" }
function LogError($msg) { Log "[ERROR] $msg" }

function PrintHeader {
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "= NeuroGraph ANGP v4.3.1-FIXED - TEST SUITE A            =" -ForegroundColor Cyan
    Write-Host "= 2664 Nodes | 37 Attacker Types (T0-T36)              =" -ForegroundColor Cyan
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""
}

function PrintBanner($title) {
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "= $title" -ForegroundColor Cyan
    Write-Host "================================================================" -ForegroundColor Cyan
}

function EnsureBinary {
    Write-Host "[INFO] Checking binary..." -ForegroundColor DarkGray
    Set-Location $ProjectDir
    cargo build --release --example sim_stress_v43ext 2>&1 | Tee-Object -FilePath $LogFile
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ERROR] Build failed!" -ForegroundColor Red
        exit 1
    }
    Write-Host "[OK] Binary ready." -ForegroundColor Green
}

function RunStressTest($testName, $percent, $nodes, $steps) {
    $outputFile = "$ResultsDir\$testName-$Timestamp.txt"
    PrintBanner "Running: $testName"
    LogInfo "Params: percent=$percent nodes=$nodes steps=$steps"
    
    EnsureBinary
    $binary = Join-Path $ProjectDir "target\release\examples\sim_stress_v43ext.exe"
    
    & $binary --percent $percent --nodes $nodes --steps $steps 2>&1 | Tee-Object -FilePath $outputFile
    
    LogInfo "Test completed"
}

# Option 50 - Custom
function Option50 {
    PrintBanner "CUSTOM - Set parameters"
    Write-Host ""
    Write-Host "  Set Steps:" -ForegroundColor Yellow
    Write-Host "  Examples: 500, 10000, 30000, 50000, 100000" -ForegroundColor DarkGray
    Write-Host "  Steps: " -NoNewline
    $customSteps = Read-Host
    if (-not $customSteps -or $customSteps -notmatch "^\d+$" -or [int]$customSteps -lt 1) {
        LogError "Invalid steps"
        return
    }
    
    Write-Host ""
    Write-Host "  Set Attacker density (0-99):" -ForegroundColor Yellow
    Write-Host "  Density: " -NoNewline
    $customPercent = Read-Host
    if (-not $customPercent -or $customPercent -notmatch "^\d+$" -or [int]$customPercent -lt 0 -or [int]$customPercent -gt 99) {
        LogError "Invalid density"
        return
    }
    
    $customSteps = [int]$customSteps
    $customPercent = [int]$customPercent
    RunStressTest "custom-${customSteps}s-${customPercent}pct" $customPercent $NODES $customSteps
}

# Show attacker types
function PrintAttackerTypes {
    Write-Host ""
    Write-Host "  37 ATTACKER TYPES (T0-T36):" -ForegroundColor Yellow
    Write-Host "  T0=Random T1=Mimicry300 T2=Mimicry500 T3=Adaptive-RepAware" -ForegroundColor Gray
    Write-Host "  ... (full list in header)" -ForegroundColor DarkGray
    Write-Host ""
}

# Menu
function ShowMenu {
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor White
    Write-Host "=   TEST SUITE A - MENU                                =" -ForegroundColor White
    Write-Host "================================================================" -ForegroundColor White
    Write-Host ""
    Write-Host "  CUSTOM" -ForegroundColor Cyan
    Write-Host "    50) Custom - set steps + attacker density (0-99)"
    Write-Host ""
    Write-Host "    99) Show 37 attacker types (T0-T36)"
    Write-Host "     0) Exit"
    Write-Host ""
    Write-Host "Select option [0-50, 99]: " -NoNewline
}

# Main
PrintHeader
EnsureBinary | Out-Null
Write-Host "  Binary ready." -ForegroundColor Green
Write-Host ""

if ($args.Count -gt 0) {
    switch ($args[0]) {
        '50' { Option50; break }
        '99' { PrintAttackerTypes; break }
        default { LogError "Invalid option: $($args[0])"; ShowMenu }
    }
    return
}

while ($true) {
    ShowMenu
    $choice = Read-Host
    
    switch ($choice) {
        '0'  { LogInfo "Exiting..."; exit 0 }
        '50' { Option50 }
        '99' { PrintAttackerTypes }
        default { LogError "Invalid option: $choice" }
    }
    
    Write-Host ""
    Read-Host "Press Enter to continue..."
}
