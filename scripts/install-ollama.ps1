param(
    [string]$USBPath = (Split-Path -Parent $PSScriptRoot)
)

# ============================================================================
#  OLLAMA USB TOOLKIT - Windows Installer Script
#  Installs Ollama + Open-Source LLM on any Windows 10/11 system
# ============================================================================

$ErrorActionPreference = "Continue"
$Host.UI.RawUI.WindowTitle = "Ollama USB Toolkit"

# --- Configuration ---
$ConfigFile = Join-Path $USBPath "config\settings.json"
$ModelsDir  = Join-Path $USBPath "models"
$LogFile    = Join-Path $USBPath "logs\install-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
$VersionFile = Join-Path $USBPath "VERSION"

# --- Read version ---
$ToolkitVersion = "1.2.0"
if (Test-Path $VersionFile) {
    $ToolkitVersion = (Get-Content $VersionFile -Raw).Trim()
}

# --- Read settings.json ---
$DefaultModel = "phi3:mini"
$OllamaHost   = "127.0.0.1"
$OllamaPort   = 11434
if (Test-Path $ConfigFile) {
    try {
        $settings   = Get-Content $ConfigFile -Raw | ConvertFrom-Json
        $DefaultModel = if ($settings.default_model) { $settings.default_model } else { $DefaultModel }
        $OllamaHost   = if ($settings.ollama_host)   { $settings.ollama_host }   else { $OllamaHost }
        $OllamaPort   = if ($settings.ollama_port)   { $settings.ollama_port }   else { $OllamaPort }
    } catch {
        # settings.json malformed — use defaults
    }
}

# Create logs directory
$LogDir = Join-Path $USBPath "logs"
if (-not (Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir -Force | Out-Null }

# --- Helper Functions ---
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    Add-Content -Path $LogFile -Value $logEntry
    switch ($Level) {
        "INFO"    { Write-Host "  [INFO] $Message" -ForegroundColor Cyan }
        "SUCCESS" { Write-Host "  [OK]   $Message" -ForegroundColor Green }
        "WARN"    { Write-Host "  [WARN] $Message" -ForegroundColor Yellow }
        "ERROR"   { Write-Host "  [ERR]  $Message" -ForegroundColor Red }
    }
}

function Show-Banner {
    Write-Host ""
    Write-Host "  ============================================================" -ForegroundColor Green
    Write-Host "       OLLAMA USB TOOLKIT v$ToolkitVersion - LLM Installer" -ForegroundColor Green
    Write-Host "  ============================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "  OS        : $([System.Environment]::OSVersion.VersionString)" -ForegroundColor Gray
    Write-Host "  RAM       : $([math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 1)) GB" -ForegroundColor Gray
    Write-Host "  USB Path  : $USBPath" -ForegroundColor Gray
    Write-Host "  Config    : default_model=$DefaultModel, port=$OllamaPort" -ForegroundColor Gray
    Write-Host ""
}

function Show-Menu {
    Write-Host ""
    Write-Host "  ┌──────────────────────────────────────────────┐" -ForegroundColor White
    Write-Host "  │           MAIN MENU - Choose Action          │" -ForegroundColor White
    Write-Host "  ├──────────────────────────────────────────────┤" -ForegroundColor White
    Write-Host "  │  1. Install Ollama + Download LLM Model      │" -ForegroundColor White
    Write-Host "  │  2. Install Ollama Only                      │" -ForegroundColor White
    Write-Host "  │  3. Download/Change LLM Model                │" -ForegroundColor White
    Write-Host "  │  4. Start Chat with LLM                      │" -ForegroundColor White
    Write-Host "  │  5. Start Ollama Server (API mode)           │" -ForegroundColor White
    Write-Host "  │  6. Install Open WebUI (Browser Chat)        │" -ForegroundColor White
    Write-Host "  │  7. System Info & GPU Check                  │" -ForegroundColor White
    Write-Host "  │  8. Store Models on USB (Portable Mode)      │" -ForegroundColor White
    Write-Host "  │  9. Uninstall Ollama                         │" -ForegroundColor White
    Write-Host "  │  0. Exit                                     │" -ForegroundColor White
    Write-Host "  └──────────────────────────────────────────────┘" -ForegroundColor White
    Write-Host ""
}

