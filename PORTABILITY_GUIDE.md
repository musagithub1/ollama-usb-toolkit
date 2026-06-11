# Portability Guide — Moving the USB Between Computers

The Ollama USB Toolkit is designed to be 100% portable. You can pull the USB drive out of a Windows Desktop and plug it directly into a Linux laptop or a MacBook, and the Agent will retain its memory, models, and configuration.

However, because operating systems handle file paths and executables differently, there are a few important rules and best practices you must follow.

---

## 1. Do Not Hardcode Absolute Paths

Because drive letters (Windows) and mount points (macOS/Linux) change depending on the computer you plug the USB into, **you must never use absolute paths in your configuration.**

- **Bad:** `C:\Users\Musa\USB_Drive\ollama-usb-toolkit\models`
- **Good:** Use relative paths (e.g., `./models` or `workspace/`) or let the `START-*` scripts handle the environment variables automatically.

The `START-*` scripts dynamically calculate the current working directory (`pwd` or `%~dp0`) every time they are run, ensuring `OLLAMA_MODELS` always points to the correct location on the flash drive regardless of the host OS.

## 2. Bootstrapping on a New OS

When you plug the USB into a computer running a *different* operating system than the last one:

1. **Run the correct startup script** (`START-Windows.bat`, `START-Mac.command`, or `START-Linux.sh`).
2. **First-time setup:** If Ollama is not installed on the new host machine, you **must** select **Option 1** from the startup menu. 
   - This will install the tiny Ollama background service on the host computer.
   - *Don't worry:* The 1GB+ models and all your data remain on the USB. Only the lightweight engine is installed on the host.

## 3. Handling Line Endings (CRLF vs LF)

If you edit `SKILL.md` files or `agent.json` on Windows (which uses `\r\n` line endings) and then move the USB to a Linux machine (which expects `\n`), you generally won't face issues because Python's `json` and file reading libraries handle this gracefully. 

However, if you write **custom bash scripts** inside the `scripts/` folder on Windows, you must ensure you save them with Unix (LF) line endings, or they will fail to execute when plugged into a macOS or Linux machine.

## 4. Mac Security Permissions (Quarantine)

When moving the USB to a new macOS device, Apple's "Gatekeeper" might block the `START-Mac.command` from running because it was downloaded from the internet or created on a different machine.

**Fix:**
Open your macOS Terminal and remove the quarantine attribute from the entire toolkit folder:
```bash
xattr -cr /Volumes/YourUSBDrive/ollama-usb-toolkit
```

## 5. Safely Ejecting

Because the Ollama engine (`ollama serve`) runs in the background and might be actively writing cache files to the `models/` directory, **you must properly close the agent and eject the USB.**

- **Do not** simply yank the USB out while the Agent API or Web Server is running in the terminal.
- Press `Ctrl+C` in the terminal to kill the servers gracefully.
- Use your operating system's "Safely Remove Hardware" / "Eject" function to ensure all model file buffers are flushed to the flash drive before physical removal.
