# Changelog

All notable changes to **Ollama USB Toolkit** are documented here.

## [2.0.0] — 2026-06-11 — "Claw Edition"

This is the **agent upgrade**. The toolkit is no longer just a portable
chat front-end for Ollama — it now ships a full local AI agent inspired
by the [OpenClaw](https://github.com/openclaw/openclaw) personal-assistant
runtime, redesigned to run from a USB drive with **zero dependencies
beyond Python 3.8 and a running Ollama server**.

### ✨ Added

- **`agent/claw_agent.py`** — single-file embedded agent runtime.
  Implements an OpenClaw-style loop:
  *intake → context assembly → inference → tool dispatch → streaming
  reply → persistence*.
- **Workspace bootstrap files** under `workspace/`:
  `IDENTITY.md`, `SOUL.md`, `USER.md`, `AGENTS.md`, `TOOLS.md`,
  `MEMORY.md`, `BOOTSTRAP.md`. Auto-created on first run, user-editable.
- **Active memory** — long-term `MEMORY.md` plus daily notes in
  `workspace/memory/YYYY-MM-DD.md`. Loaded into every system prompt,
  appended via the `remember` tool, and **auto-extracted** when the user
  shares durable facts ("my name is…", "I prefer…", …).
- **Skills system** — drop-in `skills/<name>/SKILL.md` with frontmatter.
  Bundled skills: `web-search`, `calculator`, `file-manager`,
  `system-info`, `code-helper`.
- **Built-in tools** (Ollama function-calling):
  `read_file`, `write_file`, `list_dir`, `run_shell` (sandboxed),
  `remember`, `recall`, `current_time`, `system_info`.
- **Sessions** — auto-saved every turn to
  `workspace/sessions/<id>.json`, fully resumable.
- **Doctor** — `python3 agent/claw_agent.py doctor` validates and
  repairs the workspace + checks Ollama connectivity + lists skills.
- **Claw Agent HTTP API** — `127.0.0.1:11500` with endpoints
  `/agent`, `/skills`, `/memory`, `/sessions`, `/remember`, `/recall`,
  `/health`, `/config`.
- **`webui/claw.html`** — new agentic Web UI featuring:
  - Sessions sidebar (resume any past session)
  - Skills sidebar (live list of loaded skills)
  - Tool log panel (every tool call + result)
  - Memory viewer (live `MEMORY.md`)
  - Agent / Chat toggle
  - Quick-actions: Remember, Recall, Doctor, Save
- **Launcher updates** — `START-*` scripts gain menu items
  **A) Start Claw Agent (terminal)**, **B) Start Claw Agent API**, and
  **C) Doctor**.
- **`agent/start-agent.sh` + `.bat`** — one-click agent API launcher.
- **`agent/start-chat.sh` + `.bat`** — one-click terminal agent.
- **`docs/v2/CLAW.md`** — full v2 manual.

### 🔄 Changed

- `VERSION` bumped to `2.0.0`.
- `config/settings.json` is now **complemented** by
  `config/agent.json` (agent-specific knobs: tool calling, sandbox
  allow-list, memory auto-extract, system prompt extras).
- `README.md` rewritten to introduce both the v1 chat UX and the new v2
  agent UX side-by-side.

### ✅ Preserved

- The original `webui/index.html` plain-chat UI is **still bundled**.
- All v1 launcher menu items (1–9, 0) are unchanged.
- `models/`, `data/`, `logs/`, XDG redirection — unchanged. The drive
  remains 100% portable; nothing is written to the host PC.
- License remains **MIT**.

### 🙏 Inspiration

The workspace bootstrap files, agent-loop ordering, memory file naming,
skills format, and doctor concept are all directly inspired by the
**OpenClaw** project (<https://github.com/openclaw/openclaw>). The
implementation here is a clean-room, USB-targeted Python port — no
OpenClaw code is copied. Their docs (especially `docs/concepts/agent.md`,
`memory.md`, `agent-loop.md`) were the design north-star.

---

## [1.2.0] — 2025

- Cross-platform launchers (Linux / Windows / macOS).
- Pre-flight USB health check.
- Curated model catalogue (11+ models).
- Standalone browser chat UI (`webui/index.html`).
- REST API examples (curl / Python / Node).
- Portable mode via XDG env-var redirection.

## [1.0.0] — Initial release

- Bash + PowerShell installer.
- Manual model selection.
- Local chat against Ollama.
