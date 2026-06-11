@echo off
chcp 65001 >nul 2>&1
title Ollama USB Toolkit - LLM Installer
color 0A

echo.
echo  ╔══════════════════════════════════════════════════════════════╗
echo  ║              OLLAMA USB TOOLKIT - LLM INSTALLER             ║
echo  ║         Install and Run Open-Source LLMs Anywhere           ║
echo  ╚══════════════════════════════════════════════════════════════╝
echo.

:: -------------------------------------------------------
:: USB PATH SETUP
:: %~dp0 always resolves to the folder where this .bat
:: lives — i.e. the USB root — regardless of which drive
:: letter Windows assigns to the USB on this machine.
:: -------------------------------------------------------
set "USB_DIR=%~dp0"
set "USB_DIR=%USB_DIR:~0,-1%"
set "SCRIPTS_DIR=%USB_DIR%\scripts"
set "DATA_DIR=%USB_DIR%\data"
set "MODELS_DIR=%USB_DIR%\models"
set "LOG_DIR=%USB_DIR%\logs"

:: Set Ollama model path to USB so models travel with the drive
set "OLLAMA_MODELS=%MODELS_DIR%"

if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"
if not exist "%DATA_DIR%" mkdir "%DATA_DIR%"
if not exist "%MODELS_DIR%" mkdir "%MODELS_DIR%"

echo  [INFO] USB Drive detected at: %USB_DIR%
echo.

:: -------------------------------------------------------
:: PORTABILITY FIX — Wipe stale path caches
:: When the USB moves to a different PC, Windows caches
:: from the old machine contain wrong absolute paths and
:: cause crashes. Deleting them on every launch fixes this.
:: -------------------------------------------------------
echo  [INFO] Clearing stale path caches for portability...
if exist "%DATA_DIR%\config.json"  del /q "%DATA_DIR%\config.json"  >nul 2>&1
if exist "%DATA_DIR%\Cache"        rmdir /s /q "%DATA_DIR%\Cache"   >nul 2>&1
if exist "%DATA_DIR%\Code Cache"   rmdir /s /q "%DATA_DIR%\Code Cache" >nul 2>&1
if exist "%DATA_DIR%\GPUCache"     rmdir /s /q "%DATA_DIR%\GPUCache" >nul 2>&1
echo  [INFO] Cache cleared.
echo.

:: Check for PowerShell availability
where powershell >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo  [ERROR] PowerShell is not available on this system.
    echo  [ERROR] Please install PowerShell or use a Windows 10+ system.
    pause
    exit /b 1
)

:: -------------------------------------------------------
:: TOP-LEVEL MENU
:: 1 = Original Ollama installer (PowerShell)
:: A = Claw Agent (terminal)
:: B = Claw Agent API + Web UI
:: C = Doctor
:: -------------------------------------------------------
:menu
echo.
echo  +----------------------------------------------+
echo  ^|              OLLAMA USB TOOLKIT             ^|
echo  +----------------------------------------------+
echo  ^|  1. Run the original installer (Ollama)      ^|
echo  ^|                                              ^|
echo  ^|  -- Claw Edition (v2.0) --                   ^|
echo  ^|  A. Start Claw Agent (terminal)              ^|
echo  ^|  B. Start Claw Agent API + open Web UI       ^|
echo  ^|  C. Doctor (validate workspace)              ^|
echo  ^|                                              ^|
echo  ^|  0. Exit                                     ^|
echo  +----------------------------------------------+
echo.
set /p choice=  Select an option (1, A, B, C, 0): 
if /i "%choice%"=="1" goto run_installer
if /i "%choice%"=="A" goto claw_chat
if /i "%choice%"=="B" goto claw_serve
if /i "%choice%"=="C" goto claw_doctor
if /i "%choice%"=="0" goto end
echo  [WARN] Invalid option.
goto menu

:run_installer
echo  [INFO] Launching installer...
echo.
powershell -ExecutionPolicy Bypass -File "%SCRIPTS_DIR%\install-ollama.ps1" -USBPath "%USB_DIR%"
pause
goto menu

:claw_chat
where python >nul 2>&1 && (set "PY=python") || (set "PY=py")
%PY% "%USB_DIR%\agent\claw_agent.py" chat
pause
goto menu

:claw_serve
where python >nul 2>&1 && (set "PY=python") || (set "PY=py")
start "" "%USB_DIR%\webui\claw.html"
%PY% "%USB_DIR%\agent\claw_agent.py" serve --port 11500
pause
goto menu

:claw_doctor
where python >nul 2>&1 && (set "PY=python") || (set "PY=py")
%PY% "%USB_DIR%\agent\claw_agent.py" doctor
pause
goto menu

:end
endlocal
exit /b 0
