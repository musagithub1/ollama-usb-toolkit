@echo off
setlocal
set "SCRIPT_DIR=%~dp0"
set "USB_DIR=%SCRIPT_DIR%.."
for %%I in ("%USB_DIR%") do set "USB_DIR=%%~fI"
set "OLLAMA_MODELS=%USB_DIR%\models"
where python >nul 2>&1 && (set "PY=python") || (set "PY=py")
%PY% "%SCRIPT_DIR%claw_agent.py" chat %*
pause
