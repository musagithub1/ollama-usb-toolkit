#!/usr/bin/env bash
# ============================================================================
#  OLLAMA USB TOOLKIT - Linux Installer & Launcher
#  Installs Ollama + Open-Source LLM on any Linux system
# ============================================================================

set -euo pipefail

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;37m'
NC='\033[0m' # No Color

# --- Get USB path (where this script lives) ---
USB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="${USB_DIR}/scripts"
MODELS_DIR="${USB_DIR}/models"
CONFIG_DIR="${USB_DIR}/config"
LOG_DIR="${USB_DIR}/logs"
DATA_DIR="${USB_DIR}/data"

mkdir -p "${LOG_DIR}" "${DATA_DIR}"

# --- Force all app data to stay on the USB (Linux portability) ---
# Without these, apps like Electron/Open WebUI write to ~/.config on the host PC.
export OLLAMA_MODELS="${MODELS_DIR}"
export OLLAMA_ORIGINS="*"   # Allow Web UI requests from local HTTP server (fixes CORS)
export XDG_CONFIG_HOME="${DATA_DIR}/config"
export XDG_DATA_HOME="${DATA_DIR}/share"
export XDG_CACHE_HOME="${DATA_DIR}/cache"
mkdir -p "${XDG_CONFIG_HOME}" "${XDG_DATA_HOME}" "${XDG_CACHE_HOME}"
LOG_FILE="${LOG_DIR}/install-$(date +%Y%m%d-%H%M%S).log"

# --- Helper Functions ---
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp
    timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"

    case "$level" in
        INFO)    echo -e "  ${CYAN}[INFO]${NC} $message" ;;
        SUCCESS) echo -e "  ${GREEN}[OK]${NC}   $message" ;;
        WARN)    echo -e "  ${YELLOW}[WARN]${NC} $message" ;;
        ERROR)   echo -e "  ${RED}[ERR]${NC}  $message" ;;
    esac
}

show_banner() {
    local version
    version=$(cat "${USB_DIR}/VERSION" 2>/dev/null || echo "1.2.0")
    echo ""
    echo -e "  ${GREEN}============================================================${NC}"
    echo -e "  ${GREEN}     OLLAMA USB TOOLKIT v${version} - LLM Installer${NC}"
    echo -e "  ${GREEN}============================================================${NC}"
    echo ""
    echo -e "  ${GRAY}OS      : $(uname -s) $(uname -r) ($(uname -m))${NC}"
    echo -e "  ${GRAY}Distro  : $(cat /etc/os-release 2>/dev/null | grep PRETTY_NAME | cut -d'"' -f2 || echo 'Unknown')${NC}"

    local total_ram
    total_ram=$(awk '/MemTotal/ {printf "%.1f", $2/1024/1024}' /proc/meminfo 2>/dev/null || echo "Unknown")
    echo -e "  ${GRAY}RAM     : ${total_ram} GB${NC}"
    echo -e "  ${GRAY}USB Path: ${USB_DIR}${NC}"
    echo ""
}

show_menu() {
    echo ""
    echo -e "  ${WHITE}┌──────────────────────────────────────────────┐${NC}"
    echo -e "  ${WHITE}│           MAIN MENU - Choose Action          │${NC}"
    echo -e "  ${WHITE}├──────────────────────────────────────────────┤${NC}"
    echo -e "  ${WHITE}│  1. Install Ollama + Download LLM Model      │${NC}"
    echo -e "  ${WHITE}│  2. Install Ollama Only                      │${NC}"
    echo -e "  ${WHITE}│  3. Download/Change LLM Model                │${NC}"
    echo -e "  ${WHITE}│  4. Start Chat with LLM                      │${NC}"
    echo -e "  ${WHITE}│  5. Start Ollama Server (API mode)           │${NC}"
    echo -e "  ${WHITE}│  6. Install Open WebUI (Browser Chat)        │${NC}"
    echo -e "  ${WHITE}│  7. System Info & GPU Check                  │${NC}"
    echo -e "  ${WHITE}│  8. Store Models on USB (Portable Mode)      │${NC}"
    echo -e "  ${WHITE}│  9. Uninstall Ollama                         │${NC}"
    echo -e "  ${WHITE}├──────────────────────────────────────────────┤${NC}"
    echo -e "  ${WHITE}│  ${CYAN}🦞 Claw Edition (v2.0)${WHITE}                       │${NC}"
    echo -e "  ${WHITE}│  A. Start Claw Agent (terminal)              │${NC}"
    echo -e "  ${WHITE}│  B. Start Claw Agent API + open Web UI       │${NC}"
    echo -e "  ${WHITE}│  C. Doctor (validate workspace)              │${NC}"
    echo -e "  ${WHITE}├──────────────────────────────────────────────┤${NC}"
    echo -e "  ${WHITE}│  0. Exit                                     │${NC}"
    echo -e "  ${WHITE}└──────────────────────────────────────────────┘${NC}"
    echo ""
}

