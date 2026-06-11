@echo off
rem ============================================================
rem  Claw agent API launcher (Windows)
rem ============================================================
setlocal
set "SCRIPT_DIR=%~dp0"
set "USB_DIR=%SCRIPT_DIR%.."
for %%I in ("%USB_DIR%") do set "USB_DIR=%%~fI"

set "OLLAMA_MODELS=%USB_DIR%\models"
set "OLLAMA_ORIGINS=*"

where python >nul 2>&1
if %ERRORLEVEL% neq 0 (
    where py >nul 2>&1
    if %ERRORLEVEL% neq 0 (
        echo [ERROR] Python is not installed. Install Python 3.8+ from python.org
        pause
        exit /b 1
    )
    set "PY=py"
) else (
    set "PY=python"
)

echo.
echo  ================================================================
echo   Claw agent API
echo   USB:  %USB_DIR%
echo   URL:  http://127.0.0.1:11500
echo   UI:   open webui\claw.html in your browser
echo  ================================================================
echo.
%PY% "%SCRIPT_DIR%claw_agent.py" serve --port 11500
pause
