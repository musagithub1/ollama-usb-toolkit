#!/bin/bash
# ============================================================================
#  OLLAMA USB TOOLKIT - Mac Launcher
#  Double-click this file on any Mac to start Ollama from the USB.
#  First run: auto-downloads Ollama for macOS to the USB (~60 MB).
#  Nothing is installed on the host Mac — everything stays on the USB.
# ============================================================================

# Move to the directory where this script lives (the USB root)
cd "$(dirname "$0")" || exit 1
SCRIPT_DIR="$(pwd)"

MAC_OLLAMA_DIR="${SCRIPT_DIR}/ollama_mac"
MODELS_DIR="${SCRIPT_DIR}/models"
LOG_DIR="${SCRIPT_DIR}/logs"
CONFIG_FILE="${SCRIPT_DIR}/config/settings.json"
WEBUI="${SCRIPT_DIR}/webui/index.html"

mkdir -p "${MAC_OLLAMA_DIR}" "${MODELS_DIR}" "${LOG_DIR}"

# --- Colors (macOS terminal supports ANSI) ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
GRAY='\033[0;37m'
NC='\033[0m'

echo ""
echo -e "${CYAN}==================================================="
echo -e "     OLLAMA USB TOOLKIT - Mac Launcher"
echo -e "===================================================${NC}"
echo ""

# ============================================================================
# STEP 1: Read config/settings.json for port settings
# ============================================================================
OLLAMA_PORT=11434
OLLAMA_HOST="127.0.0.1"