show_model_menu() {
    echo ""
    echo -e "  ${CYAN}┌──────────────────────────────────────────────────────────────┐${NC}"
    echo -e "  ${CYAN}│              SELECT A MODEL TO DOWNLOAD                      │${NC}"
    echo -e "  ${CYAN}├──────────────────────────────────────────────────────────────┤${NC}"
    echo -e "  ${CYAN}│                                                              │${NC}"
    echo -e "  ${CYAN}│  --- Lightweight (2-4 GB RAM) ---                            │${NC}"
    echo -e "  ${CYAN}│  1. tinyllama       (1.1B)  - Fast, lightweight              │${NC}"
    echo -e "  ${CYAN}│  2. phi3:mini       (3.8B)  - Microsoft, great quality       │${NC}"
    echo -e "  ${CYAN}│  3. gemma2:2b       (2.6B)  - Google, compact               │${NC}"
    echo -e "  ${CYAN}│                                                              │${NC}"
    echo -e "  ${CYAN}│  --- Medium (8 GB RAM) ---                                   │${NC}"
    echo -e "  ${CYAN}│  4. llama3.2        (3B)    - Meta, latest Llama             │${NC}"
    echo -e "  ${CYAN}│  5. mistral         (7B)    - Mistral AI, versatile          │${NC}"
    echo -e "  ${CYAN}│  6. gemma2          (9B)    - Google, powerful               │${NC}"
    echo -e "  ${CYAN}│  7. qwen2.5         (7B)    - Alibaba, multilingual          │${NC}"
    echo -e "  ${CYAN}│                                                              │${NC}"
    echo -e "  ${CYAN}│  --- Large (16+ GB RAM) ---                                  │${NC}"
    echo -e "  ${CYAN}│  8. llama3.1:70b    (70B)   - Meta, top quality              │${NC}"
    echo -e "  ${CYAN}│  9. deepseek-r1     (7B)    - DeepSeek, reasoning            │${NC}"
    echo -e "  ${CYAN}│                                                              │${NC}"
    echo -e "  ${CYAN}│  --- Code Models ---                                         │${NC}"
    echo -e "  ${CYAN}│  10. codellama      (7B)    - Meta, code generation          │${NC}"
    echo -e "  ${CYAN}│  11. starcoder2:3b  (3B)    - BigCode, coding assistant      │${NC}"
    echo -e "  ${CYAN}│                                                              │${NC}"
    echo -e "  ${CYAN}│  12. Custom model (enter name manually)                      │${NC}"
    echo -e "  ${CYAN}│   0. Back to main menu                                       │${NC}"
    echo -e "  ${CYAN}└──────────────────────────────────────────────────────────────┘${NC}"
    echo ""
}

get_model_name() {
    local choice="$1"
    case "$choice" in
        1)  echo "tinyllama" ;;
        2)  echo "phi3:mini" ;;
        3)  echo "gemma2:2b" ;;
        4)  echo "llama3.2" ;;
        5)  echo "mistral" ;;
        6)  echo "gemma2" ;;
        7)  echo "qwen2.5" ;;
        8)  echo "llama3.1:70b" ;;
        9)  echo "deepseek-r1" ;;
        10) echo "codellama" ;;
        11) echo "starcoder2:3b" ;;
        12)
            read -rp "  Enter model name (e.g., 'llama3.2:1b'): " custom_model
            echo "$custom_model"
            ;;
        *)  echo "" ;;
    esac
}