function Show-ModelMenu {
    Write-Host ""
    Write-Host "  ┌──────────────────────────────────────────────────────────────┐" -ForegroundColor Cyan
    Write-Host "  │              SELECT A MODEL TO DOWNLOAD                      │" -ForegroundColor Cyan
    Write-Host "  ├──────────────────────────────────────────────────────────────┤" -ForegroundColor Cyan
    Write-Host "  │                                                              │" -ForegroundColor Cyan
    Write-Host "  │  --- Lightweight (2-4 GB RAM) ---                            │" -ForegroundColor Cyan
    Write-Host "  │  1. tinyllama       (1.1B)  - Fast, lightweight              │" -ForegroundColor Cyan
    Write-Host "  │  2. phi3:mini       (3.8B)  - Microsoft, great quality       │" -ForegroundColor Cyan
    Write-Host "  │  3. gemma2:2b       (2.6B)  - Google, compact               │" -ForegroundColor Cyan
    Write-Host "  │                                                              │" -ForegroundColor Cyan
    Write-Host "  │  --- Medium (8 GB RAM) ---                                   │" -ForegroundColor Cyan
    Write-Host "  │  4. llama3.2        (3B)    - Meta, latest Llama             │" -ForegroundColor Cyan
    Write-Host "  │  5. mistral         (7B)    - Mistral AI, versatile          │" -ForegroundColor Cyan
    Write-Host "  │  6. gemma2          (9B)    - Google, powerful               │" -ForegroundColor Cyan
    Write-Host "  │  7. qwen2.5         (7B)    - Alibaba, multilingual          │" -ForegroundColor Cyan
    Write-Host "  │                                                              │" -ForegroundColor Cyan
    Write-Host "  │  --- Large (16+ GB RAM) ---                                  │" -ForegroundColor Cyan
    Write-Host "  │  8. llama3.1:70b    (70B)   - Meta, top quality              │" -ForegroundColor Cyan
    Write-Host "  │  9. deepseek-r1     (7B)    - DeepSeek, reasoning            │" -ForegroundColor Cyan
    Write-Host "  │                                                              │" -ForegroundColor Cyan
    Write-Host "  │  --- Code Models ---                                         │" -ForegroundColor Cyan
    Write-Host "  │  10. codellama      (7B)    - Meta, code generation          │" -ForegroundColor Cyan
    Write-Host "  │  11. starcoder2:3b  (3B)    - BigCode, coding assistant      │" -ForegroundColor Cyan
    Write-Host "  │                                                              │" -ForegroundColor Cyan
    Write-Host "  │  12. Custom model (enter name manually)                      │" -ForegroundColor Cyan
    Write-Host "  │   0. Back to main menu                                       │" -ForegroundColor Cyan
    Write-Host "  └──────────────────────────────────────────────────────────────┘" -ForegroundColor Cyan
    Write-Host ""
}

function Get-ModelName {
    param([string]$Choice)
    switch ($Choice) {
        "1"  { return "tinyllama" }
        "2"  { return "phi3:mini" }
        "3"  { return "gemma2:2b" }
        "4"  { return "llama3.2" }
        "5"  { return "mistral" }
        "6"  { return "gemma2" }
        "7"  { return "qwen2.5" }
        "8"  { return "llama3.1:70b" }
        "9"  { return "deepseek-r1" }
        "10" { return "codellama" }
        "11" { return "starcoder2:3b" }
        "12" {
            $custom = Read-Host "  Enter model name (e.g., 'llama3.2:1b')"
            return $custom.Trim()
        }
        default { return $null }
    }
}

function Test-OllamaInstalled {
    $ollamaPath = Get-Command ollama -ErrorAction SilentlyContinue
    if ($ollamaPath) {
        return $true
    }
    # Check common install locations
    $commonPaths = @(
        "$env:LOCALAPPDATA\Programs\Ollama\ollama.exe",
        "C:\Program Files\Ollama\ollama.exe",
        "$env:USERPROFILE\AppData\Local\Programs\Ollama\ollama.exe"
    )
    foreach ($path in $commonPaths) {
        if (Test-Path $path) {
            return $true
        }
    }
    return $false
}

function Get-OllamaPath {
    $ollamaCmd = Get-Command ollama -ErrorAction SilentlyContinue
    if ($ollamaCmd) {
        return $ollamaCmd.Source
    }
    $commonPaths = @(
        "$env:LOCALAPPDATA\Programs\Ollama\ollama.exe",
        "C:\Program Files\Ollama\ollama.exe"
    )
    foreach ($path in $commonPaths) {
        if (Test-Path $path) { return $path }
    }
    return "ollama"
}

