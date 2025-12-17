# ============================================================
# Run ML Notebook (PowerShell, Windows-native)
# ============================================================

$ErrorActionPreference = "Stop"

# Go to project root
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $Root

$NotebookPath = "ml\notebooks\01_data_loading_and_cleaning.ipynb"
$OutDir = "ml\outputs"
$ExecIpynb = Join-Path $OutDir "01_executed.ipynb"
$OutHtml = Join-Path $OutDir "01_report.html"
$ReqFile = "requirements.txt"
$VenvDir = ".venv-ml"

Write-Host "[0/6] Checking files..."
if (!(Test-Path $NotebookPath)) {
    throw "Notebook not found: $NotebookPath"
}
if (!(Test-Path $ReqFile)) {
    throw "requirements-ml.txt not found in project root"
}
if (!(Test-Path "data")) {
    throw "data/ directory not found"
}

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

Write-Host "[1/6] Creating or reusing virtual environment"
if (!(Test-Path $VenvDir)) {
    python -m venv $VenvDir
}

$Python = Join-Path $VenvDir "Scripts\python.exe"
$Pip    = Join-Path $VenvDir "Scripts\pip.exe"

Write-Host "[2/6] Upgrading pip"
& $Python -m pip install --upgrade pip

Write-Host "[3/6] Installing ML dependencies"
& $Pip install -r $ReqFile

Write-Host "[4/6] Executing notebook (this may take a few minutes)"
& $Python -m jupyter nbconvert --to notebook --execute `
    --ExecutePreprocessor.timeout=600 `
    --output $ExecIpynb `
    $NotebookPath

Write-Host "[5/6] Exporting HTML report"
& $Python -m jupyter nbconvert --to html `
    --output $OutHtml `
    $ExecIpynb

Write-Host "[6/6] Finished successfully"
Write-Host "--------------------------------------------"
Write-Host "Executed notebook: $ExecIpynb"
Write-Host "HTML report:       $OutHtml"
Write-Host "Open the HTML file in a browser to verify results."
