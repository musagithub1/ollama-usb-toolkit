# Ollama USB Toolkit (v2.0.0 — Claw Edition) 🦞

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
1. If this is your very first time running it on a new computer, select **Option 1** to quickly bootstrap the Ollama runtime.
2. To start chatting, select **Option B (Agent API + Web UI)**. This will boot the background servers and automatically open the Agent interface in your web browser.

---

## 📚 Further Reading

- [PORTABILITY_GUIDE.md](PORTABILITY_GUIDE.md) - Tips for moving the USB between different OSes safely.
- [ARCHITECTURE.md](ARCHITECTURE.md) - Technical deep-dive into how the Agent Sandbox and Skills work.
- [MIGRATION.md](MIGRATION.md) - Information for users upgrading from v1 to v2.
