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

:: Get the USB drive path (where this script is located)
set "USB_DIR=%~dp0"
set "USB_DIR=%USB_DIR:~0,-1%"
set "SCRIPTS_DIR=%USB_DIR%\scripts"

echo  [INFO] USB Drive detected at: %USB_DIR%
echo.

:: Check for PowerShell availability
where powershell >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo  [ERROR] PowerShell is not available on this system.
    echo  [ERROR] Please install PowerShell or use a Windows 10+ system.
    pause
    exit /b 1
)

:: Launch the PowerShell installer script
echo  [INFO] Launching installer...
echo.
powershell -ExecutionPolicy Bypass -File "%SCRIPTS_DIR%\install-ollama.ps1" -USBPath "%USB_DIR%"

pause
