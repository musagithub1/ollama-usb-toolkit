# Migrating from v1.2.0 to v2.0.0

**Good news:** v2 is fully **additive**. Nothing from v1 was removed.
You can keep using the v1 chat UI and launcher menu exactly as before.

---

## What's new at a glance

| If you want to… | In v1 you did… | In v2 you can also do… |
|---|---|---|
| Chat with a model in the browser | Open `webui/index.html` | Open **`webui/claw.html`** for the new agentic UI |
| Chat from the terminal | Pick menu option 4 | Run `agent/start-chat.sh` (or .bat) for the new agent |
| Save the conversation | Copy/paste manually | Sessions auto-save to `workspace/sessions/` |
| Have the AI remember you | Not possible | `remember`, `recall`, auto-extracted to `MEMORY.md` |
| Run a tool (e.g. read a file) | Not possible | Ask the agent — it calls `read_file`, `run_shell`, … |
| Add a custom capability | Edit Ollama Modelfiles | Drop a `skills/<name>/SKILL.md` — instant skill |

---

## Step-by-step

### 1. (Optional) Back up your USB

Just copy the old folder somewhere safe.

### 2. Drop in the v2 files

Replace your folder with the v2 zip, or merge file-by-file. Important
items that did **not** exist in v1:

```
agent/                  ← new: agent runtime + launchers
workspace/              ← new: bootstrap files + memory + sessions
skills/                 ← new: drop-in skills
webui/claw.html         ← new: agentic UI
docs/v2/CLAW.md         ← new: full v2 manual
config/agent.json       ← new: agent-specific config
MIGRATION.md            ← this file
```

`webui/index.html`, `START-*`, `scripts/install-ollama.ps1`,
`config/settings.json`, `models/`, `data/`, etc. are all **unchanged**.

### 3. Run the doctor

This creates the bootstrap files and verifies everything:

```bash
# Linux / macOS
python3 agent/claw_agent.py doctor

# Windows
python agent\claw_agent.py doctor
```

You should see:

```
🦞 Claw doctor — checking workspace
  Created/repaired: IDENTITY.md, SOUL.md, USER.md, AGENTS.md, TOOLS.md, MEMORY.md, BOOTSTRAP.md, memory/2026-06-11.md
  Ollama reachable at http://127.0.0.1:11434
  Models installed: …
  Skills loaded: 5
  Sessions on disk: 0
```

### 4. Start the agent

**Browser path** (best UI):

```bash
./agent/start-agent.sh        # Linux/macOS
agent\start-agent.bat         # Windows
```

Then open `webui/claw.html` in your browser.

**Terminal path**:

```bash
./agent/start-chat.sh         # Linux/macOS
agent\start-chat.bat          # Windows
```

### 5. Personalize

Open `workspace/USER.md` and fill in your preferred name, timezone, etc.
Or just tell the agent in chat — it will write it for you.

---

## FAQ

### Do I need to redownload my models?

**No.** Models stay where they were (USB `models/` folder). v2 reads
`OLLAMA_MODELS` exactly like v1 does.

### Will the v1 UI keep working?

**Yes.** `webui/index.html` is untouched. Use whichever UI you prefer.

### Does the agent need internet?

**No** — except the optional `web-search` skill, which only runs if the
model explicitly decides to call it. Disable it by deleting the
`skills/web-search/` folder or setting `enabled: false` in its
`SKILL.md` frontmatter.

### Which models work with tools?

Any Ollama model that supports function calling: **llama3.x**,
**qwen2.5**, **mistral**, **phi3**, etc. For older / unsupported
models, run the agent with `--no-tools` (or set `enable_tools: false`
in `config/agent.json`).

### How do I uninstall v2 and go back to v1?

Delete `agent/`, `workspace/`, `skills/`, `webui/claw.html`,
`config/agent.json`, and revert `VERSION` to `1.2.0`. The v1 toolkit
will be exactly as it was.

---

## Rollback safety

v2 never overwrites:
- `webui/index.html`
- `config/settings.json`
- any of the `START-*` scripts (the v2 menu items are appended, not
  replacing existing options)
- your existing `models/` or `data/`

So there's no risk to your existing setup.
