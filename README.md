<div align="center">

# 🧠 Ollama USB Toolkit

### Run Local LLMs Anywhere — Plug In, Power Up, Chat.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Linux%20%7C%20Windows%20%7C%20macOS-brightgreen)]()
[![Ollama](https://img.shields.io/badge/Powered%20by-Ollama-orange)](https://ollama.com)
[![Shell](https://img.shields.io/badge/Shell-Bash%20%7C%20PowerShell-blue)]()
[![Stars](https://img.shields.io/github/stars/musagithub1/ollama-usb-toolkit?style=social)](https://github.com/musagithub1/ollama-usb-toolkit)

**A fully portable, cross-platform toolkit to install, manage, and chat with open-source Large Language Models (LLMs) — directly from a USB drive. No cloud. No API keys. 100% private.**

[🚀 Quick Start](#-quick-start) · [✨ Features](#-features) · [📁 Project Structure](#-project-structure) · [🤖 Supported Models](#-supported-models) · [🌐 Web UI](#-built-in-web-ui) · [🔌 API](#-rest-api--developer-mode) · [⚙️ Configuration](#%EF%B8%8F-configuration) · [📖 Docs](docs/MANUAL.md)

</div>

---

## 🎯 What Is This?

The **Ollama USB Toolkit** is a self-contained environment for running open-source LLMs on virtually any Windows or Linux computer — directly from a USB drive. It wraps the powerful [Ollama](https://ollama.com) runtime with an interactive, menu-driven installer and launcher, making local AI accessible to everyone.

Whether you're a developer building AI apps, a researcher running offline experiments, or just someone who wants a private ChatGPT alternative with zero setup friction — this toolkit has you covered.

> **"Plug in your USB → Run the script → Chat with AI"** — it's really that simple.

---

## ✨ Features

| Feature | Description |
|---|---|
| 🖥️ **Cross-Platform** | Works on Windows 10/11, all major Linux distros, and **macOS** |
| 🔍 **Pre-Flight Check** | Validates USB drive health, free space & speed before installing |
| 📦 **Automated Install** | One-command Ollama installation (online or offline) |
| 🎛️ **Menu-Driven UI** | Interactive terminal menu — no commands to memorize |
| 💾 **Portable Mode** | Store LLM models on the USB drive — take them anywhere |
| 🌐 **Built-in Web UI** | Browser-based ChatGPT-like interface (`webui/index.html`) |
| 🔌 **REST API Mode** | Expose Ollama API at `http://localhost:11434` for apps |
| 🔒 **Offline Support** | Pre-place installers on USB for fully air-gapped setups |
| 🤖 **11+ Curated Models** | From tiny 1.1B to powerful 70B parameter models |
| 🖥️ **GPU Detection** | Auto-detects NVIDIA, AMD, and Intel GPUs |
| 💡 **Smart Recommendations** | Suggests best models based on your RAM |
| 📋 **Detailed Logging** | All actions logged to `logs/` for easy debugging |
| ⚙️ **JSON Config** | Customize behavior via `config/settings.json` |
| 🔐 **True Portability** | XDG env vars ensure all data stays on USB, nothing written to host PC |

---

## 🚀 Quick Start

### 🐧 Linux

```bash
# 1. Navigate to the toolkit directory (or USB mount point)
cd /path/to/ollama-usb-toolkit

# 2. Make scripts executable (first time only)
chmod +x START-Linux.sh preflight-check.sh

# 3. (Recommended) Run the pre-flight check first
./preflight-check.sh

# 4. Launch the toolkit
./START-Linux.sh
```

### 🪟 Windows

```
1. Open the toolkit folder in File Explorer
2. Double-click START-Windows.bat
3. Allow PowerShell execution if prompted
```

> 💡 The Windows launcher automatically clears stale path caches — so the USB works correctly even when moved between different PCs.

### 🍎 macOS

```
1. Open the toolkit folder in Finder
2. Double-click START-Mac.command
3. If blocked by Gatekeeper: right-click → Open → Open
```

> 💡 **First time on Mac:** The launcher auto-downloads the Ollama binary (~60 MB) directly to the USB. Nothing is installed on your Mac.

> **First time on any platform?** Choose **Option 1** from the menu: it installs Ollama, lets you pick a model, and starts a chat — all in one go.

---

## 🎛️ Main Menu Options

```
  ┌──────────────────────────────────────────────┐
  │           MAIN MENU - Choose Action          │
  ├──────────────────────────────────────────────┤
  │  1. Install Ollama + Download LLM Model      │
  │  2. Install Ollama Only                      │
  │  3. Download/Change LLM Model                │
  │  4. Start Chat with LLM                      │
  │  5. Start Ollama Server (API mode)           │
  │  6. Install Open WebUI (Browser Chat)        │
  │  7. System Info & GPU Check                  │
  │  8. Store Models on USB (Portable Mode)      │
  │  9. Uninstall Ollama                         │
  │  0. Exit                                     │
  └──────────────────────────────────────────────┘
```

### Option Details

| # | Option | What It Does |
|---|--------|-------------|
| **1** | Install Ollama + Model | **Recommended for beginners.** Full setup: installs Ollama, lets you pick a model, and starts chatting immediately. |
| **2** | Install Ollama Only | Installs the Ollama service without downloading any models. |
| **3** | Download/Change Model | Download a new model or switch between installed models. |
| **4** | Start Chat | Launch an interactive terminal chat with any installed model. |
| **5** | Start API Server | Starts Ollama in server mode at `http://localhost:11434` for use with apps and scripts. |
| **6** | Install Open WebUI | Sets up a browser-based ChatGPT-like interface via Docker or pip. |
| **7** | System Info & GPU | Full hardware report: OS, RAM, CPU, GPU (NVIDIA/AMD/Intel), disk, and model recommendations. |
| **8** | Portable Mode | Redirects model storage to the USB drive so models travel with you. |
| **9** | Uninstall Ollama | Cleanly removes Ollama and optionally deletes downloaded models. |

---

## 🤖 Supported Models

The toolkit includes a curated selection of the best open-source models:

### 🪶 Lightweight (2–4 GB RAM)
| Model | Size | Best For |
|-------|------|----------|
| `tinyllama` | 1.1B | Fast replies, low-end hardware |
| `phi3:mini` | 3.8B | Microsoft model — great quality for its size |
| `gemma2:2b` | 2.6B | Google — compact and capable |

### ⚖️ Medium (8 GB RAM)
| Model | Size | Best For |
|-------|------|----------|
| `llama3.2` | 3B | Meta's latest Llama — versatile |
| `mistral` | 7B | Mistral AI — excellent general purpose |
| `gemma2` | 9B | Google — powerful and balanced |
| `qwen2.5` | 7B | Alibaba — strong multilingual support |

### 🏋️ Large (16+ GB RAM)
| Model | Size | Best For |
|-------|------|----------|
| `llama3.1:70b` | 70B | Meta's flagship — near GPT-4 quality |
| `deepseek-r1` | 7B | DeepSeek — exceptional reasoning tasks |

### 💻 Code Models
| Model | Size | Best For |
|-------|------|----------|
| `codellama` | 7B | Meta — general code generation |
| `starcoder2:3b` | 3B | BigCode — lightweight coding assistant |

> **Not listed?** Use **Option 12 (Custom model)** to pull any model from the [Ollama library](https://ollama.com/library).

---

## 📁 Project Structure

```
ollama-usb-toolkit/
│
├── 📜 START-Linux.sh              # Main launcher for Linux (Bash)
├── 📜 START-Windows.bat           # Main launcher for Windows (calls PowerShell)
├── 📜 START-Mac.command           # Main launcher for macOS (double-click to run)
├── 📜 preflight-check.sh          # USB health check — run before installing
│
├── 📂 scripts/
│   └── install-ollama.ps1         # Full Windows installer script (PowerShell)
│
├── 📂 webui/
│   └── index.html                 # Standalone browser chat UI (no server needed)
│
├── 📂 api-examples/
│   ├── curl_examples.sh           # Ollama REST API examples using curl (Bash)
│   ├── python_example.py          # API examples using Python (no extra libs)
│   └── javascript_example.js      # API examples using Node.js / browser fetch
│
├── 📂 config/
│   └── settings.json              # Toolkit configuration (model, ports, mode)
│
├── 📂 installers/                 # Place offline Ollama installers here
│   └── README.txt                 # Instructions for offline / air-gapped setup
│
├── 📂 models/                     # LLM model storage (used in Portable Mode)
│
├── 📂 data/                       # App data kept on USB (XDG override target)
│
├── 📂 ollama_mac/                 # macOS Ollama binary (auto-created on first Mac run)
│
├── 📂 logs/                       # Auto-generated log files
│   ├── install-YYYYMMDD-HHMMSS.log
│   └── ollama-mac.log             # macOS server output
│
└── 📂 docs/
    └── MANUAL.md                  # Full user manual
```

---

## 🌐 Built-in Web UI

The toolkit includes a **zero-dependency, browser-based chat interface** at `webui/index.html`. Open it directly in any browser — no server needed.

### Features
- 🔗 Connects to local Ollama API (`http://localhost:11434`)
- 🔄 Auto-detects and lists all installed models
- 📡 Real-time streaming responses (token by token)
- 🛑 Stop generation at any time
- 🎨 Markdown rendering — bold, italic, code blocks, lists
- 📋 One-click code copy button
- 🌡️ Temperature slider for creativity control
- 💬 System prompt customization
- 🗑️ Clear chat / new conversation
- 📱 Fully responsive (mobile-friendly)

### How to Use

1. Start the Ollama server (Menu Option 5)
2. Open `webui/index.html` in your browser
3. Select a model from the dropdown
4. Start chatting!

---

## 🔌 REST API & Developer Mode

Start the Ollama server (Menu Option 5) to expose a REST API at `http://localhost:11434`. Use it to integrate LLMs into your own applications.

### Quick API Reference

**Health Check**
```bash
curl http://localhost:11434
```

**List Models**
```bash
curl http://localhost:11434/api/tags
```

**Generate Text**
```bash
curl http://localhost:11434/api/generate \
  -H "Content-Type: application/json" \
  -d '{
    "model": "phi3:mini",
    "prompt": "Explain quantum computing in one sentence.",
    "stream": false
  }'
```

**Chat (with history)**
```bash
curl http://localhost:11434/api/chat \
  -H "Content-Type: application/json" \
  -d '{
    "model": "phi3:mini",
    "messages": [
      {"role": "system", "content": "You are a helpful assistant."},
      {"role": "user", "content": "What is Docker?"}
    ],
    "stream": false
  }'
```

**Streaming Response**
```bash
curl http://localhost:11434/api/generate \
  -H "Content-Type: application/json" \
  -d '{"model": "phi3:mini", "prompt": "Write a haiku.", "stream": true}'
```

### Code Examples

Full working examples are in the `api-examples/` directory:

```bash
# Run curl examples
bash api-examples/curl_examples.sh

# Run Python examples (no extra packages needed!)
python3 api-examples/python_example.py

# Run JavaScript examples (Node.js 18+)
node api-examples/javascript_example.js
```

### Python (Built-in `urllib`, no pip required)

```python
import json, urllib.request

def chat(model, prompt):
    payload = json.dumps({"model": model, "prompt": prompt, "stream": False}).encode()
    req = urllib.request.Request(
        "http://localhost:11434/api/generate",
        data=payload,
        headers={"Content-Type": "application/json"}
    )
    res = urllib.request.urlopen(req)
    return json.loads(res.read())["response"]

print(chat("phi3:mini", "What is Python?"))
```

### JavaScript (Node.js 18+ / Browser)

```javascript
const response = await fetch("http://localhost:11434/api/generate", {
  method: "POST",
  headers: { "Content-Type": "application/json" },
  body: JSON.stringify({ model: "phi3:mini", prompt: "What is AI?", stream: false })
});
const data = await response.json();
console.log(data.response);
```

---

## 💾 Portable Mode (Store Models on USB)

By default, Ollama stores models on the host computer's internal drive. **Portable Mode** changes this so your models live on the USB drive — carry them everywhere.

**Enable via the menu (Option 8) or manually:**

```bash
# Linux / macOS
export OLLAMA_MODELS="/path/to/usb/models"

# Windows (PowerShell)
$env:OLLAMA_MODELS = "D:\models"
```

| Aspect | Detail |
|--------|--------|
| ✅ **Benefit** | Models travel with you on the USB — no re-downloading |
| ✅ **Benefit** | Saves space on the host computer |
| ✅ **Benefit** | XDG env vars ensure app config also stays on USB (Linux) |
| ⚠️ **Trade-off** | USB drives are slower than SSDs — use USB 3.0+ |
| 📁 **Storage Path** | `models/` folder on the USB |

> **Note:** Portable mode is set for the **current session only**. USB mount paths differ between computers (e.g. `/media/userA/USB` vs `/media/userB/USB`), so saving the path permanently would break on other machines. Re-enable it via Option 8 each time.

---

## 📴 Offline / Air-Gapped Installation

Run the toolkit with **zero internet connection** by pre-loading the installer:

### 🐧 Linux
1. Download `ollama-linux-amd64.tar.zst` from [ollama.com/download](https://ollama.com/download)
2. Place it in the `installers/` directory
3. Run `./START-Linux.sh` — it will auto-detect the local installer

### 🪟 Windows
1. Download `OllamaSetup.exe` from [ollama.com/download](https://ollama.com/download)
2. Place it in the `installers/` directory
3. Run `START-Windows.bat` — it will auto-detect and run it

### 🍎 macOS
1. Download `ollama-darwin.zip` from the [Ollama GitHub releases](https://github.com/ollama/ollama/releases)
2. Place it in the `installers/` directory
3. Run `START-Mac.command` — it will detect the local file and skip the download

> **Full offline mode:** Pre-download models too by running `ollama pull <model>` on an internet-connected machine, then copying the model files to the USB's `models/` directory.

---

## ⚙️ Configuration

Edit `config/settings.json` to customize toolkit behavior:

```json
{
  "default_model": "phi3:mini",
  "portable_mode_default": false,
  "webui_port": 8080,
  "ollama_host": "127.0.0.1",
  "ollama_port": 11434
}
```

| Key | Default | Description |
|-----|---------|-------------|
| `default_model` | `phi3:mini` | Model suggested during first-time setup |
| `portable_mode_default` | `false` | Set `true` to auto-enable Portable Mode |
| `webui_port` | `8080` | Port for Open WebUI |
| `ollama_host` | `127.0.0.1` | Ollama API host address |
| `ollama_port` | `11434` | Ollama API port |

---

## 🖥️ System Requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| **OS** | Windows 10 (22H2) / Modern Linux / macOS 12+ | Windows 11 / Ubuntu 22.04+ / macOS 13+ |
| **RAM** | 4 GB | 16 GB+ |
| **Disk** | 4 GB (for small models) | 50 GB+ on USB |
| **USB** | USB 2.0 | USB 3.0 or faster |
| **GPU** | Not required (CPU mode) | NVIDIA / AMD GPU (highly recommended) |
| **Internet** | Required for online install | Not needed if offline installer is placed |

### RAM → Model Size Guide

| Your RAM | Recommended Models |
|----------|-------------------|
| 4 GB | `tinyllama` |
| 8 GB | `phi3:mini`, `gemma2:2b`, `llama3.2` |
| 16 GB | `mistral`, `gemma2`, `qwen2.5`, `codellama` |
| 32 GB+ | `llama3.1:70b`, `deepseek-r1` |

---

## 🔧 Troubleshooting

<details>
<summary><b>❌ "Permission Denied" on Linux</b></summary>

```bash
chmod +x START-Linux.sh preflight-check.sh
./preflight-check.sh   # optional health check
./START-Linux.sh
```
</details>

<details>
<summary><b>❌ "PowerShell is not available" on Windows</b></summary>

PowerShell is standard on Windows 10/11. If missing, install it from the [Microsoft Store](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows).
</details>

<details>
<summary><b>❌ macOS blocks START-Mac.command ("unidentified developer")</b></summary>

Right-click `START-Mac.command` → **Open** → click **Open** in the dialog. This is a one-time step required by macOS Gatekeeper for scripts from the internet.

Alternatively, run in Terminal:
```bash
chmod +x START-Mac.command
./START-Mac.command
```
</details>

<details>
<summary><b>❌ Crashes / "wrong path" errors when moving USB between PCs (Windows)</b></summary>

This is automatically fixed — `START-Windows.bat` wipes stale path caches on every launch. If you still see errors, delete the `data/` folder on the USB and relaunch.
</details>

<details>
<summary><b>❌ Installation fails / No internet</b></summary>

Use the offline mode: Download the Ollama installer manually and place it in the `installers/` directory. The script auto-detects it. See [Offline Installation](#-offline--air-gapped-installation) for per-platform instructions.
</details>

<details>
<summary><b>❌ Model download fails</b></summary>

1. Check your internet connection
2. Verify the model name at [ollama.com/library](https://ollama.com/library)
3. Check `logs/install-*.log` for detailed error output
</details>

<details>
<summary><b>❌ Slow performance in Portable Mode</b></summary>

USB 2.0 drives are slow for large model files. Use a **USB 3.0** (or faster) flash drive. Run `./preflight-check.sh` to benchmark your drive speed before installing.
</details>

<details>
<summary><b>❌ Web UI can't connect to Ollama</b></summary>

1. Ensure the Ollama server is running (Menu Option 5)
2. Verify Ollama is at `http://localhost:11434` by visiting it in a browser
3. Check the API URL in the Web UI settings panel
</details>

<details>
<summary><b>📋 Viewing Logs</b></summary>

All logs are saved in the `logs/` directory:
- `install-YYYYMMDD-HHMMSS.log` — Installation and session logs
- `ollama-server.log` — Ollama server output (Linux)
- `ollama-mac.log` — macOS server output

```bash
# View the latest log
ls -t logs/ | head -1 | xargs -I{} cat logs/{}
```
</details>

---

## 🗺️ Roadmap

### ✅ Completed
- [x] macOS support (`START-Mac.command`)
- [x] USB pre-flight health check (`preflight-check.sh`)
- [x] XDG env vars — all app data stays on USB (Linux)
- [x] Windows portability cache-wipe fix
- [x] Portable mode `.bashrc` bug fix

### 🔜 Upcoming
- [ ] Auto-update checker for Ollama
- [ ] Model size estimator before download
- [ ] GPU offloading configuration wizard
- [ ] Multi-model comparison mode
- [ ] Batch conversation export (JSON/Markdown)
- [ ] One-command Docker Compose setup
- [ ] Web UI reads `config/settings.json` for dynamic port config

---

## 🤝 Contributing

Contributions are welcome! To contribute:

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature`
3. Commit your changes: `git commit -m "feat: add your feature"`
4. Push to GitHub: `git push origin feature/your-feature`
5. Open a Pull Request

Please follow the existing code style and test on both Linux and Windows if possible.

---

## 📄 License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.

You are free to use, modify, and distribute this toolkit for personal or commercial purposes.

---

## 🙏 Acknowledgments

- [**Ollama**](https://ollama.com) — The incredible runtime that powers this entire toolkit
- [**Meta AI**](https://ai.meta.com) — Llama model series
- [**Mistral AI**](https://mistral.ai) — Mistral model series
- [**Google DeepMind**](https://deepmind.google) — Gemma model series
- [**Open WebUI**](https://github.com/open-webui/open-webui) — Inspiration for the browser interface

---

<div align="center">

**Made with ❤️ for the open-source AI community**

*Run AI locally. Own your data. Share knowledge.*

⭐ **Star this repo** if it helped you run your first local LLM!

[🐛 Report Bug](https://github.com/musagithub1/ollama-usb-toolkit/issues) · [💡 Request Feature](https://github.com/musagithub1/ollama-usb-toolkit/issues) · [📖 Full Manual](docs/MANUAL.md)

</div>
