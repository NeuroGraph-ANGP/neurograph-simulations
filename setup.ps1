# setup.ps1 -- NeuroGraph ANGP v4.3 First-Time Setup
Set-ExecutionPolicy -Scope Process Bypass
 $ErrorActionPreference = "Stop"

 $REPO = "NeuroGraph-ANGP/neurograph-simulations"
 $BIN_DIR = "$PSScriptRoot\bin"
 $BINARY = "sim_stress_v43ext.exe"
 $RELEASE_API = "https://api.github.com/repos/$REPO/releases/latest"

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  NeuroGraph ANGP v4.3 -- Setup" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

if (Test-Path "$BIN_DIR\$BINARY") {
    Write-Host "[OK] $BINARY already present in bin\" -ForegroundColor Green
    exit 0
}

if (-not (Test-Path $BIN_DIR)) {
    New-Item -ItemType Directory -Path $BIN_DIR | Out-Null
    Write-Host "[OK] Created bin\ directory" -ForegroundColor Green
}

Write-Host "[...] Fetching latest release from GitHub..." -ForegroundColor Yellow

try {
    $release = Invoke-RestMethod -Uri $RELEASE_API -Headers @{ "User-Agent" = "NeuroGraph7Setup/1.0" }
} catch {
    Write-Host "[FAIL] Cannot reach GitHub API." -ForegroundColor Red
    exit 1
}

 $asset = $release.assets | Where-Object { $_.name -eq $BINARY }

if (-not $asset) {
    Write-Host "[FAIL] $BINARY not found in latest release!" -ForegroundColor Red
    Write-Host "       Visit: https://github.com/$REPO/releases" -ForegroundColor Yellow
    exit 1
}

 $outputPath = "$BIN_DIR\$BINARY"
Write-Host "[...] Downloading $BINARY..." -ForegroundColor Yellow

try {
    Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $outputPath -Headers @{ "User-Agent" = "NeuroGraph7Setup/1.0" }
} catch {
    Write-Host "[FAIL] Download failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

 $size = [math]::Round((Get-Item $outputPath).Length / 1KB, 0)
Write-Host "[OK] Downloaded $BINARY ($size KB)" -ForegroundColor Green

Write-Host ""
Write-Host "Setup complete! Now run:" -ForegroundColor Cyan
Write-Host "  .\RUN-TESTS-A.ps1" -ForegroundColor White
Write-Host "  .\RUN-NG-BENCHMARK.ps1" -ForegroundColor White
Write-Host ""