function Install-Ollama {
    Write-Host ""
    if (Test-OllamaInstalled) {
        Write-Log "Ollama is already installed on this system." "SUCCESS"
        $version = & ollama --version 2>&1
        Write-Log "Version: $version" "INFO"
        Write-Host ""
        $update = Read-Host "  Do you want to update/reinstall? (y/N)"
        if ($update -ne "y" -and $update -ne "Y") {
            return $true
        }
    }

    Write-Log "Installing Ollama for Windows..." "INFO"
    Write-Host ""

    # Method 1: Try PowerShell install script (recommended, online)
    Write-Log "Downloading and installing Ollama via official installer..." "INFO"
    Write-Host ""

    try {
        # Check internet connectivity
        $testConnection = Test-NetConnection -ComputerName "ollama.com" -Port 443 -WarningAction SilentlyContinue
        if (-not $testConnection.TcpTestSucceeded) {
            Write-Log "No internet connection detected. Checking for offline installer on USB..." "WARN"
            $offlineInstaller = Join-Path $USBPath "installers\OllamaSetup.exe"
            if (Test-Path $offlineInstaller) {
                Write-Log "Found offline installer. Running..." "INFO"
                Start-Process -FilePath $offlineInstaller -Wait
                return $true
            } else {
                Write-Log "No offline installer found at: $offlineInstaller" "ERROR"
                Write-Log "Please connect to the internet or place OllamaSetup.exe in the 'installers' folder." "ERROR"
                return $false
            }
        }

        # Download and run the official installer
        Write-Log "Downloading OllamaSetup.exe..." "INFO"
        $installerPath = Join-Path $env:TEMP "OllamaSetup.exe"
        $downloadUrl = "https://ollama.com/download/OllamaSetup.exe"

        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $downloadUrl -OutFile $installerPath -UseBasicParsing

        if (Test-Path $installerPath) {
            Write-Log "Download complete. Running installer..." "SUCCESS"
            Write-Host ""
            Write-Host "  The Ollama installer window will open." -ForegroundColor Yellow
            Write-Host "  Please follow the installation prompts." -ForegroundColor Yellow
            Write-Host "  The script will continue after installation completes." -ForegroundColor Yellow
            Write-Host ""

            Start-Process -FilePath $installerPath -Wait

            # Refresh PATH
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

            Start-Sleep -Seconds 3

            if (Test-OllamaInstalled) {
                Write-Log "Ollama installed successfully!" "SUCCESS"
                return $true
            } else {
                Write-Log "Installation may have completed. Please restart this script if ollama is not found." "WARN"
                return $true
            }
        }
    }
    catch {
        Write-Log "Error during installation: $_" "ERROR"

        # Fallback: Try PowerShell one-liner
        Write-Log "Trying alternative installation method..." "INFO"
        try {
            Invoke-Expression (Invoke-RestMethod -Uri "https://ollama.com/install.ps1")
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
            if (Test-OllamaInstalled) {
                Write-Log "Ollama installed successfully via PowerShell script!" "SUCCESS"
                return $true
            }
        }
        catch {
            Write-Log "Alternative installation also failed: $_" "ERROR"
            return $false
        }
    }
    return $false
}

function Start-OllamaServer {
    Write-Log "Starting Ollama server..." "INFO"

    # Check if server is already running
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:11434" -UseBasicParsing -TimeoutSec 3 -ErrorAction Stop
        if ($response.StatusCode -eq 200) {
            Write-Log "Ollama server is already running at http://localhost:11434" "SUCCESS"
            return $true
        }
    } catch {
        # Server not running, start it
    }

    $ollamaPath = Get-OllamaPath
    Write-Log "Starting server with: $ollamaPath serve" "INFO"
    Start-Process -FilePath $ollamaPath -ArgumentList "serve" -WindowStyle Minimized
    Start-Sleep -Seconds 5

    # Verify server started
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:11434" -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop
        Write-Log "Ollama server started successfully at http://localhost:11434" "SUCCESS"
        return $true
    } catch {
        Write-Log "Failed to verify server startup. It may still be initializing..." "WARN"
        return $true
    }
}

