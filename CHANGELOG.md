# Changelog

All notable changes to the **Ollama USB Toolkit** are documented here.

Format: `[Version] — Date — Summary`

---

## [1.2.0] — 2026-06-11

### ✨ Added
- **`START-Mac.command`** — Full macOS launcher. Auto-downloads Ollama Darwin binary to the USB on first run. Reads `config/settings.json` for port settings. Opens the built-in Web UI. Supports offline install via `installers/ollama-darwin.zip`.
- **`preflight-check.sh`** — USB drive health check. Verifies write access, free disk space (warns < 4 GB, recommends 16 GB+), and benchmarks read/write speed using `dd`. Detects USB 2.0 vs USB 3.0.
- **`CHANGELOG.md`** — This file. Version history for the project.
- **`VERSION`** — Version number file. Read by scripts to display current version in banners.
- **`CONTRIBUTING.md`** — Contributor guide with setup, code style, and PR instructions.
- macOS section added to **Offline Installation** docs.
- macOS Gatekeeper troubleshooting added to **README.md**.

### 🛠️ Fixed
- **Portable mode `.bashrc` bug** (`START-Linux.sh`) — Previously wrote the absolute USB mount path permanently to `~/.bashrc`. This broke on other PCs where the USB mounts at a different path. Now only exports `OLLAMA_MODELS` for the current session with a clear warning.
- **Windows path portability** (`START-Windows.bat`) — Now uses `%~dp0` for all paths so the USB works on any drive letter. Auto-creates `data/`, `models/`, `logs/` folders. Passes `USB_DIR` to the PS1 installer.
- **Windows cache-wipe fix** (`START-Windows.bat`) — Deletes stale `Cache/`, `Code Cache/`, `GPUCache/`, `config.json` on every launch. Prevents crashes when moving the USB between different Windows PCs.
- **XDG env variables** (`START-Linux.sh`) — Added `XDG_CONFIG_HOME`, `XDG_DATA_HOME`, `XDG_CACHE_HOME` pointing to `data/` on the USB. Prevents apps from writing config to the host PC's `~/.config`.

### 📝 Changed
- **README.md** platform badge updated: Linux | Windows → Linux | Windows | macOS.
- **README.md** Quick Start section now includes macOS instructions.
- **README.md** Roadmap split into ✅ Completed and 🔜 Upcoming sections.
- **`install-ollama.ps1`** now reads `default_model` from `config/settings.json` to pre-select the default model in the menu.
- **`webui/index.html`** now loads API URL from `config/settings.json` on startup, with fallback to `http://localhost:11434`.

---

## [1.1.0] — 2026-06-10

### ✨ Added
- Built-in Web UI (`webui/index.html`) — standalone browser chat with streaming, markdown rendering, model switcher, system prompt, temperature slider, and stop button.
- REST API examples (`api-examples/`) — Python, JavaScript, and curl examples with zero extra dependencies.
- `config/settings.json` — JSON config for Ollama host, port, and default model.
- `docs/MANUAL.md` — Full user manual.
- `installers/` directory — for placing offline Ollama installers.
- `logs/` directory — auto-generated log files with timestamps.
- `.gitignore` — excludes model files, logs, and OS artifacts.

### 🛠️ Fixed
- Linux and Windows scripts now both handle offline installs gracefully.
- Ollama server startup now waits up to 15 seconds with retry logic.

---

## [1.0.0] — 2026-06-09

### 🎉 Initial Release
- `START-Linux.sh` — Full Bash installer and launcher for Linux with interactive TUI menu.
- `START-Windows.bat` + `scripts/install-ollama.ps1` — Windows installer with PowerShell.
- 11 curated models: tinyllama, phi3:mini, gemma2:2b, llama3.2, mistral, gemma2, qwen2.5, llama3.1:70b, deepseek-r1, codellama, starcoder2:3b.
- Portable Mode (store models on USB).
- System info and GPU detection (NVIDIA, AMD, Intel).
- RAM-based model recommendations.
- Open WebUI integration (Docker or pip).
- Uninstall Ollama option.
