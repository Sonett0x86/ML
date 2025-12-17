### Option 1: View results via Web Interface

The project is deployed on a cloud server.

Web interface:
http://39.105.136.49:8080

The interface allows:
- Viewing historical house prices (2-bedroom houses)
- Viewing forecasted prices for future periods

### Option 2: Run locally (Windows PowerShell)

This option allows the machine learning part of the project to be run locally without using Docker or the cloud deployment.

**Steps:**
1. Clone the project repository to a local machine.
2. Open PowerShell and navigate to the project root directory.
3. Run the following command:

```powershell
powershell -ExecutionPolicy Bypass -File .\run_notebook.ps1


