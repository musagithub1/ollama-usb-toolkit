# Ollama USB Toolkit - Run LLMs Anywhere

Welcome to the Ollama USB Toolkit! This portable solution allows you to install and run powerful, open-source Large Language Models (LLMs) on almost any Windows or Linux computer directly from this USB drive.

Whether you want to experiment with AI, run a local chatbot, or develop applications, this toolkit makes it simple to get started without a complex setup process.

## Quick Start

1.  **Plug in the USB drive** to your computer.
2.  Open the drive in your file explorer.
3.  **Run the appropriate launcher for your system:**
    *   **For Windows:** Double-click `START-Windows.bat`
    *   **For Linux:** Open a terminal, navigate to the USB drive, and run `./START-Linux.sh`

An interactive menu will guide you through the rest of the process, including installation, model downloads, and chatting with your LLM.

## Features

*   **Cross-Platform:** Works on both Windows (10/11) and most modern Linux distributions.
*   **Automated Installation:** The scripts handle the detection of your OS and automate the installation of Ollama.
*   **Menu-Driven Interface:** An easy-to-use menu for installing, managing models, and starting chats.
*   **Portable Mode:** Choose to store your downloaded LLM models directly on the USB drive, allowing you to take your models with you anywhere.
*   **Model Selection:** A curated list of popular models is available for easy download, from lightweight models that run on laptops to powerful models for high-end workstations.
*   **Offline Installation:** Place the Ollama installer in the `installers` directory for a fully offline setup.
*   **Optional Web UI:** Includes an option to install Open WebUI for a browser-based, ChatGPT-like experience.

## How It Works

The launcher script (`.bat` for Windows, `.sh` for Linux) is the entry point. It performs the following steps:

1.  **Detects the Operating System** and runs the appropriate installer logic.
2.  **Checks for Dependencies** like PowerShell on Windows.
3.  **Presents a Main Menu** with options to install Ollama, download models, chat, and more.
4.  **Installs Ollama:** If not already installed, it downloads and runs the official Ollama installer.
5.  **Downloads a Model:** Guides you to select and download an LLM from the official Ollama library.
6.  **Launches the Chat:** Starts an interactive chat session in your terminal with the selected model.

## System Requirements

*   **OS:** Windows 10 (22H2) or newer / A modern Linux distribution.
*   **RAM:** 8 GB is recommended for smaller models (like `phi3:mini`), while 16-32 GB is needed for larger, more powerful models.
*   **Disk Space:** The host system needs minimal space. The models can be stored on the USB drive if it has sufficient capacity (models range from 2 GB to over 40 GB).
*   **GPU (Optional but Recommended):** An NVIDIA or AMD GPU will significantly accelerate model performance.

## Documentation

For more detailed information, troubleshooting, and advanced usage, please refer to the `docs/MANUAL.md` file included in this toolkit.

--- 
*This toolkit was created to simplify the use of local, open-source AI. Enjoy exploring the world of LLMs!*