function Pull-Model {
    param([string]$ModelName)

    if (-not $ModelName) {
        Write-Log "No model name specified." "ERROR"
        return $false
    }

    Write-Log "Pulling model: $ModelName (this may take a while)..." "INFO"
    Write-Host ""
    Write-Host "  Downloading model '$ModelName'..." -ForegroundColor Yellow
    Write-Host "  This can take several minutes depending on model size and internet speed." -ForegroundColor Yellow
    Write-Host ""

    # Ensure server is running
    Start-OllamaServer | Out-Null

    $ollamaPath = Get-OllamaPath
    & $ollamaPath pull $ModelName

    if ($LASTEXITCODE -eq 0) {
        Write-Log "Model '$ModelName' downloaded successfully!" "SUCCESS"
        return $true
    } else {
        Write-Log "Failed to download model '$ModelName'." "ERROR"
        return $false
    }
}

function Start-Chat {
    param([string]$ModelName)

    if (-not $ModelName) {
        # List available models
        Write-Log "Checking available models..." "INFO"
        $ollamaPath = Get-OllamaPath
        Write-Host ""
        & $ollamaPath list
        Write-Host ""
        $ModelName = Read-Host "  Enter model name to chat with"
    }

    if (-not $ModelName) {
        Write-Log "No model specified." "ERROR"
        return
    }

    Start-OllamaServer | Out-Null

    Write-Host ""
    Write-Host "  ============================================================" -ForegroundColor Green
    Write-Host "  Starting chat with: $ModelName" -ForegroundColor Green
    Write-Host "  Type '/bye' to exit the chat" -ForegroundColor Green
    Write-Host "  ============================================================" -ForegroundColor Green
    Write-Host ""

    $ollamaPath = Get-OllamaPath
    & $ollamaPath run $ModelName
}

function Show-SystemInfo {
    Write-Host ""
    Write-Host "  ============================================================" -ForegroundColor Cyan
    Write-Host "  SYSTEM INFORMATION" -ForegroundColor Cyan
    Write-Host "  ============================================================" -ForegroundColor Cyan
    Write-Host ""

    # OS Info
    $os = Get-CimInstance Win32_OperatingSystem
    Write-Host "  OS         : $($os.Caption) $($os.Version)" -ForegroundColor White
    Write-Host "  Architecture: $($env:PROCESSOR_ARCHITECTURE)" -ForegroundColor White

    # RAM
    $totalRAM = [math]::Round($os.TotalVisibleMemorySize / 1MB, 1)
    $freeRAM = [math]::Round($os.FreePhysicalMemory / 1MB, 1)
    Write-Host "  Total RAM  : $totalRAM GB" -ForegroundColor White
    Write-Host "  Free RAM   : $freeRAM GB" -ForegroundColor White

    # CPU
    $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
    Write-Host "  CPU        : $($cpu.Name)" -ForegroundColor White
    Write-Host "  Cores      : $($cpu.NumberOfCores) cores / $($cpu.NumberOfLogicalProcessors) threads" -ForegroundColor White

    # GPU Check
    Write-Host ""
    Write-Host "  --- GPU Information ---" -ForegroundColor Yellow
    $gpus = Get-CimInstance Win32_VideoController
    foreach ($gpu in $gpus) {
        $vram = [math]::Round($gpu.AdapterRAM / 1GB, 1)
        Write-Host "  GPU        : $($gpu.Name)" -ForegroundColor White
        Write-Host "  VRAM       : $vram GB" -ForegroundColor White
        Write-Host "  Driver     : $($gpu.DriverVersion)" -ForegroundColor White
        Write-Host ""
    }

    # NVIDIA check
    $nvidiaSmi = Get-Command nvidia-smi -ErrorAction SilentlyContinue
    if ($nvidiaSmi) {
        Write-Host "  --- NVIDIA GPU Details ---" -ForegroundColor Yellow
        & nvidia-smi --query-gpu=name,memory.total,memory.free,driver_version --format=csv,noheader
        Write-Host ""
    }

    # Disk space
    Write-Host "  --- Disk Space ---" -ForegroundColor Yellow
    $drives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Used -ne $null }
    foreach ($drive in $drives) {
        $total = [math]::Round($drive.Used / 1GB + $drive.Free / 1GB, 1)
        $free = [math]::Round($drive.Free / 1GB, 1)
        Write-Host "  Drive $($drive.Name): $free GB free / $total GB total" -ForegroundColor White
    }

    # Model recommendation
    Write-Host ""
    Write-Host "  --- Model Recommendation ---" -ForegroundColor Green
    if ($totalRAM -ge 32) {
        Write-Host "  Your system can run large models (up to 70B parameters)" -ForegroundColor Green
        Write-Host "  Recommended: llama3.1:70b, deepseek-r1" -ForegroundColor Green
    } elseif ($totalRAM -ge 16) {
        Write-Host "  Your system can run medium-large models (7-13B parameters)" -ForegroundColor Green
        Write-Host "  Recommended: mistral, gemma2, qwen2.5, llama3.2" -ForegroundColor Green
    } elseif ($totalRAM -ge 8) {
        Write-Host "  Your system can run small-medium models (3-7B parameters)" -ForegroundColor Green
        Write-Host "  Recommended: phi3:mini, llama3.2, gemma2:2b" -ForegroundColor Green
    } else {
        Write-Host "  Limited RAM detected. Use lightweight models only." -ForegroundColor Yellow
        Write-Host "  Recommended: tinyllama, gemma2:2b" -ForegroundColor Yellow
    }
    Write-Host ""
}

