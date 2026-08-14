# setup.ps1 -- NeuroGraph ANGP v4.3 First-Time Setup
Set-ExecutionPolicy -Scope Process Bypass
 $ErrorActionPreference = "Stop"

 $REPO = "NeuroGraph-ANGP/neurograph-simulations"
 $BINARY = "angp.exe"
 $BIN_DIR = "$PSScriptRoot\bin"
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
    Write-Host "       Error: $($_.Exception.Message)" -ForegroundColor DarkRed
    exit 1
}

 $asset = $release.assets | Where-Object { $_.name -eq $BINARY }

if (-not $asset) {
    Write-Host "[FAIL] Binary '$BINARY' not found in latest release!" -ForegroundColor Red
    Write-Host "       Available assets:" -ForegroundColor Yellow
    $release.assets | ForEach-Object { Write-Host "         - $($_.name)" -ForegroundColor DarkGray }
    Write-Host ""
    Write-Host "       Visit: https://github.com/$REPO/releases" -ForegroundColor Yellow
    exit 1
}

 $downloadUrl = $asset.browser_download_url
 $outputPath = "$BIN_DIR\$BINARY"

Write-Host "[...] Downloading $BINARY from GitHub Releases..." -ForegroundColor Yellow
Write-Host "       Release: $($release.tag_name)" -ForegroundColor DarkGray

try {
    Invoke-WebRequest -Uri $downloadUrl -OutFile $outputPath -Headers @{ "User-Agent" = "NeuroGraph7Setup/1.0" }
} catch {
    Write-Host "[FAIL] Download failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

 $fileSize = (Get-Item $outputPath).Length
if ($fileSize -gt 1MB) {
    Write-Host "[OK] Downloaded $BINARY ($([math]::Round($fileSize/1MB, 1)) MB)" -ForegroundColor Green
} else {
    Write-Host "[WARN] Binary seems too small ($fileSize bytes). May be corrupt." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Setup complete! Now run:" -ForegroundColor Cyan
Write-Host "  .\RUN-TESTS-A.ps1" -ForegroundColor White
Write-Host "  .\RUN-NG-BENCHMARK.ps1" -ForegroundColor White
Write-Host ""