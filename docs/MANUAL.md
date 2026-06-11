# Ollama USB Toolkit - User Manual

This manual provides detailed instructions on using the Ollama USB Toolkit, from basic setup to advanced configuration. It is designed to help you get the most out of your portable LLM environment.

## Table of Contents

1.  [Introduction](#introduction)
2.  [Getting Started](#getting-started)
    *   [Windows](#windows)
    *   [Linux](#linux)
3.  [The Main Menu](#the-main-menu)
    *   [1. Install Ollama + Download LLM Model](#1-install-ollama--download-llm-model)
    *   [2. Install Ollama Only](#2-install-ollama-only)
    *   [3. Download/Change LLM Model](#3-downloadchange-llm-model)
    *   [4. Start Chat with LLM](#4-start-chat-with-llm)
    *   [5. Start Ollama Server (API mode)](#5-start-ollama-server-api-mode)
    *   [6. Install Open WebUI](#6-install-open-webui)
    *   [7. System Info & GPU Check](#7-system-info--gpu-check)
    *   [8. Store Models on USB (Portable Mode)](#8-store-models-on-usb-portable-mode)
    *   [9. Uninstall Ollama](#9-uninstall-ollama)
4.  [Portable Mode Explained](#portable-mode-explained)
5.  [Offline Installation](#offline-installation)
6.  [Advanced Configuration](#advanced-configuration)
7.  [Troubleshooting](#troubleshooting)

---

## Introduction

The Ollama USB Toolkit is a self-contained environment for running open-source Large Language Models (LLMs) on various computers. It simplifies the process of installing Ollama, managing models, and interacting with them. The core idea is to provide a "plug-and-play" experience for local AI.

## Getting Started

### Windows

1.  **Plug in the USB drive.**
2.  Open the drive in File Explorer.
3.  Double-click the `START-Windows.bat` file.
4.  A terminal window will open, displaying the main menu. If prompted by Windows Defender or other antivirus software, you may need to allow the script to run.

### Linux

1.  **Plug in the USB drive.**
2.  Open a terminal window.
3.  Navigate to the directory where the USB drive is mounted. For example:
    ```bash
    cd /media/your_username/OLLAMA_USB
    ```
4.  Make the script executable (you only need to do this once):
    ```bash
    chmod +x START-Linux.sh
    ```
5.  Run the script:
    ```bash
    ./START-Linux.sh
    ```

## The Main Menu

The main menu provides a set of options to manage your Ollama environment.

### 1. Install Ollama + Download LLM Model

This is the recommended option for first-time users. It performs a full setup:

*   It checks if Ollama is already installed. If not, it runs the official installer.
*   After installation, it presents a menu of popular LLMs to download.
*   Once a model is downloaded, it gives you the option to start chatting immediately.

### 2. Install Ollama Only

This option only installs the Ollama service on the host machine. It does not download any models. Use this if you want to set up the environment but download models later.

### 3. Download/Change LLM Model

Use this option to download new models or switch between models you have already downloaded. It will display the model selection menu.

### 4. Start Chat with LLM

This option initiates a chat session in the terminal. If you have multiple models, it will ask you which one you want to use.

### 5. Start Ollama Server (API mode)

This starts the Ollama server in the background. The server exposes a REST API at `http://localhost:11434`, which can be used by other applications (like Open WebUI) to interact with the LLMs.

### 6. Install Open WebUI

Open WebUI provides a user-friendly, browser-based interface similar to ChatGPT. This option helps you install it. You can choose between a Docker-based installation (recommended if you have Docker) or a Python-based installation.

### 7. System Info & GPU Check

This option displays detailed information about the host system, including:

*   Operating System and architecture.
*   Total and available RAM.
*   CPU information.
*   Detected GPUs (NVIDIA, AMD, Intel) and their VRAM.
*   Available disk space.

It also provides a recommendation for the types of models your system can handle based on the available RAM.

### 8. Store Models on USB (Portable Mode)

This crucial feature allows you to store the large model files on the USB drive itself, rather than on the host computer's internal storage. See the [Portable Mode Explained](#portable-mode-explained) section for more details.

### 9. Uninstall Ollama

This option helps you remove the Ollama service and, optionally, the downloaded models from the host computer.

## Portable Mode Explained

**What it is:** By default, Ollama stores models in the user's home directory on the host computer (e.g., `C:\Users\YourUser\.ollama` on Windows). Portable Mode changes this setting, telling Ollama to use the `models` folder on the USB drive instead.

**Pros:**
*   **True Portability:** Your models travel with you. You can use them on any computer without re-downloading.
*   **Saves Space:** Does not use up space on the host computer's primary drive.

**Cons:**
*   **Performance:** USB drives are slower than internal SSDs. Model loading times and generation speed might be slightly reduced. Using a high-speed USB 3.0 (or faster) drive is highly recommended.

**How to use it:** Select option 8 from the menu. The script will set the `OLLAMA_MODELS` environment variable on the host system to point to the USB's `models` directory.

## Offline Installation

This toolkit can work without an active internet connection if you prepare it beforehand.

1.  **Download the Ollama installer** for your target operating system (Windows or Linux) from the [official Ollama website](https://ollama.com/download).
2.  Place the downloaded installer file inside the `installers` directory on the USB drive.
    *   For Windows: `installers/OllamaSetup.exe`
    *   For Linux: `installers/ollama-linux-amd64.tar.zst` (or `.tgz`)
3.  When you run the launcher script on a machine without internet, it will automatically detect and use the local installer.

**Note:** You will also need to download model files separately for a fully offline experience. You can do this by running `ollama pull <model_name>` on a machine with internet and then copying the model files from the models directory to the USB's `models` directory.

## Advanced Configuration

You can customize some of the toolkit's behavior by editing the `config/settings.json` file:

*   `
`default_model`": The model that the script will suggest for download.
*   `"portable_mode_default"`: Set to `true` to automatically enable portable mode.
*   `"webui_port"`: The port to use for the Open WebUI.

## Troubleshooting

*   **"PowerShell is not available" (Windows):** The toolkit requires PowerShell, which is standard on Windows 10 and 11. If you are on an older system, you may need to install it.
*   **"Permission Denied" (Linux):** Ensure you have made the `START-Linux.sh` script executable by running `chmod +x START-Linux.sh`.
*   **Installation Fails:** If the online installation fails, check your internet connection. For offline installation, ensure the correct installer file is in the `installers` directory.
*   **Model Download Fails:** This is almost always an internet issue or a typo in the model name. Check your connection and the model name.
*   **Slow Performance:** LLMs are resource-intensive. Performance depends on the host computer's CPU, RAM, and GPU. Using a faster USB drive (USB 3.0+) can help in portable mode.
*   **Logs:** The toolkit creates log files in the `logs` directory on the USB drive. These files (`install-*.log`, `ollama-server.log`) contain detailed information that can help diagnose issues.
