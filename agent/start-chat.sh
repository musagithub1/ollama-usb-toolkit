#!/usr/bin/env bash
# Convenience launcher: terminal chat with the Claw agent
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USB_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
export OLLAMA_MODELS="$USB_DIR/models"
PYTHON="python3"
command -v "$PYTHON" >/dev/null 2>&1 || PYTHON="python"
exec "$PYTHON" "$SCRIPT_DIR/claw_agent.py" chat "$@"
