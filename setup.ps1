# setup.ps1 -- NeuroGraph ANGP v4.3 First-Time Setup
Set-ExecutionPolicy -Scope Process Bypass
 $ErrorActionPreference = "Stop"

 $REPO = "NeuroGraph-ANGP/neurograph-simulations"
 $BIN_DIR = "$PSScriptRoot\bin"
 $RELEASE_API = "https://api.github.com/repos/$REPO/releases/latest"

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  NeuroGraph ANGP v4.3 -- Setup" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Creeaza directorul bin
if (-not (Test-Path $BIN_DIR)) {
    New-Item -ItemType Directory -Path $BIN_DIR | Out-Null
    Write-Host "[OK] Created bin\ directory" -ForegroundColor Green
}

# Verifica daca binary-urile exista deja
 $existing = Get-ChildItem "$BIN_DIR\*.exe" -ErrorAction SilentlyContinue
if ($existing.Count -ge 2) {
    Write-Host "[OK] Binaries already present in bin\" -ForegroundColor Green
    $existing | ForEach-Object { Write-Host "     - $($_.Name)" -ForegroundColor DarkGray }
    exit 0
}

# Descarca de la GitHub Releases
Write-Host "[...] Fetching latest release from GitHub..." -ForegroundColor Yellow

try {
    $release = Invoke-RestMethod -Uri $RELEASE_API -Headers @{ "User-Agent" = "NeuroGraph7Setup/1.0" }
} catch {
    Write-Host "[FAIL] Cannot reach GitHub API." -ForegroundColor Red
    Write-Host "       Error: $($_.Exception.Message)" -ForegroundColor DarkRed
    exit 1
}

 $assets = $release.assets | Where-Object { $_.name -like "*.exe" }

if ($assets.Count -eq 0) {
    Write-Host "[FAIL] No .exe binaries found in latest release!" -ForegroundColor Red
    Write-Host "       Visit: https://github.com/$REPO/releases" -ForegroundColor Yellow
    exit 1
}

Write-Host "[...] Downloading $($assets.Count) binaries from release $($release.tag_name)..." -ForegroundColor Yellow

foreach ($asset in $assets) {
    $outputPath = "$BIN_DIR\$($asset.name)"
    Write-Host "     - $($asset.name)..." -ForegroundColor DarkGray -NoNewline
    
    try {
        Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $outputPath -Headers @{ "User-Agent" = "NeuroGraph7Setup/1.0" }
        $size = [math]::Round((Get-Item $outputPath).Length / 1KB, 0)
        Write-Host " OK ($size KB)" -ForegroundColor Green
    } catch {
        Write-Host " FAIL" -ForegroundColor Red
        Write-Host "       $($_.Exception.Message)" -ForegroundColor DarkRed
    }
}

Write-Host ""
Write-Host "Setup complete! Now run:" -ForegroundColor Cyan
Write-Host "  .\RUN-TESTS-A.ps1" -ForegroundColor White
Write-Host "  .\RUN-NG-BENCHMARK.ps1" -ForegroundColor White
Write-Host ""