check_ollama_installed() {
    if command -v ollama &>/dev/null; then
        return 0
    fi
    # Check common locations
    for path in /usr/local/bin/ollama /usr/bin/ollama "$HOME/.local/bin/ollama"; do
        if [ -x "$path" ]; then
            return 0
        fi
    done
    return 1
}

get_ollama_path() {
    if command -v ollama &>/dev/null; then
        command -v ollama
        return
    fi
    for path in /usr/local/bin/ollama /usr/bin/ollama "$HOME/.local/bin/ollama"; do
        if [ -x "$path" ]; then
            echo "$path"
            return
        fi
    done
    echo "ollama"
}

install_ollama() {
    echo ""
    if check_ollama_installed; then
        log SUCCESS "Ollama is already installed on this system."
        local version
        version="$(ollama --version 2>&1 || true)"
        log INFO "Version: $version"
        echo ""
        read -rp "  Do you want to update/reinstall? (y/N): " update_choice
        if [[ "$update_choice" != "y" && "$update_choice" != "Y" ]]; then
            return 0
        fi
    fi

    log INFO "Installing Ollama for Linux..."
    echo ""

    # Check for internet connectivity
    if ! curl -s --connect-timeout 5 https://ollama.com > /dev/null 2>&1; then
        log WARN "No internet connection detected."

        # Check for offline binary on USB
        local offline_binary="${USB_DIR}/installers/ollama-linux-amd64.tar.zst"
        local offline_binary_gz="${USB_DIR}/installers/ollama-linux-amd64.tgz"

        if [ -f "$offline_binary" ]; then
            log INFO "Found offline installer. Installing from USB..."
            sudo tar x -C /usr -f "$offline_binary"
            log SUCCESS "Ollama installed from offline package!"
            return 0
        elif [ -f "$offline_binary_gz" ]; then
            log INFO "Found offline installer (tgz). Installing from USB..."
            sudo tar xzf "$offline_binary_gz" -C /usr
            log SUCCESS "Ollama installed from offline package!"
            return 0
        else
            log ERROR "No offline installer found."
            log ERROR "Please connect to the internet or place the Ollama binary in the 'installers' folder."
            return 1
        fi
    fi

    # Online installation
    log INFO "Downloading and installing Ollama via official script..."
    echo ""

    # Check if we have sudo access
    if sudo -n true 2>/dev/null; then
        log INFO "Running with sudo privileges..."
    else
        log WARN "This installation requires sudo privileges."
        log INFO "You may be prompted for your password."
        echo ""
    fi

    # Run the official install script
    curl -fsSL https://ollama.com/install.sh | sh

    if check_ollama_installed; then
        log SUCCESS "Ollama installed successfully!"
        return 0
    else
        log ERROR "Installation may have failed. Please check the output above."
        return 1
    fi
}

start_ollama_server() {
    log INFO "Starting Ollama server..."

    # Check if already running
    if curl -s http://localhost:11434 > /dev/null 2>&1; then
        log SUCCESS "Ollama server is already running at http://localhost:11434"
        return 0
    fi

    local ollama_path
    ollama_path="$(get_ollama_path)"

    # Start server in background
    nohup "$ollama_path" serve > "${LOG_DIR}/ollama-server.log" 2>&1 &
    local server_pid=$!
    echo "$server_pid" > "${LOG_DIR}/ollama-server.pid"

    # Wait for server to start
    local retries=0
    while [ $retries -lt 15 ]; do
        if curl -s http://localhost:11434 > /dev/null 2>&1; then
            log SUCCESS "Ollama server started (PID: $server_pid) at http://localhost:11434"
            return 0
        fi
        sleep 1
        retries=$((retries + 1))
    done

    log WARN "Server may still be starting. Check logs at: ${LOG_DIR}/ollama-server.log"
    return 0
}

