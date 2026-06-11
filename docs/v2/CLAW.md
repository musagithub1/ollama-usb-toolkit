# 🦞 Claw — the agent inside the Ollama USB Toolkit

> **TL;DR** — v2.0.0 turns the toolkit from a *chat* into an *agent*.
> Plug in the USB, start the agent, and you get an OpenClaw-inspired
> personal assistant that **remembers**, **uses tools**, **runs skills**,
> and **gets better the more you talk to it** — all locally.

---

## 1. What changed in v2

| Area | v1.2.0 | v2.0.0 (Claw Edition) |
|---|---|---|
| Interaction | Plain chat against Ollama | **Agentic loop** with tool calling |
| Memory | None | **Active memory**: `MEMORY.md` + daily notes, auto-extract on durable facts |
| Persona | None | **Workspace bootstrap files** (IDENTITY / SOUL / USER / AGENTS / TOOLS) |
| Skills | None | **`skills/<name>/SKILL.md`** drop-in skills (web-search, calculator, file-manager, system-info, code-helper) |
| Tools | None | `read_file`, `write_file`, `list_dir`, `run_shell`, `remember`, `recall`, `current_time`, `system_info` |
| WebUI | Chat-only `webui/index.html` | **`webui/claw.html`** — sessions, tool log, memory viewer, agent/chat toggle |
| API | Ollama 11434 only | **Claw Agent API at 127.0.0.1:11500** + Ollama at 11434 |
| Sessions | Lost on close | **`workspace/sessions/<id>.json`** — auto-saved every turn, resumable |
| Doctor | None | `claw_agent.py doctor` — validates & repairs workspace |

The original v1 chat UI (`webui/index.html`) **is still there**.
v2 is **additive** — nothing was removed.

---

## 2. The agent loop (OpenClaw-inspired, USB-friendly)

```
┌───────────────────────────────────────────────────────────────┐
│  intake (user message)                                        │
│       │                                                       │
│       ▼                                                       │
│  context assembly                                             │
│   ├─ workspace bootstrap files (IDENTITY/SOUL/USER/AGENTS/…)  │
│   ├─ MEMORY.md (long-term)                                    │
│   ├─ memory/YYYY-MM-DD.md (today + yesterday)                 │
│   └─ skills snapshot (skills/*/SKILL.md)                      │
│       │                                                       │
│       ▼                                                       │
│  Ollama inference  ── tool_call?  ── yes ──► dispatch tool ──┐│
│       │                                                      ││
│       │ no                                                   ││
│       ▼                                                      ││
│  streaming reply                              ◄──────────────┘│
│       │                                                       │
│       ▼                                                       │
│  persistence (sessions/<id>.json) + maybe MEMORY.md append    │
└───────────────────────────────────────────────────────────────┘
```

This mirrors the OpenClaw runtime loop (intake → context → inference →
tools → stream → persist) but stripped down so it runs on plain Python +
Ollama, with **zero external dependencies** beyond the standard library.

---

## 3. Workspace layout (lives on your USB)

```
workspace/
├── IDENTITY.md     ← agent name + emoji + vibe
├── SOUL.md         ← persona, boundaries, tone
├── USER.md         ← what the agent knows about you
├── AGENTS.md       ← operating instructions for the agent
├── TOOLS.md        ← user notes about tools
├── MEMORY.md       ← long-term facts (auto-appended via `remember`)
├── BOOTSTRAP.md    ← first-run ritual (delete after use)
├── memory/
│   ├── 2026-06-11.md
│   └── 2026-06-10.md
└── sessions/
    └── 20260611-091203-a1b2c3.json
```

You can edit any of these by hand. The agent will read your edits on the
next turn.

---

## 4. Quick start

### 4a. Start the Ollama server

Use the existing main launcher (`START-Linux.sh` / `START-Windows.bat` /
`START-Mac.command`) and pick **option 5** ("Start Ollama Server").

### 4b. Start the Claw agent API

```bash
# Linux / macOS
./agent/start-agent.sh

# Windows
agent\start-agent.bat
```

