#!/usr/bin/env bash
set -euo pipefail

# ------------------------------------------------------------
# ML verification runner (Notebook -> Executed Notebook -> HTML report)
# - Creates an isolated venv: .venv-ml
# - Installs ML-only dependencies from requirements-ml.txt
# - Executes notebook:
#     ml/notebooks/01_data_loading_and_cleaning.ipynb
# - Exports:
#     ml/outputs/01_executed.ipynb
#     ml/outputs/01_report.html
# ------------------------------------------------------------

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT_DIR"

NOTEBOOK_PATH="ml/notebooks/01_data_loading_and_cleaning.ipynb"
OUT_DIR="ml/outputs"
EXEC_IPYNB="${OUT_DIR}/01_executed.ipynb"
OUT_HTML="${OUT_DIR}/01_report.html"
REQ_FILE="requirements-ml.txt"
VENV_DIR=".venv-ml"

echo "[0/5] Sanity checks"
if [[ ! -f "$NOTEBOOK_PATH" ]]; then
  echo "ERROR: Notebook not found: ${NOTEBOOK_PATH}"
  echo "Hint: Ensure the notebook is located at: ml/notebooks/01_data_loading_and_cleaning.ipynb"
  exit 1
fi

if [[ ! -f "$REQ_FILE" ]]; then
  echo "ERROR: ${REQ_FILE} not found in project root."
  echo "Hint: Create requirements-ml.txt (ML-only dependencies) in the repository root."
  exit 1
fi

mkdir -p "$OUT_DIR"

echo "[1/5] Create/Reuse venv: ${VENV_DIR}"
if [[ ! -d "$VENV_DIR" ]]; then
  python -m venv "$VENV_DIR"
fi

# shellcheck disable=SC1091
source "${VENV_DIR}/bin/activate"

echo "[2/5] Upgrade pip"
python -m pip install --upgrade pip

echo "[3/5] Install ML requirements from ${REQ_FILE}"
pip install -r "$REQ_FILE"

echo "[4/5] Execute notebook (this may take a while)"
# Execute notebook, produce executed ipynb.
jupyter nbconvert --to notebook --execute \
  --ExecutePreprocessor.timeout=600 \
  --output "$EXEC_IPYNB" \
  "$NOTEBOOK_PATH"

echo "[5/5] Export HTML report"
jupyter nbconvert --to html \
  --output "$OUT_HTML" \
  "$EXEC_IPYNB"

echo ""
echo "Done."
echo "Executed notebook: ${EXEC_IPYNB}"
echo "HTML report:       ${OUT_HTML}"
echo "Open the HTML file in your browser to verify results."