pull_model() {
    local model_name="$1"

    if [ -z "$model_name" ]; then
        log ERROR "No model name specified."
        return 1
    fi

    log INFO "Pulling model: $model_name (this may take a while)..."
    echo ""
    echo -e "  ${YELLOW}Downloading model '$model_name'...${NC}"
    echo -e "  ${YELLOW}This can take several minutes depending on model size and internet speed.${NC}"
    echo ""

    # Ensure server is running
    start_ollama_server > /dev/null 2>&1 || true

    local ollama_path
    ollama_path="$(get_ollama_path)"

    "$ollama_path" pull "$model_name"

    if [ $? -eq 0 ]; then
        log SUCCESS "Model '$model_name' downloaded successfully!"
        return 0
    else
        log ERROR "Failed to download model '$model_name'."
        return 1
    fi
}

start_chat() {
    local model_name="${1:-}"

    if [ -z "$model_name" ]; then
        log INFO "Checking available models..."
        local ollama_path
        ollama_path="$(get_ollama_path)"
        echo ""
        "$ollama_path" list 2>/dev/null || echo "  No models found."
        echo ""
        read -rp "  Enter model name to chat with: " model_name
    fi

    if [ -z "$model_name" ]; then
        log ERROR "No model specified."
        return 1
    fi

    start_ollama_server > /dev/null 2>&1 || true

    echo ""
    echo -e "  ${GREEN}============================================================${NC}"
    echo -e "  ${GREEN}  Starting chat with: $model_name${NC}"
    echo -e "  ${GREEN}  Type '/bye' to exit the chat${NC}"
    echo -e "  ${GREEN}============================================================${NC}"
    echo ""

    local ollama_path
    ollama_path="$(get_ollama_path)"
    "$ollama_path" run "$model_name"
}

show_system_info() {
    echo ""
    echo -e "  ${CYAN}============================================================${NC}"
    echo -e "  ${CYAN}  SYSTEM INFORMATION${NC}"
    echo -e "  ${CYAN}============================================================${NC}"
    echo ""

    # OS Info
    echo -e "  ${WHITE}OS         : $(uname -s) $(uname -r)${NC}"
    echo -e "  ${WHITE}Distro     : $(cat /etc/os-release 2>/dev/null | grep PRETTY_NAME | cut -d'"' -f2 || echo 'Unknown')${NC}"
    echo -e "  ${WHITE}Arch       : $(uname -m)${NC}"

    # RAM
    local total_ram free_ram
    total_ram=$(awk '/MemTotal/ {printf "%.1f", $2/1024/1024}' /proc/meminfo)
    free_ram=$(awk '/MemAvailable/ {printf "%.1f", $2/1024/1024}' /proc/meminfo)
    echo -e "  ${WHITE}Total RAM  : ${total_ram} GB${NC}"
    echo -e "  ${WHITE}Free RAM   : ${free_ram} GB${NC}"

    # CPU
    local cpu_model cpu_cores
    cpu_model=$(grep "model name" /proc/cpuinfo | head -1 | cut -d':' -f2 | xargs)
    cpu_cores=$(nproc)
    echo -e "  ${WHITE}CPU        : ${cpu_model}${NC}"
    echo -e "  ${WHITE}Cores      : ${cpu_cores}${NC}"

    # GPU Check
    echo ""
    echo -e "  ${YELLOW}--- GPU Information ---${NC}"

    # NVIDIA
    if command -v nvidia-smi &>/dev/null; then
        echo -e "  ${WHITE}NVIDIA GPU detected:${NC}"
        nvidia-smi --query-gpu=name,memory.total,memory.free,driver_version --format=csv,noheader 2>/dev/null || echo "  Could not query NVIDIA GPU"
    fi

    # AMD
    if [ -d /sys/class/drm ]; then
        for card in /sys/class/drm/card*/device/vendor; do
            if [ -f "$card" ] && grep -q "0x1002" "$card" 2>/dev/null; then
                echo -e "  ${WHITE}AMD GPU detected${NC}"
                break
            fi
        done
    fi

    # Intel
    if lspci 2>/dev/null | grep -i "vga\|3d\|display" | grep -iq "intel"; then
        echo -e "  ${WHITE}Intel GPU: $(lspci | grep -i 'vga\|3d\|display' | grep -i intel | cut -d':' -f3 | xargs)${NC}"
    fi

    if ! command -v nvidia-smi &>/dev/null; then
        echo -e "  ${GRAY}No dedicated NVIDIA GPU detected. Ollama will use CPU.${NC}"
    fi

    # Disk space
    echo ""
    echo -e "  ${YELLOW}--- Disk Space ---${NC}"
    df -h / | tail -1 | awk '{printf "  Root (/): %s free / %s total (%s used)\n", $4, $2, $5}'
    df -h "$USB_DIR" | tail -1 | awk -v usb="$USB_DIR" '{printf "  USB (%s): %s free / %s total\n", usb, $4, $2}'

    # Model recommendation
    echo ""
    echo -e "  ${GREEN}--- Model Recommendation ---${NC}"
    local ram_gb
    ram_gb=$(awk '/MemTotal/ {printf "%d", $2/1024/1024}' /proc/meminfo)

    if [ "$ram_gb" -ge 32 ]; then
        echo -e "  ${GREEN}Your system can run large models (up to 70B parameters)${NC}"
        echo -e "  ${GREEN}Recommended: llama3.1:70b, deepseek-r1${NC}"
    elif [ "$ram_gb" -ge 16 ]; then
        echo -e "  ${GREEN}Your system can run medium-large models (7-13B parameters)${NC}"
        echo -e "  ${GREEN}Recommended: mistral, gemma2, qwen2.5, llama3.2${NC}"
    elif [ "$ram_gb" -ge 8 ]; then
        echo -e "  ${GREEN}Your system can run small-medium models (3-7B parameters)${NC}"
        echo -e "  ${GREEN}Recommended: phi3:mini, llama3.2, gemma2:2b${NC}"
    else
        echo -e "  ${YELLOW}Limited RAM detected. Use lightweight models only.${NC}"
        echo -e "  ${YELLOW}Recommended: tinyllama, gemma2:2b${NC}"
    fi
    echo ""
}

