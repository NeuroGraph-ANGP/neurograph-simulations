# ===================================================================
#  NeuroGraph ANGP v4.3-EXT - WARMUP BOOTSTRAP (PowerShell)
#  ===================================================================
#  SEPARAT de sim_stress_v43ext.rs - nu modifica fisierul original!
#  Foloseste flag-ul --warmup deja existent in binar.
#
#  UTILIZARE:
#    .\RUN-WARMUP-BOOTSTRAP.ps1
#    .\RUN-WARMUP-BOOTSTRAP.ps1 -Warmup 2000
#    .\RUN-WARMUP-BOOTSTRAP.ps1 -Percent 30 -Nodes 2664 -Warmup 1000
# ===================================================================

param(
    [int]$Percent = 0,
    [int]$Nodes   = 2664,
    [int]$Warmup  = 1000,
    [switch]$NoWarmup
)

# --- FIND BINARY ---
 $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
 $Binary = Join-Path $ScriptDir "bin\sim_stress_v43ext.exe"

if (-not (Test-Path $Binary)) {
    $BinaryAlt = Join-Path $ScriptDir "target\release\examples\sim_stress_v43ext.exe"
    if (Test-Path $BinaryAlt) {
        $Binary = $BinaryAlt
    } else {
        $BinaryAlt2 = Join-Path $ScriptDir "bin\sim_stress_v43ext"
        if (Test-Path $BinaryAlt2) {
            $Binary = $BinaryAlt2
        } else {
            Write-Host ""
            Write-Host "+======================================================+" -ForegroundColor Red
            Write-Host "|  EROARE: Binarul nu exista!                          |" -ForegroundColor Red
            Write-Host "+======================================================+" -ForegroundColor Red
            Write-Host ""
            Write-Host "  Ruleaza setup.ps1 intai:" -ForegroundColor Yellow
            Write-Host "  .\setup.ps1" -ForegroundColor Green
            Write-Host ""
            exit 1
        }
    }
}

# --- CALCULATIONS ---
 $NAttackers = [math]::Floor($Nodes * $Percent / 100)
 $NHonest    = $Nodes - $NAttackers

# --- HEADER ---
Write-Host ""
Write-Host "+================================================================+" -ForegroundColor Cyan
Write-Host "|  NeuroGraph ANGP v4.3-EXT - WARMUP BOOTSTRAP                |" -ForegroundColor Cyan
Write-Host "+================================================================+" -ForegroundColor Cyan
Write-Host "|  Nodes:      $Nodes ($NHonest honest + $NAttackers attackers)       |" -ForegroundColor Cyan
Write-Host "|  Attackers:  $Percent%                                            |" -ForegroundColor Cyan
Write-Host "|  Warmup:     $Warmup steps                                     |" -ForegroundColor Cyan
Write-Host "+================================================================+" -ForegroundColor Cyan
Write-Host ""

if ($Warmup -gt 0) {
    Write-Host "+---------------------------------------------+" -ForegroundColor Magenta
    Write-Host "|  WARMUP MODE: $Warmup steps                     |" -ForegroundColor Magenta
    Write-Host "|  Toate nodurile honest in warmup,            |" -ForegroundColor Magenta
    Write-Host "|  Starea (rep, EMA, DAG) ramane CALDA        |" -ForegroundColor Magenta
    Write-Host "|  - niciun restart de proces!                |" -ForegroundColor Magenta
    Write-Host "+---------------------------------------------+" -ForegroundColor Magenta
} else {
    Write-Host "!  WARMUP DEZACTIVAT (0 steps) - pornire de la rece" -ForegroundColor Yellow
}
Write-Host ""

# --- SYSTEM INFO ---
 $Cores = $env:NUMBER_OF_PROCESSORS
if (-not $Cores) { $Cores = "N/A" }
Write-Host "[SYS] CPU cores:  $Cores" -ForegroundColor Cyan
Write-Host "[SYS] Binary:     $Binary" -ForegroundColor Cyan
if (Test-Path $Binary) {
    $BinSize = (Get-Item $Binary).Length / 1MB
    Write-Host ("[SYS] Binary size: {0:N1} MB" -f $BinSize) -ForegroundColor Cyan
}
Write-Host ""

# --- RUN WARMUP ---
Write-Host "================================================================" -ForegroundColor Green
Write-Host "  STARTING WARMUP..." -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Green
Write-Host ""

 $sw = [System.Diagnostics.Stopwatch]::StartNew()

# Run the binary with --warmup flag only (NO benchmark)
& $Binary --percent $Percent --nodes $Nodes --steps 0 --warmup $Warmup

 $ExitCode = $LASTEXITCODE
 $sw.Stop()

 $WallSec = [math]::Round($sw.Elapsed.TotalSeconds, 1)

Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan

if ($ExitCode -eq 0) {
    Write-Host "  OK WARMUP COMPLET" -ForegroundColor Green
} else {
    Write-Host "  FAIL WARMUP ESUAT (exit code: $ExitCode)" -ForegroundColor Red
}

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  Wall time:    ${WallSec}s"
Write-Host "  Nodes:        $Nodes"
Write-Host "  Warmup:       $Warmup steps"
Write-Host ""
Write-Host "  Next steps (alege manual):" -ForegroundColor Yellow
Write-Host "    .\RUN-TESTS-A.ps1       - Single-shard security analysis" -ForegroundColor White
Write-Host "    .\RUN-NG-BENCHMARK.ps1  - Multi-shard benchmark" -ForegroundColor White
Write-Host ""

# Nu inchidem PowerShell - fereastra ramane deschisa