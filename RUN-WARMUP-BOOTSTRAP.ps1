# ═══════════════════════════════════════════════════════════════════
#  NeuroGraph ANGP v4.3-EXT — WARMUP + BENCHMARK WRAPPER (PowerShell)
#  ═══════════════════════════════════════════════════════════════════
#  SEPARAT de sim_stress_v43ext.rs — nu modifică fișierul original!
#  Folosește flag-ul --warmup deja existent în binar.
#
#  UTILIZARE:
#    .\RUN-WARMUP-BOOTSTRAP.ps1
#    .\RUN-WARMUP-BOOTSTRAP.ps1 -Warmup 2000
#    .\RUN-WARMUP-BOOTSTRAP.ps1 -Percent 30 -Nodes 2664 -Steps 10000 -Warmup 1000
#    .\RUN-WARMUP-BOOTSTRAP.ps1 -Quick
#    .\RUN-WARMUP-BOOTSTRAP.ps1 -Full
#    .\RUN-WARMUP-BOOTSTRAP.ps1 -Stress
# ═══════════════════════════════════════════════════════════════════

param(
    [int]$Percent = 10,
    [int]$Nodes   = 2664,
    [int]$Steps   = 5000,
    [int]$Warmup  = 1000,
    [switch]$Quick,
    [switch]$Full,
    [switch]$Stress,
    [switch]$NoWarmup
)

# ─── PROFILE PRESETS ───
$ProfileName = "default"
if ($Quick) {
    $Nodes = 200; $Steps = 2000; $Warmup = 500; $ProfileName = "quick"
}
if ($Full) {
    $Nodes = 2664; $Steps = 10000; $Warmup = 2000; $ProfileName = "full"
}
if ($Stress) {
    $Nodes = 6660; $Steps = 20000; $Warmup = 3000; $Percent = 30; $ProfileName = "stress"
}
if ($NoWarmup) {
    $Warmup = 0
}

# ─── FIND BINARY ───
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$Binary = Join-Path $ScriptDir "target\release\examples\sim_stress_v43ext.exe"

if (-not (Test-Path $Binary)) {
    # Try Linux path too (WSL / cross-platform)
    $BinaryAlt = Join-Path $ScriptDir "target\release\examples\sim_stress_v43ext"
    if (Test-Path $BinaryAlt) {
        $Binary = $BinaryAlt
    } else {
        Write-Host ""
        Write-Host "╔══════════════════════════════════════════════════════╗" -ForegroundColor Red
        Write-Host "║  EROARE: Binarul nu există!                          ║" -ForegroundColor Red
        Write-Host "╚══════════════════════════════════════════════════════╝" -ForegroundColor Red
        Write-Host ""
        Write-Host "  Compilează mai întâi cu:" -ForegroundColor Yellow
        Write-Host "  cargo build --release --example sim_stress_v43ext" -ForegroundColor Green
        Write-Host ""
        exit 1
    }
}

# ─── CALCULATIONS ───
$NAttackers = [math]::Floor($Nodes * $Percent / 100)
$NHonest    = $Nodes - $NAttackers
$TotalSteps = $Warmup + $Steps

# ─── HEADER ───
Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  NeuroGraph ANGP v4.3-EXT — WARMUP BENCHMARK WRAPPER        ║" -ForegroundColor Cyan
Write-Host "╠════════════════════════════════════════════════════════════════╣" -ForegroundColor Cyan
Write-Host "║  Profile:    $ProfileName                                              ║" -ForegroundColor Cyan
Write-Host "║  Nodes:      $Nodes ($NHonest honest + $NAttackers attackers)       ║" -ForegroundColor Cyan
Write-Host "║  Attackers:  $Percent%                                            ║" -ForegroundColor Cyan
Write-Host "║  Warmup:     $Warmup steps                                     ║" -ForegroundColor Cyan
Write-Host "║  Benchmark:  $Steps steps                                    ║" -ForegroundColor Cyan
Write-Host "║  Total:      $TotalSteps steps                                   ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

if ($Warmup -gt 0) {
    Write-Host "┌─────────────────────────────────────────────┐" -ForegroundColor Magenta
    Write-Host "│  WARMUP MODE: $Warmup steps                     │" -ForegroundColor Magenta
    Write-Host "│  Toate nodurile honest în warmup,            │" -ForegroundColor Magenta
    Write-Host "│  apoi atacatorii introduși la step $Warmup.  │" -ForegroundColor Magenta
    Write-Host "│  Starea (rep, EMA, DAG) rămâne CALDĂ        │" -ForegroundColor Magenta
    Write-Host "│  — niciun restart de proces!                │" -ForegroundColor Magenta
    Write-Host "└─────────────────────────────────────────────┘" -ForegroundColor Magenta
} else {
    Write-Host "⚠  WARMUP DEZACTIVAT (0 steps) — benchmark de la rece" -ForegroundColor Yellow
}
Write-Host ""

# ─── SYSTEM INFO ───
$Cores = $env:NUMBER_OF_PROCESSORS
if (-not $Cores) { $Cores = "N/A" }
Write-Host "[SYS] CPU cores:  $Cores" -ForegroundColor Cyan
Write-Host "[SYS] Binary:     $Binary" -ForegroundColor Cyan
if (Test-Path $Binary) {
    $BinSize = (Get-Item $Binary).Length / 1MB
    Write-Host ("[SYS] Binary size: {0:N1} MB" -f $BinSize) -ForegroundColor Cyan
}
Write-Host ""

# ─── RUN BENCHMARK ───
Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "  STARTING BENCHMARK..." -ForegroundColor Green
Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""

$sw = [System.Diagnostics.Stopwatch]::StartNew()

# Run the actual binary with --warmup flag
# The binary handles warmup internally: warmup steps run all-honest,
# then attackers are introduced. State stays warm (no process restart).
& $Binary --percent $Percent --nodes $Nodes --steps $Steps --warmup $Warmup

$ExitCode = $LASTEXITCODE
$sw.Stop()

$WallSec = [math]::Round($sw.Elapsed.TotalSeconds, 1)

Write-Host ""
Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Cyan

if ($ExitCode -eq 0) {
    Write-Host "  ✓ BENCHMARK COMPLET" -ForegroundColor Green
} else {
    Write-Host "  ✗ BENCHMARK EȘUAT (exit code: $ExitCode)" -ForegroundColor Red
}

Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Wall time:    ${WallSec}s"
Write-Host "  Profile:      $ProfileName"
Write-Host "  Nodes:        $Nodes"
Write-Host "  Warmup:       $Warmup steps"
Write-Host "  Benchmark:    $Steps steps"
Write-Host "  Total steps:  $TotalSteps"
if ($Warmup -gt 0) {
    $Ratio = [math]::Round($Warmup * 100 / $TotalSteps, 1)
    Write-Host "  Warmup ratio: ${Ratio}%"
}
Write-Host ""

# Nu închidem PowerShell — fereastra rămâne deschisă