set_portable_mode() {
    echo ""
    echo -e "  ${YELLOW}============================================================${NC}"
    echo -e "  ${YELLOW}  PORTABLE MODE - Store Models on USB${NC}"
    echo -e "  ${YELLOW}============================================================${NC}"
    echo ""
    echo -e "  ${WHITE}This will configure Ollama to store models on the USB drive.${NC}"
    echo -e "  ${WHITE}Models path: ${MODELS_DIR}${NC}"
    echo ""
    echo -e "  ${YELLOW}NOTE: LLM models are large (2-40+ GB). Ensure your USB has${NC}"
    echo -e "  ${YELLOW}enough space and is USB 3.0+ for reasonable performance.${NC}"
    echo ""

    read -rp "  Enable portable mode? (y/N): " confirm
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        mkdir -p "$MODELS_DIR"

        # Set for current session ONLY.
        # NOTE: We intentionally do NOT write to ~/.bashrc because the USB mount
        # path changes between computers (e.g. /media/userA/USB vs /media/userB/USB).
        # Writing the absolute path to .bashrc would break on every other machine.
        export OLLAMA_MODELS="$MODELS_DIR"

        log SUCCESS "Portable mode enabled for this session!"
        log INFO "Models will be stored at: $MODELS_DIR"
        echo ""
        echo -e "  ${YELLOW}⚠  IMPORTANT: Portable mode is active for this session only.${NC}"
        echo -e "  ${GRAY}   This path is NOT saved permanently — USB mount paths differ${NC}"
        echo -e "  ${GRAY}   between computers, so saving it would break on other PCs.${NC}"
        echo -e "  ${GRAY}   Just re-select Option 8 each time you plug into a new PC.${NC}"

        # Restart server if running so it picks up the new OLLAMA_MODELS path
        if curl -s http://localhost:11434 > /dev/null 2>&1; then
            log INFO "Restarting Ollama server to use new model path..."
            pkill -f "ollama serve" 2>/dev/null || true
            sleep 2
            start_ollama_server
        fi
    else
        log INFO "Portable mode not enabled."
    fi
    echo ""
}

