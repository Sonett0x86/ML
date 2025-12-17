# ============================================================
# Run ML Notebook (PowerShell, Windows-native)
#
# Project structure (based on your repo):
# - data/raw_sales.csv
# - ml/notebooks/01_data_loading_and_cleaning.ipynb
# - ml/output/ (generated)
# - requirements.txt (in repo root)
#
# What this script does:
# 1) Creates a dedicated venv: .venv-ml
# 2) Installs dependencies from requirements.txt
# 3) Executes the notebook from ml/notebooks so "../data/..." works
# 4) Exports executed notebook + HTML report into ml/output
# ============================================================

$ErrorActionPreference = "Stop"

# Go to project root (where this script is located)
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $Root

# --- Paths (match your repo structure) ---
$NotebookPath = "ml\notebooks\01_data_loading_and_cleaning.ipynb"

# Your repo uses ml/output (not ml/outputs)
$OutDir = "ml\output"
$ExecIpynb = Join-Path $OutDir "01_executed.ipynb"
$OutHtml  = Join-Path $OutDir "01_report.html"

# Your repo root has requirements.txt (no requirements-ml.txt)
$ReqFile = "requirements.txt"

# Dedicated venv (do NOT conflict with existing .venv)
$VenvDir = ".venv-ml"

Write-Host "[0/6] Checking files..."

# Check python
if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    throw "Python not found in PATH. Install Python 3.x and restart PowerShell."
}

# Check notebook
if (!(Test-Path $NotebookPath)) {
    throw "Notebook not found: $NotebookPath"
}

# Check requirements
if (!(Test-Path $ReqFile)) {
    throw "Requirements file not found in project root: $ReqFile"
}

# Check dataset exists in the repo root data folder
$RootDataPath = Join-Path $Root "data\raw_sales.csv"
if (!(Test-Path $RootDataPath)) {
    throw "Dataset not found: $RootDataPath"
}

# --- IMPORTANT: notebook uses ../data/raw_sales.csv from ml/notebooks
# That resolves to ml/data/raw_sales.csv.
# We will ensure a copy exists there for successful execution.
$MlDataDir = Join-Path $Root "ml\data"
$MlDataPath = Join-Path $MlDataDir "raw_sales.csv"

if (!(Test-Path $MlDataPath)) {
    New-Item -ItemType Directory -Force -Path $MlDataDir | Out-Null
    Copy-Item -Force $RootDataPath $MlDataPath
    Write-Host "Copied dataset to notebook-expected path: $MlDataPath"
}

# Create output dir
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

Write-Host "[1/6] Creating or reusing virtual environment: $VenvDir"
if (!(Test-Path $VenvDir)) {
    python -m venv $VenvDir
}

# Use absolute paths for python/pip so they still work after Push-Location
$Python = Join-Path $Root (Join-Path $VenvDir "Scripts\python.exe")
$Pip    = Join-Path $Root (Join-Path $VenvDir "Scripts\pip.exe")

if (!(Test-Path $Python)) { throw "Virtualenv python not found: $Python" }
if (!(Test-Path $Pip))    { throw "Virtualenv pip not found: $Pip" }

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

# Run from notebook directory so relative paths like ../data/raw_sales.csv work
Push-Location $NotebookDir

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
