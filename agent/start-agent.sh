#!/usr/bin/env bash
# Convenience launcher: start the Claw agent API (Linux/macOS)
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USB_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Keep Ollama models on the USB
export OLLAMA_MODELS="$USB_DIR/models"
export OLLAMA_ORIGINS="*"

PYTHON="python3"
command -v "$PYTHON" >/dev/null 2>&1 || PYTHON="python"

echo "🦞  Starting Claw agent API…"
echo "    USB:  $USB_DIR"
echo "    URL:  http://127.0.0.1:11500"
echo "    UI:   open webui/claw.html in your browser"
echo ""
exec "$PYTHON" "$SCRIPT_DIR/claw_agent.py" serve --port 11500