install_open_webui() {
    echo ""
    echo -e "  ${CYAN}============================================================${NC}"
    echo -e "  ${CYAN}  OPEN WEBUI - Browser-Based Chat Interface${NC}"
    echo -e "  ${CYAN}============================================================${NC}"
    echo ""
    echo -e "  ${WHITE}Choose your Web UI option:${NC}"
    echo -e "  ${WHITE}1. Built-in Web UI (Recommended — no install needed)${NC}"
    echo -e "     ${GRAY}Serves webui/index.html via Python's built-in HTTP server.${NC}"
    echo -e "     ${GRAY}Required for chat to work — file:// protocol blocks the API.${NC}"
    echo -e "  ${WHITE}2. Open WebUI via Docker (full-featured, requires Docker)${NC}"
    echo -e "  ${WHITE}3. Open WebUI via pip (requires Python 3.11+)${NC}"
    echo -e "  ${WHITE}0. Go back${NC}"
    echo ""

    read -rp "  Select (0-3): " method

    case "$method" in
        1)
            # Serve the built-in Web UI with Python's HTTP server
            if ! command -v python3 &>/dev/null; then
                log ERROR "Python 3 is not installed. Please install it first."
                return 1
            fi

            # Find a free port (default 8080, fallback to 8081+)
            local port=8080
            while lsof -i :"$port" &>/dev/null 2>&1; do
                port=$((port + 1))
            done

            # Kill any previous instance we started
            pkill -f "python3 -m http.server.*${USB_DIR}" 2>/dev/null || true
            sleep 0.5

            log INFO "Starting built-in Web UI server on port ${port}..."
            nohup python3 -m http.server "$port" \
                --directory "${USB_DIR}" \
                > "${LOG_DIR}/webui-server.log" 2>&1 &
            local server_pid=$!
            echo "$server_pid" > "${LOG_DIR}/webui-server.pid"
            sleep 1

            local url="http://localhost:${port}/webui/index.html"
            log SUCCESS "Web UI is running at: ${url}"
            echo ""
            echo -e "  ${GREEN}Opening in browser...${NC}"
            xdg-open "$url" 2>/dev/null || \
                (command -v firefox &>/dev/null && firefox "$url" &) || \
                (command -v chromium-browser &>/dev/null && chromium-browser "$url" &) || \
                log WARN "Could not auto-open browser. Navigate to: ${url}"
            ;;
        2)
            if ! command -v docker &>/dev/null; then
                log ERROR "Docker is not installed."
                echo -e "  ${YELLOW}Install Docker: https://docs.docker.com/engine/install/${NC}"
                return 1
            fi
            log INFO "Starting Open WebUI via Docker..."
            docker run -d \
                -p 3000:8080 \
                --add-host=host.docker.internal:host-gateway \
                -v open-webui:/app/backend/data \
                --name open-webui \
                --restart always \
                ghcr.io/open-webui/open-webui:main
            log SUCCESS "Open WebUI started! Access it at: http://localhost:3000"
            ;;
        3)
            if ! command -v python3 &>/dev/null && ! command -v python &>/dev/null; then
                log ERROR "Python is not installed. Please install Python 3.11+ first."
                return 1
            fi
            log INFO "Installing Open WebUI via pip..."
            pip3 install open-webui || pip install open-webui
            log INFO "Starting Open WebUI..."
            nohup open-webui serve > "${LOG_DIR}/open-webui.log" 2>&1 &
            log SUCCESS "Open WebUI started! Access it at: http://localhost:8080"
            ;;
        *)
            return 0
            ;;
    esac
    echo ""
}

uninstall_ollama() {
    echo ""
    echo -e "  ${RED}WARNING: This will uninstall Ollama from this system.${NC}"
    read -rp "  Are you sure? (y/N): " confirm
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        log INFO "Uninstalling Ollama..."

        # Stop Ollama
        sudo systemctl stop ollama 2>/dev/null || true
        sudo systemctl disable ollama 2>/dev/null || true
        pkill -f "ollama" 2>/dev/null || true

        # Remove service file
        sudo rm -f /etc/systemd/system/ollama.service
        sudo systemctl daemon-reload 2>/dev/null || true

        # Remove binary
        sudo rm -f "$(which ollama 2>/dev/null)" 2>/dev/null || true
        sudo rm -f /usr/local/bin/ollama /usr/bin/ollama 2>/dev/null || true

        # Remove libraries
        sudo rm -rf /usr/lib/ollama /usr/local/lib/ollama 2>/dev/null || true

        # Ask about models
        echo ""
        read -rp "  Also remove downloaded models? (y/N): " remove_models
        if [[ "$remove_models" == "y" || "$remove_models" == "Y" ]]; then
            sudo rm -rf /usr/share/ollama 2>/dev/null || true
            rm -rf "$HOME/.ollama" 2>/dev/null || true
            log SUCCESS "Models removed."
        fi

        # Remove user
        sudo userdel ollama 2>/dev/null || true
        sudo groupdel ollama 2>/dev/null || true

        log SUCCESS "Ollama has been uninstalled."
    fi
    echo ""
}