if [ -f "$CONFIG_FILE" ] && command -v python3 &>/dev/null; then
    OLLAMA_PORT=$(python3 -c "
import json, sys
try:
    d = json.load(open('${CONFIG_FILE}'))
    print(d.get('ollama_port', 11434))
except:
    print(11434)
" 2>/dev/null || echo 11434)
    OLLAMA_HOST=$(python3 -c "
import json, sys
try:
    d = json.load(open('${CONFIG_FILE}'))
    print(d.get('ollama_host', '127.0.0.1'))
except:
    print('127.0.0.1')
" 2>/dev/null || echo "127.0.0.1")
fi

OLLAMA_URL="http://${OLLAMA_HOST}:${OLLAMA_PORT}"

# ============================================================================
# STEP 2: Download Ollama for macOS to USB (first time only)
# ============================================================================
OLLAMA_BIN="${MAC_OLLAMA_DIR}/ollama"

if [ ! -f "$OLLAMA_BIN" ]; then
    echo -e "${YELLOW}  First time on Mac — downloading Ollama to USB...${NC}"
    echo -e "  ${GRAY}Nothing will be installed on this Mac.${NC}"
    echo ""

    # Check for offline installer first
    OFFLINE_PKG="${SCRIPT_DIR}/installers/ollama-darwin.zip"
    if [ -f "$OFFLINE_PKG" ]; then
        echo -e "  ${GREEN}Found offline installer. Using local copy...${NC}"
        cp "$OFFLINE_PKG" "${MAC_OLLAMA_DIR}/ollama-darwin.zip"
    else
        if ! curl -s --connect-timeout 5 https://ollama.com > /dev/null 2>&1; then
            echo -e "${RED}  ✘ No internet connection and no offline installer found.${NC}"
            echo -e "  ${GRAY}Download ollama-darwin.zip from https://github.com/ollama/ollama/releases${NC}"
            echo -e "  ${GRAY}and place it in the 'installers/' folder on the USB.${NC}"
            echo ""
            read -rp "  Press Enter to exit..."
            exit 1
        fi

        echo -e "  Downloading Ollama for macOS..."
        curl -L --progress-bar \
            "https://github.com/ollama/ollama/releases/latest/download/ollama-darwin.zip" \
            -o "${MAC_OLLAMA_DIR}/ollama-darwin.zip"
    fi

    echo -e "  Extracting..."
    unzip -o -q "${MAC_OLLAMA_DIR}/ollama-darwin.zip" -d "${MAC_OLLAMA_DIR}/"
    rm -f "${MAC_OLLAMA_DIR}/ollama-darwin.zip"

    # The zip may contain an .app bundle — extract the binary from it
    if [ -f "${MAC_OLLAMA_DIR}/Ollama.app/Contents/MacOS/ollama" ]; then
        cp "${MAC_OLLAMA_DIR}/Ollama.app/Contents/MacOS/ollama" "$OLLAMA_BIN"
    elif [ -f "${MAC_OLLAMA_DIR}/Ollama.app/Contents/Resources/ollama" ]; then
        cp "${MAC_OLLAMA_DIR}/Ollama.app/Contents/Resources/ollama" "$OLLAMA_BIN"
    fi

    if [ ! -f "$OLLAMA_BIN" ]; then
        # Try finding the binary anywhere inside the extracted folder
        FOUND=$(find "${MAC_OLLAMA_DIR}" -type f -name "ollama" | head -1)
        if [ -n "$FOUND" ]; then
            cp "$FOUND" "$OLLAMA_BIN"
        fi
    fi

    if [ ! -f "$OLLAMA_BIN" ]; then
        echo -e "${RED}  ✘ Could not find Ollama binary after extraction.${NC}"
        echo -e "  ${GRAY}Please report this at: https://github.com/musagithub1/ollama-usb-toolkit/issues${NC}"
        read -rp "  Press Enter to exit..."
        exit 1
    fi

    chmod +x "$OLLAMA_BIN"
    # Remove macOS quarantine so it runs from USB without Gatekeeper blocking
    xattr -rc "$OLLAMA_BIN" 2>/dev/null || true

    echo -e "  ${GREEN}✔ Ollama for Mac is ready on the USB!${NC}"
    echo ""
fi

# ============================================================================
# STEP 3: Set OLLAMA_MODELS to USB drive (portable mode)
# ============================================================================
export OLLAMA_MODELS="${MODELS_DIR}"
export OLLAMA_HOST="${OLLAMA_HOST}:${OLLAMA_PORT}"

echo -e "  ${GRAY}Models path : ${MODELS_DIR}${NC}"
echo -e "  ${GRAY}Ollama API  : ${OLLAMA_URL}${NC}"
echo ""

# ============================================================================
# STEP 4: Start Ollama server in background
# ============================================================================
echo -e "  Starting Ollama server..."

# Kill any existing Ollama process first (stale from previous run)
pkill -f "${MAC_OLLAMA_DIR}/ollama" 2>/dev/null || true
sleep 1

"${OLLAMA_BIN}" serve > "${LOG_DIR}/ollama-mac.log" 2>&1 &
OLLAMA_PID=$!

# Wait for server to be ready (up to 20 seconds)
echo -n "  Waiting for server"
for i in $(seq 1 20); do
    if curl -s "${OLLAMA_URL}" > /dev/null 2>&1; then
        echo ""
        echo -e "  ${GREEN}✔ Ollama server is running at ${OLLAMA_URL}${NC}"
        break
    fi
    echo -n "."
    sleep 1
    if [ "$i" -eq 20 ]; then
        echo ""
        echo -e "  ${YELLOW}⚠ Server may still be starting. Check logs if the UI doesn't connect.${NC}"
    fi
done

# ============================================================================
# STEP 5: Open the Web UI in the default browser
# ============================================================================
echo ""
if [ -f "$WEBUI" ]; then
    echo -e "  Opening Web UI in browser..."
    open "$WEBUI"
else
    echo -e "  ${YELLOW}⚠ Web UI not found at: ${WEBUI}${NC}"
    echo -e "  ${GRAY}You can still use the API at: ${OLLAMA_URL}${NC}"
fi

echo ""
echo -e "${CYAN}==================================================="
echo -e "  ✔  SYSTEM ONLINE — AI is running from USB!"
echo -e "===================================================${NC}"
echo ""
echo -e "  ${GRAY}API endpoint : ${OLLAMA_URL}${NC}"
echo -e "  ${GRAY}Model logs   : ${LOG_DIR}/ollama-mac.log${NC}"
echo ""
echo -e "  ${YELLOW}Keep this window open while using the AI.${NC}"
echo -e "  Press ${RED}[ENTER]${NC} to shut down Ollama safely."
echo ""

# ============================================================================
# STEP 6: Wait for user, then clean shutdown
# ============================================================================
read -r

echo ""
echo -e "  Shutting down Ollama..."
kill "$OLLAMA_PID" 2>/dev/null || true
pkill -f "${MAC_OLLAMA_DIR}/ollama" 2>/dev/null || true

echo -e "  ${GREEN}✔ Ollama stopped. You may safely eject the USB.${NC}"
echo ""
