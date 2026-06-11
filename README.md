# Ollama USB Toolkit (v2.0.0 — Claw Edition) 🦞

[![GitHub stars](https://img.shields.io/github/stars/musagithub1/ollama-usb-toolkit.svg?style=social&label=Star)](https://github.com/musagithub1/ollama-usb-toolkit)
[![GitHub forks](https://img.shields.io/github/forks/musagithub1/ollama-usb-toolkit.svg?style=social&label=Fork)](https://github.com/musagithub1/ollama-usb-toolkit)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Version](https://img.shields.io/badge/version-2.0.0-blue.svg)]()
Welcome to the **Ollama USB Toolkit (Claw Edition)**. 

This toolkit is an ultra-lightweight, single-agent runtime specifically built to fit on a USB drive. It only runs one local agent (named Claw by default). Unlike massive, multi-agent cloud frameworks, this is designed for ultimate portability, privacy, and simplicity. All data, models, and memories are stored locally in this folder, ensuring your agent travels with you wherever you plug in your drive.

---

## 🔌 1. The USB Plug-and-Play Experience

The most important feature of this toolkit is its complete portability. 

**How to use it on ANY system:**
1. **Copy** this entire `ollama-usb-toolkit` folder to the root of your USB flash drive or external hard drive.
2. **Plug the USB** into any Windows, macOS, or Linux computer.
3. Open the USB folder on the new computer and double-click the appropriate `START-*` script for that operating system (e.g., `START-Windows.bat`).
4. **That's it!** The toolkit will automatically detect the local operating system, bootstrap the required dependencies temporarily, and launch your agent using the models and memory *already saved on the USB*. 

Nothing is permanently installed on the host computer. When you unplug the USB, you leave zero trace behind, and your agent's memory comes with you.

---

## 🎯 2. Who is this tool for?

This toolkit is specifically designed for:

- **Privacy-Conscious Individuals:** Those who want a powerful AI assistant but refuse to send their personal data, code, or private thoughts to cloud APIs like OpenAI or Google.
- **Offline Developers & Researchers:** People working in air-gapped environments, on airplanes, or in remote locations without reliable internet access.
- **Students & Nomads:** Users who jump between computer labs, library PCs, or friend's laptops and want to carry their personal, highly customized AI assistant in their pocket.
- **Tinkerers:** Anyone who wants a simple, single-agent local environment to experiment with "Agentic" capabilities (function calling, local file reading/writing, shell execution) without complex Docker setups.

---

## ⚙️ 3. How it Works

The magic of the Claw Edition relies on three core pillars communicating with each other entirely offline:

1. **The Engine (Ollama):** Runs silently in the background (`localhost:11434`). It does the heavy mathematical lifting of text generation using local models (like `qwen2.5:0.5b` or `llama3`).
2. **The Brain (Claw Agent API):** A lightweight Python HTTP server (`localhost:11500`). It acts as the middleman. It bundles your messages with a massive "System Prompt" containing the agent's identity, memory, and installed skills. If Ollama asks to use a tool (like `read_file` or `system_info`), the Agent API executes the local Python code, grabs the result, and feeds it back to the AI.
3. **The Frontend (Web UI):** A beautiful, static HTML/JS dashboard (`localhost:8888`) that serves as your chat interface.

For a deep dive into the code and agentic loop, please read [ARCHITECTURE.md](ARCHITECTURE.md).

---

## 🚀 4. How to Run It on Your System

Running the toolkit is incredibly simple. Choose the script that matches your operating system:

### Linux
Open your terminal, navigate to the USB folder, and run:
```bash
chmod +x START-Linux.sh
./START-Linux.sh
```

### Windows
Simply navigate to the USB folder in File Explorer and double-click:
```text
START-Windows.bat
```

### macOS
Navigate to the USB folder in Finder and double-click:
```text
START-Mac.command
```

### The Startup Menu
Once you run the script, you will be greeted by a menu. 

- **Option 1 (Install Ollama + Download Model):** If this is your very first time running the toolkit on a new computer, select this. It will safely install the tiny Ollama background engine on the host machine without overwriting your USB data.
- **Option 2 (Start Classic Chat):** Starts the traditional, raw text-generation interface without agentic tools.
- **Option A (Start Agent API):** Boots only the background Python server on port `11500`. Useful for developers testing custom frontends.
- **Option B (Agent API + Web UI):** The primary option! This boots the background servers and automatically opens the beautiful Agent interface in your web browser.
- **Option C (Run Doctor):** Runs a sanity check on your environment to make sure Python, Node, and Ollama are working correctly.

**Accessing the UI:**
If your browser doesn't open automatically after selecting Option B, simply go to `http://localhost:8888/webui/claw.html` in any web browser.

**Shutting Down:**
To safely stop the agent and flush any writing to the USB, simply press `Ctrl+C` in the terminal where the script is running. Wait for the servers to exit before ejecting your USB drive!

---

## 📴 5. Offline / Air-Gapped Installation

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

## ⚙️ 6. Configuration

You can customize the toolkit behavior by editing the JSON configuration files in the `config/` folder.

### Web Server Settings (`config/settings.json`)
```json
{
  "default_model": "qwen2.5:0.5b",
  "portable_mode_default": false,
  "webui_port": 8080,
  "ollama_host": "127.0.0.1",
  "ollama_port": 11434
}
```

### Agent Sandbox Settings (`config/agent.json`)
```json
{
  "default_model": "qwen2.5:0.5b",
  "agent_mode": true,
  "enable_tools": true,
  "enable_skills": true,
  "shell_sandbox": true,
  "shell_allow_list": [
    "ls", "dir", "pwd", "echo", "cat", "python", "python3"
  ]
}
```

---

## 🖥️ 7. System Requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| **OS** | Windows 10 (22H2) / Modern Linux / macOS 12+ | Windows 11 / Ubuntu 22.04+ / macOS 13+ |
| **RAM** | 4 GB | 16 GB+ |
| **Disk** | 4 GB (for small models) | 50 GB+ on USB |
| **USB** | USB 2.0 | USB 3.0 or faster |
| **GPU** | Not required (CPU mode) | NVIDIA / AMD GPU (highly recommended) |

### RAM → Model Size Guide

| Your RAM | Recommended Models |
|----------|-------------------|
| 4 GB | `qwen2.5:0.5b`, `tinyllama` |
| 8 GB | `phi3:mini`, `gemma2:2b`, `llama3.2` |
| 16 GB | `mistral`, `gemma2`, `qwen2.5:7b`, `codellama` |
| 32 GB+ | `llama3.1:70b`, `deepseek-r1` |

---

## 🔧 8. Troubleshooting

<details>
<summary><b>❌ "Permission Denied" on Linux</b></summary>

```bash
chmod +x START-Linux.sh preflight-check.sh
./preflight-check.sh   # optional health check
./START-Linux.sh
```
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

Use the offline mode: Download the Ollama installer manually and place it in the `installers/` directory. The script auto-detects it.
</details>

<details>
<summary><b>📋 Viewing Logs</b></summary>

All logs are saved in the `logs/` directory:
- `install-YYYYMMDD-HHMMSS.log` — Installation and session logs
- `ollama-server.log` — Ollama server output (Linux)
- `ollama-mac.log` — macOS server output
</details>

---

## 📚 9. Further Reading

- [PORTABILITY_GUIDE.md](PORTABILITY_GUIDE.md) - Tips for moving the USB between different OSes safely.
- [ARCHITECTURE.md](ARCHITECTURE.md) - Technical deep-dive into how the Agent Sandbox and Skills work.
- [MIGRATION.md](MIGRATION.md) - Information for users upgrading from v1 to v2.

---

## 🗺️ Roadmap

### ✅ Completed
- [x] macOS support (`START-Mac.command`)
- [x] USB pre-flight health check (`preflight-check.sh`)
- [x] XDG env vars — all app data stays on USB (Linux)
- [x] Agentic workflow integration (Claw Edition)
- [x] Local Python Sandbox and Skill execution

### 🔜 Upcoming
- [ ] Auto-update checker for Ollama
- [ ] Model size estimator before download
- [ ] Web UI reads `config/settings.json` for dynamic port config

---

## 🤝 Contributing

Contributions are welcome! To contribute:

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature`
3. Commit your changes: `git commit -m "feat: add your feature"`
4. Push to GitHub: `git push origin feature/your-feature`
5. Open a Pull Request

---

## 📄 License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.

You are free to use, modify, and distribute this toolkit for personal or commercial purposes.

---

## 🙏 Acknowledgments

- [**Ollama**](https://ollama.com) — The incredible runtime that powers this entire toolkit
- [**Open WebUI**](https://github.com/open-webui/open-webui) — Inspiration for the browser interface

---

<div align="center">

**Made with ❤️ for the open-source AI community**

*Run AI locally. Own your data. Share knowledge.*

⭐ **Star this repo** if it helped you run your first local agent!

[🐛 Report Bug](https://github.com/musagithub1/ollama-usb-toolkit/issues) · [💡 Request Feature](https://github.com/musagithub1/ollama-usb-toolkit/issues)

</div>