function Set-PortableMode {
    Write-Host ""
    Write-Host "  ============================================================" -ForegroundColor Yellow
    Write-Host "  PORTABLE MODE - Store Models on USB" -ForegroundColor Yellow
    Write-Host "  ============================================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  This will configure Ollama to store models on the USB drive." -ForegroundColor White
    Write-Host "  Models path: $ModelsDir" -ForegroundColor White
    Write-Host ""
    Write-Host "  NOTE: LLM models are large (2-40+ GB). Ensure your USB has" -ForegroundColor Yellow
    Write-Host "  enough space and is USB 3.0+ for reasonable performance." -ForegroundColor Yellow
    Write-Host ""

    $confirm = Read-Host "  Enable portable mode? (y/N)"
    if ($confirm -eq "y" -or $confirm -eq "Y") {
        if (-not (Test-Path $ModelsDir)) {
            New-Item -ItemType Directory -Path $ModelsDir -Force | Out-Null
        }

        # Set environment variable for current session
        $env:OLLAMA_MODELS = $ModelsDir

        # Set for user permanently
        [System.Environment]::SetEnvironmentVariable("OLLAMA_MODELS", $ModelsDir, "User")

        Write-Log "Portable mode enabled! Models will be stored at: $ModelsDir" "SUCCESS"
        Write-Log "Environment variable OLLAMA_MODELS set for your user account." "SUCCESS"
        Write-Host ""
        Write-Host "  To revert, remove the OLLAMA_MODELS environment variable" -ForegroundColor Gray
        Write-Host "  from your user settings." -ForegroundColor Gray
    } else {
        Write-Log "Portable mode not enabled." "INFO"
    }
    Write-Host ""
}

function Install-OpenWebUI {
    Write-Host ""
    Write-Host "  ============================================================" -ForegroundColor Cyan
    Write-Host "  OPEN WEBUI - Browser-Based Chat Interface" -ForegroundColor Cyan
    Write-Host "  ============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Open WebUI provides a ChatGPT-like interface for Ollama." -ForegroundColor White
    Write-Host "  It requires Python 3.11+ or Docker." -ForegroundColor White
    Write-Host ""
    Write-Host "  Choose installation method:" -ForegroundColor White
    Write-Host "  1. Docker (recommended, if Docker is installed)" -ForegroundColor White
    Write-Host "  2. Python pip install" -ForegroundColor White
    Write-Host "  3. Skip / Go back" -ForegroundColor White
    Write-Host ""

    $method = Read-Host "  Select (1-3)"

    switch ($method) {
        "1" {
            $docker = Get-Command docker -ErrorAction SilentlyContinue
            if (-not $docker) {
                Write-Log "Docker is not installed. Please install Docker Desktop first." "ERROR"
                Write-Host "  Download from: https://www.docker.com/products/docker-desktop/" -ForegroundColor Yellow
                return
            }
            Write-Log "Starting Open WebUI via Docker..." "INFO"
            & docker run -d -p 3000:8080 --add-host=host.docker.internal:host-gateway -v open-webui:/app/backend/data --name open-webui --restart always ghcr.io/open-webui/open-webui:main
            Write-Log "Open WebUI started! Access it at: http://localhost:3000" "SUCCESS"
        }
        "2" {
            $python = Get-Command python -ErrorAction SilentlyContinue
            if (-not $python) {
                $python = Get-Command python3 -ErrorAction SilentlyContinue
            }
            if (-not $python) {
                Write-Log "Python is not installed. Please install Python 3.11+ first." "ERROR"
                Write-Host "  Download from: https://www.python.org/downloads/" -ForegroundColor Yellow
                return
            }
            Write-Log "Installing Open WebUI via pip..." "INFO"
            & pip install open-webui
            Write-Log "Starting Open WebUI..." "INFO"
            Start-Process -FilePath "open-webui" -ArgumentList "serve" -WindowStyle Normal
            Write-Log "Open WebUI started! Access it at: http://localhost:8080" "SUCCESS"
        }
        default {
            return
        }
    }
    Write-Host ""
}