This:
1. Validates the workspace and creates any missing bootstrap files.
2. Starts an HTTP API at `http://127.0.0.1:11500` so the new WebUI can
   talk to the agent.

### 4c. Open the new WebUI

Open `webui/claw.html` in your browser. You should see two green LEDs in
the top bar (Ollama + Agent API). If only Ollama is green, you skipped 4b.

### 4d. Or: just talk in the terminal

```bash
./agent/start-chat.sh                    # interactive
./agent/start-chat.sh --model llama3.2   # pick a model
./agent/start-chat.sh --no-tools         # plain chat mode
```

In-chat slash commands: `/save`, `/recall <q>`, `/remember <fact>`,
`/skills`, `/sessions`, `/model <name>`, `/tools on|off`, `/help`.

---

## 5. Built-in tools

| Tool | What it does |
|---|---|
| `read_file(path)` | Read any UTF-8 file on the USB |
| `write_file(path, content)` | Write — restricted to `workspace/` |
| `list_dir(path)` | List directory contents |
| `run_shell(command)` | Run a shell command, sandboxed by allow-list |
| `remember(fact)` | Append a durable fact to `MEMORY.md` |
| `recall(query)` | Search `MEMORY.md` + daily notes |
| `current_time()` | Local ISO timestamp |
| `system_info()` | OS / disk / hostname / Python version |

Tool calls go through Ollama's native function-calling, so models that
support tools (llama3.x, qwen2.5, mistral, phi3, etc.) will use them
automatically. Use `--no-tools` for models that don't.

---

## 6. Skills

Drop a folder into `skills/`:

```
skills/my-skill/
└── SKILL.md
```

```markdown
---
name: my-skill
summary: "What this skill does in one line"
enabled: true
---
# my-skill

Free-form instructions the agent will read at the start of every session.
You can reference built-in tools or include scripts in the same folder
(invoke them via `run_shell`).
```

Bundled skills:
- **web-search** — DuckDuckGo HTML search (only when user asks)
- **calculator** — sandboxed `math.*` evaluator
- **file-manager** — safe read/write inside `workspace/`
- **system-info** — defer machine questions to `system_info`
- **code-helper** — read-then-propose-then-write workflow

---

## 7. How memory makes Claw "smarter" over time

Two paths:

1. **You ask explicitly** —
   *"Remember that I prefer TypeScript."* → Claw calls the `remember`
   tool → appended to `MEMORY.md`. Loaded into the system prompt of every
   future session.

2. **Auto-extract** — when you write a sentence like *"my name is …"*,
   *"I prefer …"*, *"I work on …"*, the agent runtime appends an
   `(auto)` line to `MEMORY.md`. Toggle off with
   `memory_auto_extract: false` in `config/agent.json`.

This is the closest USB-friendly equivalent to OpenClaw's "memory plugin"
slot — durable, file-based, and inspectable.

---

## 8. HTTP API (used by `webui/claw.html`)

```
GET  /health                 -> {ok, ollama, version}
GET  /skills                 -> {skills: [...]}
GET  /memory                 -> {memory: <MEMORY.md>, user: <USER.md>}
GET  /sessions               -> {sessions: [...]}
GET  /config                 -> merged config

POST /agent      {message, model?, session_id?}
                  -> {session_id, reply, tools[], turns}
POST /remember   {fact}      -> {result}
POST /recall     {query}     -> {result}
```

It listens on `127.0.0.1:11500` only (never exposed to the network).

---

## 9. CLI reference

```
python3 agent/claw_agent.py chat       # interactive terminal chat
python3 agent/claw_agent.py serve      # start agent HTTP API on :11500
python3 agent/claw_agent.py doctor     # validate & repair workspace
python3 agent/claw_agent.py sessions   # list saved sessions
python3 agent/claw_agent.py skills     # list installed skills
```

---

## 10. Privacy & portability

- Everything still lives on the USB — `workspace/`, `models/`, `sessions/`,
  `MEMORY.md`. Nothing is written outside `XDG_*` paths on the host.
- The agent API binds to `127.0.0.1` only.
- The web-search skill is the **only** thing that touches the internet,
  and only when the model decides to call it.
- License remains MIT.
