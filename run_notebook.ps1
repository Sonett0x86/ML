# ============================================================
# Run ML Notebook (PowerShell, Windows-native)
# - Creates a dedicated venv: .venv-ml
# - Installs dependencies (prefers requirements-ml.txt, falls back to requirements.txt)
# - Executes notebook from its folder (so ../data paths work)
# - Exports executed notebook + HTML report
# ============================================================

$ErrorActionPreference = "Stop"

# Go to project root (where this script is located)
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $Root

# Paths
$NotebookPath = "ml\notebooks\01_data_loading_and_cleaning.ipynb"
$OutDir = "ml\outputs"
$ExecIpynb = Join-Path $OutDir "01_executed.ipynb"
$OutHtml = Join-Path $OutDir "01_report.html"
$VenvDir = ".venv-ml"

# Prefer ML-only requirements if present, otherwise use requirements.txt
$ReqFile = "requirements-ml.txt"
if (!(Test-Path $ReqFile)) {
    $ReqFile = "requirements.txt"
}

Write-Host "[0/6] Checking files..."
if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    throw "Python not found in PATH. Install Python 3.x and restart PowerShell."
}
if (!(Test-Path $NotebookPath)) {
    throw "Notebook not found: $NotebookPath"
}
if (!(Test-Path $ReqFile)) {
    throw "Requirements file not found in project root (expected requirements-ml.txt or requirements.txt)."
}
if (!(Test-Path "data")) {
    throw "data/ directory not found in project root."
}
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

Write-Host "[1/6] Creating or reusing virtual environment: $VenvDir"
if (!(Test-Path $VenvDir)) {
    python -m venv $VenvDir
}

# Use absolute paths for python/pip so they still work after Push-Location
$Python = Join-Path $Root (Join-Path $VenvDir "Scripts\python.exe")
$Pip    = Join-Path $Root (Join-Path $VenvDir "Scripts\pip.exe")

if (!(Test-Path $Python)) { throw "Virtualenv python not found: $Python" }
if (!(Test-Path $Pip)) { throw "Virtualenv pip not found: $Pip" }

Write-Host "[2/6] Upgrading pip"
& $Python -m pip install --upgrade pip
if ($LASTEXITCODE -ne 0) { throw "pip upgrade failed (exit code: $LASTEXITCODE)" }

Write-Host "[3/6] Installing dependencies from $ReqFile"
& $Pip install -r $ReqFile
if ($LASTEXITCODE -ne 0) { throw "pip install failed (exit code: $LASTEXITCODE)" }

Write-Host "[4/6] Executing notebook (this may take a few minutes)"
$NotebookDir  = Split-Path -Parent $NotebookPath
$NotebookFile = Split-Path -Leaf $NotebookPath

# Absolute output paths (safe regardless of current directory)
$ExecIpynbAbs = Join-Path $Root $ExecIpynb
$OutHtmlAbs   = Join-Path $Root $OutHtml

Push-Location $NotebookDir

# Run from notebook directory so relative paths like ../data/raw_sales.csv work
& $Python -m jupyter nbconvert --to notebook --execute `
    --ExecutePreprocessor.timeout=1200 `
    --output $ExecIpynbAbs `
    $NotebookFile

$code = $LASTEXITCODE
Pop-Location

if ($code -ne 0) { throw "Notebook execution failed (exit code: $code)" }
if (!(Test-Path $ExecIpynbAbs)) { throw "Executed notebook was not created: $ExecIpynbAbs" }

Write-Host "[5/6] Exporting HTML report"
& $Python -m jupyter nbconvert --to html `
    --output $OutHtmlAbs `
    $ExecIpynbAbs

if ($LASTEXITCODE -ne 0) { throw "HTML export failed (exit code: $LASTEXITCODE)" }
if (!(Test-Path $OutHtmlAbs)) { throw "HTML report was not created: $OutHtmlAbs" }

Write-Host "[6/6] Finished successfully"
Write-Host "--------------------------------------------"
Write-Host "Executed notebook: $ExecIpynbAbs"
Write-Host "HTML report:       $OutHtmlAbs"
Write-Host "Open the HTML file in a browser to verify results."