function Uninstall-Ollama {
    Write-Host ""
    Write-Host "  WARNING: This will uninstall Ollama from this system." -ForegroundColor Red
    $confirm = Read-Host "  Are you sure? (y/N)"
    if ($confirm -eq "y" -or $confirm -eq "Y") {
        Write-Log "Uninstalling Ollama..." "INFO"

        # Stop Ollama processes
        Get-Process -Name "ollama*" -ErrorAction SilentlyContinue | Stop-Process -Force

        # Try to run uninstaller
        $uninstaller = "$env:LOCALAPPDATA\Programs\Ollama\unins000.exe"
        if (Test-Path $uninstaller) {
            Start-Process -FilePath $uninstaller -Wait
            Write-Log "Ollama uninstalled via official uninstaller." "SUCCESS"
        } else {
            Write-Log "Official uninstaller not found. Please uninstall via Windows Settings > Apps." "WARN"
        }
    }
    Write-Host ""
}

# ============================================================================
#  MAIN PROGRAM LOOP
# ============================================================================

Show-Banner

# Main menu loop
$running = $true
while ($running) {
    Show-Menu
    $choice = Read-Host "  Select an option (0-9)"

    switch ($choice) {
        "1" {
            # Full install: Ollama + Model
            $installed = Install-Ollama
            if ($installed) {
                Start-OllamaServer | Out-Null
                Show-ModelMenu
                $modelChoice = Read-Host "  Select a model (0-12)"
                if ($modelChoice -ne "0") {
                    $modelName = Get-ModelName -Choice $modelChoice
                    if ($modelName) {
                        Pull-Model -ModelName $modelName
                        Write-Host ""
                        $startChat = Read-Host "  Start chatting with $modelName now? (Y/n)"
                        if ($startChat -ne "n" -and $startChat -ne "N") {
                            Start-Chat -ModelName $modelName
                        }
                    }
                }
            }
        }
        "2" {
            # Install Ollama only
            Install-Ollama
        }
        "3" {
            # Download model
            if (-not (Test-OllamaInstalled)) {
                Write-Log "Ollama is not installed. Please install it first (Option 1 or 2)." "ERROR"
            } else {
                Start-OllamaServer | Out-Null
                Show-ModelMenu
                $modelChoice = Read-Host "  Select a model (0-12)"
                if ($modelChoice -ne "0") {
                    $modelName = Get-ModelName -Choice $modelChoice
                    if ($modelName) { Pull-Model -ModelName $modelName }
                }
            }
        }
        "4" {
            # Start chat
            if (-not (Test-OllamaInstalled)) {
                Write-Log "Ollama is not installed. Please install it first." "ERROR"
            } else {
                Start-Chat
            }
        }
        "5" {
            # Start server
            if (-not (Test-OllamaInstalled)) {
                Write-Log "Ollama is not installed. Please install it first." "ERROR"
            } else {
                Start-OllamaServer
                Write-Host ""
                Write-Host "  Ollama API is running at: http://localhost:11434" -ForegroundColor Green
                Write-Host "  Press any key to return to menu..." -ForegroundColor Gray
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
        }
        "6" {
            # Install Open WebUI
            Install-OpenWebUI
        }
        "7" {
            # System info
            Show-SystemInfo
            Write-Host "  Press any key to return to menu..." -ForegroundColor Gray
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        "8" {
            # Portable mode
            Set-PortableMode
        }
        "9" {
            # Uninstall
            Uninstall-Ollama
        }
        "0" {
            Write-Host ""
            Write-Host "  Thank you for using Ollama USB Toolkit!" -ForegroundColor Green
            Write-Host "  Happy chatting with your local LLM!" -ForegroundColor Green
            Write-Host ""
            $running = $false
        }
        default {
            Write-Host "  Invalid option. Please try again." -ForegroundColor Red
        }
    }
}
