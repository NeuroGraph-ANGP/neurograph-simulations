# RUN-WARMUP-BOOTSTRAP.ps1
# NeuroGraph ANGP v4.3.1 - Warmup Bootstrap
# Runs ONLY warmup, captures binary output silently, shows clean progress.
# No options. No -Quick/-Full/-Stress.

param()

 $ErrorActionPreference = 'Stop'

 $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
if (-not $scriptDir) { $scriptDir = $PWD.Path }

 $binPath = Join-Path $scriptDir 'bin\sim_stress_v43ext.exe'

if (-not (Test-Path $binPath)) {
    Write-Host ""
    Write-Host "+======================================================+" -ForegroundColor Red
    Write-Host "|  ERROR: Binary not found!                            |" -ForegroundColor Red
    Write-Host "|  Expected: bin\sim_stress_v43ext.exe                 |" -ForegroundColor Red
    Write-Host "+======================================================+" -ForegroundColor Red
    Write-Host ""
    Write-Host "  Run setup.ps1 first to download the binary."
    Write-Host ""
    exit 1
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  NeuroGraph ANGP v4.3.1 - Warmup Bootstrap" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Binary: $binPath" -ForegroundColor Green
Write-Host ""
Write-Host "Running ONLY warmup, then stops." -ForegroundColor Yellow
Write-Host ""

# Run warmup - capture all binary output silently
Write-Host "[STEP] Running warmup..." -ForegroundColor Yellow
 $sw = [System.Diagnostics.Stopwatch]::StartNew()

# Capture output, don't display it
 $null = & $binPath --steps 0 2>&1 | Out-Null
 $exitCode = $LASTEXITCODE

 $sw.Stop()
 $wallSec = [math]::Round($sw.Elapsed.TotalSeconds, 1)

Write-Host ""
if ($exitCode -eq 0) {
    Write-Host "[OK] Warmup complete in ${wallSec}s." -ForegroundColor Green
    Write-Host ""
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host "  Next steps - run ONE of these manually:" -ForegroundColor Cyan
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  .\RUN-TESTS-A.ps1        (test suite A)" -ForegroundColor White
    Write-Host "  .\RUN-NG-BENCHMARK.ps1   (full benchmark)" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host "[FAIL] Warmup exited with code $exitCode" -ForegroundColor Red
    Write-Host ""
}