# ============================================================================
#  MAIN PROGRAM LOOP
# ============================================================================

show_banner

running=true
while $running; do
    show_menu
    read -rp "  Select an option (0-9, A/B/C): " choice
    choice=$(echo "$choice" | tr '[:lower:]' '[:upper:]')

    case "$choice" in
        1)
            # Full install: Ollama + Model
            install_ollama
            if check_ollama_installed; then
                start_ollama_server || true
                show_model_menu
                read -rp "  Select a model (0-12): " model_choice
                if [ "$model_choice" != "0" ]; then
                    model_name="$(get_model_name "$model_choice")"
                    if [ -n "$model_name" ]; then
                        pull_model "$model_name"
                        echo ""
                        read -rp "  Start chatting with $model_name now? (Y/n): " start_now
                        if [[ "$start_now" != "n" && "$start_now" != "N" ]]; then
                            start_chat "$model_name"
                        fi
                    fi
                fi
            fi
            ;;
        2)
            install_ollama
            ;;
        3)
            if ! check_ollama_installed; then
                log ERROR "Ollama is not installed. Please install it first (Option 1 or 2)."
            else
                start_ollama_server || true
                show_model_menu
                read -rp "  Select a model (0-12): " model_choice
                if [ "$model_choice" != "0" ]; then
                    model_name="$(get_model_name "$model_choice")"
                    if [ -n "$model_name" ]; then
                        pull_model "$model_name"
                    fi
                fi
            fi
            ;;
        4)
            if ! check_ollama_installed; then
                log ERROR "Ollama is not installed. Please install it first."
            else
                start_chat ""
            fi
            ;;
        5)
            if ! check_ollama_installed; then
                log ERROR "Ollama is not installed. Please install it first."
            else
                start_ollama_server
                echo ""
                echo -e "  ${GREEN}Ollama API is running at: http://localhost:11434${NC}"
                echo -e "  ${GRAY}Press Enter to return to menu...${NC}"
                read -r
            fi
            ;;
        6)
            install_open_webui
            ;;
        7)
            show_system_info
            echo -e "  ${GRAY}Press Enter to return to menu...${NC}"
            read -r
            ;;
        8)
            set_portable_mode
            ;;
        9)
            uninstall_ollama
            ;;
        A)
            log INFO "Starting Claw Agent (terminal)..."
            if ! command -v python3 >/dev/null 2>&1; then
                log ERROR "Python 3 is required for the Claw agent."
            else
                python3 "${USB_DIR}/agent/claw_agent.py" chat || true
            fi
            ;;
        B)
            log INFO "Starting Claw Agent API on http://127.0.0.1:11500 ..."
            if ! command -v python3 >/dev/null 2>&1; then
                log ERROR "Python 3 is required for the Claw agent."
            else
                # Try to open the web UI in the default browser
                ( sleep 1 && (xdg-open "${USB_DIR}/webui/claw.html" 2>/dev/null \
                              || open "${USB_DIR}/webui/claw.html" 2>/dev/null \
                              || true) ) &
                python3 "${USB_DIR}/agent/claw_agent.py" serve --port 11500 || true
            fi
            ;;
        C)
            if ! command -v python3 >/dev/null 2>&1; then
                log ERROR "Python 3 is required for the Claw agent."
            else
                python3 "${USB_DIR}/agent/claw_agent.py" doctor || true
                read -rp "  Press Enter to return to menu..." _
            fi
            ;;
        0)
            echo ""
            echo -e "  ${GREEN}Thank you for using Ollama USB Toolkit!${NC}"
            echo -e "  ${GREEN}Happy chatting with your local LLM!${NC}"
            echo ""
            running=false
            ;;
        *)
            echo -e "  ${RED}Invalid option. Please try again.${NC}"
            ;;
    esac
done
