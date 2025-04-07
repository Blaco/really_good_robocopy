@echo off
:: ============================================================
:: Batch File: Launch Auto_Backup.ps1 as Administrator
:: Description: This batch file checks for administrative
::              privileges, sets the working directory to the
::              folder containing the batch file, and then
::              launches the Auto_Backup.ps1 PowerShell script.
:: ============================================================

:: ----- Check for Administrative Privileges -----
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting administrative privileges...
    timeout /t 1 /nobreak >nul
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:: ----- Set Working Directory to the Batch File's Location -----
cd /d "%~dp0"

:: ----- Inform User  -----
echo Running as Administrator.
timeout /t 2 /nobreak >nul

:: ----- Launch the PowerShell Backup Script -----
:: (Ensure that Auto_Backup.ps1 is in the same folder as this batch file.)
powershell -ExecutionPolicy Bypass -File "Auto_Backup.ps1"

:: ----- End of Script -----
