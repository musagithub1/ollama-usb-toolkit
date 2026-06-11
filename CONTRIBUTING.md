# 🤝 Contributing to Ollama USB Toolkit

Thank you for your interest in contributing! This guide will help you get started.

---

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How to Contribute](#how-to-contribute)
- [Project Structure](#project-structure)
- [Development Setup](#development-setup)
- [Code Style](#code-style)
- [Testing](#testing)
- [Pull Request Process](#pull-request-process)

---

## Code of Conduct

Be respectful. This is an open-source project for everyone. Harassment, discrimination, or hostile behavior will not be tolerated.

---

## How to Contribute

### 🐛 Reporting Bugs

1. Check [existing issues](https://github.com/musagithub1/ollama-usb-toolkit/issues) first.
2. Open a new issue with:
   - Your OS (Linux distro / Windows version / macOS version)
   - USB drive type (USB 2.0 / 3.0 / 3.1)
   - The exact error message or unexpected behavior
   - Steps to reproduce

### 💡 Suggesting Features

Open a [Feature Request issue](https://github.com/musagithub1/ollama-usb-toolkit/issues/new) describing:
- What problem it solves
- How it fits the toolkit's portable/offline-first philosophy

### 🔧 Contributing Code

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature-name`
3. Make your changes (see [Code Style](#code-style))
4. Test on the platforms you have access to
5. Commit: `git commit -m "feat: describe your change"`
6. Push: `git push origin feature/your-feature-name`
7. Open a Pull Request

---

## Project Structure

```
ollama-usb-toolkit/
├── START-Linux.sh          # Linux launcher — Bash
├── START-Windows.bat       # Windows entry point — calls PowerShell
├── START-Mac.command       # macOS launcher — Bash
├── preflight-check.sh      # USB health check — Bash
├── scripts/
│   └── install-ollama.ps1  # Windows full installer — PowerShell
├── webui/
│   └── index.html          # Single-file browser chat UI — HTML/JS/CSS
├── api-examples/           # Code examples for the Ollama REST API
├── config/
│   └── settings.json       # User-editable configuration
├── docs/
│   └── MANUAL.md           # Full user manual
├── installers/             # Place offline Ollama installers here
├── VERSION                 # Semantic version (e.g. 1.2.0)
└── CHANGELOG.md            # Version history
```

---

## Development Setup

### Requirements
- **Linux/macOS:** bash 4+, curl, dd
- **Windows:** PowerShell 5.1+ (comes with Windows 10/11)
- **For testing the Web UI:** Any modern browser

### Running Locally (No USB Needed)

```bash
# Clone the repo
git clone https://github.com/musagithub1/ollama-usb-toolkit.git
cd ollama-usb-toolkit

# Make scripts executable
chmod +x START-Linux.sh preflight-check.sh START-Mac.command

# Run preflight check to validate your environment
./preflight-check.sh

# Launch the toolkit
./START-Linux.sh
```

### Testing the Web UI

```bash
# Start Ollama (requires Ollama installed)
ollama serve &

# Open the Web UI directly in browser
xdg-open webui/index.html   # Linux
open webui/index.html        # macOS
```

---

## Code Style

### Bash Scripts (`START-Linux.sh`, `preflight-check.sh`, `START-Mac.command`)

- Use `#!/usr/bin/env bash` shebang (NOT `/bin/bash` — for portability)
- Use `set -euo pipefail` only where error-exit is safe (avoid in interactive menu loops)
- Use color variables defined at the top — never hardcode ANSI codes inline
- Quote all variables: `"$VAR"` not `$VAR`
- Use `local` for function-scoped variables
- Add a comment block at the top of each major section
- Keep functions focused — one job per function

```bash
# ✅ Good
log INFO "Starting Ollama server..."
export OLLAMA_MODELS="${MODELS_DIR}"

# ❌ Bad
echo -e "\033[0;36m[INFO]\033[0m Starting Ollama server..."
export OLLAMA_MODELS=$MODELS_DIR
```

### PowerShell (`scripts/install-ollama.ps1`)

- Use `Write-Log` for all output (not `Write-Host` directly)
- Use `$ErrorActionPreference = "Continue"` — don't kill the script on minor errors
- Use `PascalCase` for function names: `Install-Ollama`, `Show-Menu`
- Always check `Test-Path` before accessing files

### Web UI (`webui/index.html`)

- Single-file only — no npm, no build step, no external CDN dependencies
- Use CSS variables (`--bg-primary`, `--accent`, etc.) for all colors
- Keep JavaScript vanilla — no frameworks
- New features must work offline (no external API calls)

### Commit Messages

Use [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: add GPU memory display to system info
fix: correct portable mode session-only export
docs: update README with Mac offline install steps
chore: bump VERSION to 1.3.0
```

---

## Testing

Please test your changes on as many platforms as you have access to:

| Platform | How to Test |
|----------|-------------|
| **Linux** | Run `./preflight-check.sh` then `./START-Linux.sh` |
| **Windows** | Double-click `START-Windows.bat`, allow PowerShell |
| **macOS** | Right-click `START-Mac.command` → Open |
| **Web UI** | Open `webui/index.html` with Ollama running |

If you can only test on one platform, clearly state that in your PR so a maintainer or other contributor can test the rest.

---

## Pull Request Process

1. **One PR = one feature or fix.** Don't bundle unrelated changes.
2. **Update `CHANGELOG.md`** under `[Unreleased]` with a summary of what you changed.
3. **Bump `VERSION`** if your change warrants it (follow [SemVer](https://semver.org/)):
   - `PATCH` (1.2.x) — bug fixes
   - `MINOR` (1.x.0) — new features, backward compatible
   - `MAJOR` (x.0.0) — breaking changes
4. **Update README.md** if you add new files, options, or platform support.
5. PRs are reviewed within a few days. Be patient and responsive to feedback.

---

## Questions?

Open a [Discussion](https://github.com/musagithub1/ollama-usb-toolkit/issues) or an issue — happy to help!
