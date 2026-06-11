#!/usr/bin/env python3
"""
=============================================================================
  Claw Agent  —  Ollama USB Toolkit v2.0.0
  An OpenClaw-inspired portable AI agent that runs from your USB drive.
=============================================================================

Single embedded agent runtime:
    intake -> context assembly -> Ollama inference -> tool execution
    -> streaming reply -> persistence

Features (modeled on OpenClaw concepts, USB-friendly, pure-Python):
  * Workspace bootstrap files (AGENTS.md, SOUL.md, MEMORY.md, USER.md, ...)
  * Active memory: agent learns about the user across sessions
  * Skills system: drop a skills/<name>/SKILL.md file to extend the agent
  * Built-in tools: file I/O, list_dir, run_shell, remember, recall, ...
  * Sessions persisted under workspace/sessions/<id>.json
  * Doctor: validate + repair workspace
  * Streaming responses, tool call loop, sandboxed shell

Designed to require nothing but Python 3.8+ and a running Ollama server.
=============================================================================
"""

from __future__ import annotations

import argparse
import datetime as dt
import json
import os
import platform
import re
import shlex
import subprocess
import sys
import textwrap
import time
import urllib.error
import urllib.parse
import urllib.request
import uuid
from pathlib import Path
from typing import Any, Callable

# ---------------------------------------------------------------------------
# Paths — everything stays on the USB drive
# ---------------------------------------------------------------------------

USB_ROOT = Path(__file__).resolve().parent.parent
WORKSPACE = USB_ROOT / "workspace"
MEMORY_DIR = WORKSPACE / "memory"
SESSIONS_DIR = WORKSPACE / "sessions"
SKILLS_DIR = USB_ROOT / "skills"
CONFIG_FILE = USB_ROOT / "config" / "settings.json"
AGENT_CONFIG = USB_ROOT / "config" / "agent.json"
LOG_DIR = USB_ROOT / "logs"

for d in (WORKSPACE, MEMORY_DIR, SESSIONS_DIR, LOG_DIR):
    d.mkdir(parents=True, exist_ok=True)

# ---------------------------------------------------------------------------
# Color output (no external deps)
# ---------------------------------------------------------------------------

class C:
    R = "\033[0m"
    DIM = "\033[2m"
    BOLD = "\033[1m"
    RED = "\033[31m"
    GRN = "\033[32m"
    YEL = "\033[33m"
    BLU = "\033[34m"
    MAG = "\033[35m"
    CYN = "\033[36m"
    WHT = "\033[37m"


def use_color() -> bool:
    return sys.stdout.isatty() and os.environ.get("NO_COLOR") is None


def cprint(text: str, color: str = "") -> None:
    if use_color() and color:
        print(f"{color}{text}{C.R}")
    else:
        print(text)


# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------

DEFAULT_AGENT_CONFIG: dict[str, Any] = {
    "default_model": "phi3:mini",
    "ollama_host": "127.0.0.1",
    "ollama_port": 11434,
    "system_prompt_extra": "",
    "agent_mode": True,
    "enable_tools": True,
    "enable_skills": True,
    "memory_auto_extract": True,
    "max_tool_iterations": 6,
    "shell_sandbox": True,
    "shell_allow_list": [
        "ls", "dir", "pwd", "cd", "echo", "cat", "type",
        "head", "tail", "wc", "find", "grep", "uname",
        "whoami", "date", "df", "du", "ps", "free",
        "python", "python3", "pip", "node", "git",
    ],
}


def load_config() -> dict[str, Any]:
    cfg: dict[str, Any] = dict(DEFAULT_AGENT_CONFIG)
    if CONFIG_FILE.exists():
        try:
            cfg.update(json.loads(CONFIG_FILE.read_text()))
        except Exception:
            pass
    if AGENT_CONFIG.exists():
        try:
            cfg.update(json.loads(AGENT_CONFIG.read_text()))
        except Exception:
            pass
    return cfg


def save_agent_config(cfg: dict[str, Any]) -> None:
    AGENT_CONFIG.parent.mkdir(parents=True, exist_ok=True)
    AGENT_CONFIG.write_text(json.dumps(cfg, indent=2))


# ---------------------------------------------------------------------------
# Workspace bootstrap files (OpenClaw-style)
# ---------------------------------------------------------------------------

BOOTSTRAP_TEMPLATES: dict[str, str] = {
    "IDENTITY.md": """# Identity

**Name:** Claw
**Emoji:** 🦞
**Vibe:** Helpful, concise, a little playful. Local. Private. Yours.

I am the agent embedded inside the **Ollama USB Toolkit** — a portable AI
assistant that lives on your USB drive and runs entirely on your machine.
""",
    "SOUL.md": """# Soul — Persona, boundaries, tone

* I am **local-first**. I never call cloud APIs unless you explicitly install a
  skill that does.
* I am **honest**. If I don't know something, I say so.
* I am **concise** by default. I expand when asked.
* I respect privacy: nothing leaves this USB unless you tell me to.
* I follow the user's lead. I do not lecture.
""",
    "USER.md": """# User profile

> Edit this file (or just tell me about yourself in chat — I will update it).

**Preferred name:** _unset_
**Pronouns:** _unset_
**Timezone:** _unset_
**Operating system:** _auto-detected at runtime_
**Stack / interests:** _unset_

## Notes
""",
    "AGENTS.md": """# Agents — operating instructions

You are **Claw**, an AI agent running locally from a USB drive.

## How you work
1. You receive a user message.
2. You may call **tools** (function-calling) to read files, run commands,
   search memory, or use installed skills.
3. You may use **memory**: long-term in `MEMORY.md`, daily notes in
   `memory/YYYY-MM-DD.md`. Use the `remember` tool to add a durable fact.
4. You stream a final reply.

## Rules
* Prefer tools over guessing when the user asks about *their* environment.
* When the user shares a durable fact ("I prefer X", "my project is Y"),
  call `remember` to write it to `MEMORY.md`.
* Keep replies short unless detail is requested.
* Code blocks must be fenced and language-tagged.
* Never write outside `workspace/` without explicit user permission.
""",
    "MEMORY.md": """# Long-term memory

> Durable facts about the user, projects, and standing decisions. The agent
> may append to this file via the `remember` tool. You can edit it manually.

""",
    "TOOLS.md": """# Tools — user notes

Built-in tools available to the agent (function-calling):

| Tool          | Purpose                                                   |
|---------------|-----------------------------------------------------------|
| `read_file`   | Read a UTF-8 text file from the USB                       |
| `write_file`  | Create / overwrite a text file inside `workspace/`        |
| `list_dir`    | List files in a directory                                 |
| `run_shell`   | Run a shell command (sandboxed allow-list by default)     |
| `remember`    | Append a durable fact to `MEMORY.md`                      |
| `recall`      | Search `MEMORY.md` and daily notes for a keyword          |
| `current_time`| Get current local time / date                             |
| `system_info` | OS / RAM / CPU / GPU summary                              |

Add or remove notes here freely; this file is just guidance for the agent.
""",
    "BOOTSTRAP.md": """# Bootstrap — first-run ritual

Welcome! On your first conversation, please:

1. Greet the user and ask their preferred **name**.
2. Ask what they would like Claw to help with on this USB.
3. Use the `remember` tool to save the answer to `MEMORY.md`.
4. **Delete this file** (`workspace/BOOTSTRAP.md`) once the ritual is done —
   it will not be recreated.
""",
}


def ensure_workspace(repair: bool = False) -> list[str]:
    """Create any missing bootstrap files. Returns list of created files."""
    created: list[str] = []
    for name, body in BOOTSTRAP_TEMPLATES.items():
        target = WORKSPACE / name
        if not target.exists():
            target.write_text(body)
            created.append(name)
        elif repair and target.stat().st_size == 0:
            target.write_text(body)
            created.append(name + " (repaired empty)")
    today = dt.date.today().isoformat()
    daily = MEMORY_DIR / f"{today}.md"
    if not daily.exists():
        daily.write_text(f"# {today}\n\n")
        created.append(f"memory/{today}.md")
    return created


def load_bootstrap_context(max_chars_per_file: int = 4000) -> str:
    """Read all bootstrap files, return as one big system-prompt block."""
    parts: list[str] = []
    order = ["IDENTITY.md", "SOUL.md", "USER.md", "AGENTS.md", "TOOLS.md",
             "MEMORY.md", "BOOTSTRAP.md"]
    for name in order:
        f = WORKSPACE / name
        if not f.exists():
            parts.append(f"## [{name}] (missing)\n")
            continue
        body = f.read_text()
        if not body.strip():
            continue
        if len(body) > max_chars_per_file:
            body = body[:max_chars_per_file] + f"\n\n[…truncated {len(body)-max_chars_per_file} chars…]"
        parts.append(f"## [{name}]\n{body}")

    today = dt.date.today().isoformat()
    yest = (dt.date.today() - dt.timedelta(days=1)).isoformat()
    for d in (yest, today):
        f = MEMORY_DIR / f"{d}.md"
        if f.exists() and f.read_text().strip():
            body = f.read_text()
            if len(body) > 2000:
                body = body[:2000] + "\n[…truncated…]"
            parts.append(f"## [memory/{d}.md]\n{body}")

    return "\n\n".join(parts)


# ---------------------------------------------------------------------------
# Skills loader (drop-in skills/<name>/SKILL.md)
# ---------------------------------------------------------------------------

def load_skills() -> list[dict[str, Any]]:
    skills: list[dict[str, Any]] = []
    if not SKILLS_DIR.exists():
        return skills
    for skill_path in sorted(SKILLS_DIR.iterdir()):
        if not skill_path.is_dir():
            continue
        skill_md = skill_path / "SKILL.md"
        if not skill_md.exists():
            continue
        text = skill_md.read_text()
        meta: dict[str, Any] = {"name": skill_path.name, "path": str(skill_path)}
        m = re.match(r"^---\n(.*?)\n---\n", text, re.DOTALL)
        if m:
            for line in m.group(1).splitlines():
                if ":" in line:
                    k, v = line.split(":", 1)
                    meta[k.strip()] = v.strip().strip('"\'')
            text = text[m.end():]
        meta["body"] = text.strip()
        if meta.get("enabled", "true").lower() != "false":
            skills.append(meta)
    return skills


def skills_prompt_block(skills: list[dict[str, Any]]) -> str:
    if not skills:
        return ""
    lines = ["## Installed skills",
             "These are loaded from `skills/<name>/SKILL.md`. Use the matching tool",
             "or follow the skill's instructions when relevant.\n"]
    for s in skills:
        lines.append(f"### {s.get('name')} — {s.get('summary', '(no summary)')}")
        lines.append(s["body"])
        lines.append("")
    return "\n".join(lines)


# ---------------------------------------------------------------------------
# Built-in tools (Ollama / OpenAI function-calling style)
# ---------------------------------------------------------------------------

def _safe_path(p: str) -> Path:
    """Resolve a path, but never escape USB_ROOT for write ops."""
    pp = (USB_ROOT / p).resolve() if not os.path.isabs(p) else Path(p).resolve()
    return pp


def tool_read_file(path: str) -> str:
    p = _safe_path(path)
    if not p.exists():
        return f"ERROR: file not found: {path}"
    try:
        return p.read_text(errors="replace")[:20000]
    except Exception as e:
        return f"ERROR: {e}"


def tool_write_file(path: str, content: str) -> str:
    p = _safe_path(path)
    try:
        p.relative_to(WORKSPACE)
    except ValueError:
        return f"ERROR: write_file is restricted to workspace/. Got: {p}"
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(content)
    return f"OK: wrote {len(content)} bytes to {p.relative_to(USB_ROOT)}"


def tool_list_dir(path: str = ".") -> str:
    p = _safe_path(path)
    if not p.exists():
        return f"ERROR: not found: {path}"
    if not p.is_dir():
        return f"ERROR: not a directory: {path}"
    items = []
    for c in sorted(p.iterdir()):
        kind = "DIR " if c.is_dir() else "FILE"
        size = c.stat().st_size if c.is_file() else 0
        items.append(f"{kind} {size:>10} {c.name}")
    return "\n".join(items) or "(empty)"


def tool_run_shell(command: str, cfg: dict[str, Any]) -> str:
    if cfg.get("shell_sandbox", True):
        first = shlex.split(command)[0] if command.strip() else ""
        if first not in cfg.get("shell_allow_list", []):
            return (f"ERROR: shell sandbox blocked '{first}'. "
                    f"Add it to config/agent.json shell_allow_list, "
                    f"or set shell_sandbox: false.")
    try:
        out = subprocess.run(
            command, shell=True, capture_output=True,
            text=True, timeout=20, cwd=str(USB_ROOT),
        )
        result = out.stdout
        if out.stderr:
            result += f"\n[stderr]\n{out.stderr}"
        if out.returncode != 0:
            result += f"\n[exit code: {out.returncode}]"
        return result[:8000] or "(no output)"
    except subprocess.TimeoutExpired:
        return "ERROR: command timed out (20s)"
    except Exception as e:
        return f"ERROR: {e}"


def tool_remember(fact: str) -> str:
    mem = WORKSPACE / "MEMORY.md"
    stamp = dt.datetime.now().strftime("%Y-%m-%d")
    line = f"- ({stamp}) {fact.strip()}\n"
    with mem.open("a") as f:
        f.write(line)
    return f"OK: remembered. MEMORY.md now {mem.stat().st_size} bytes."


def tool_recall(query: str) -> str:
    hits: list[str] = []
    needle = query.lower()
    sources = [WORKSPACE / "MEMORY.md"] + sorted(MEMORY_DIR.glob("*.md"))
    for src in sources:
        if not src.exists():
            continue
        for ln in src.read_text().splitlines():
            if needle in ln.lower():
                hits.append(f"[{src.name}] {ln.strip()}")
    return "\n".join(hits[:30]) or f"(no hits for '{query}')"


def tool_current_time() -> str:
    return dt.datetime.now().astimezone().isoformat()


def tool_system_info() -> str:
    info = {
        "os": f"{platform.system()} {platform.release()}",
        "machine": platform.machine(),
        "python": platform.python_version(),
        "node": platform.node(),
        "cwd": str(USB_ROOT),
    }
    try:
        import shutil
        total, used, free = shutil.disk_usage(str(USB_ROOT))
        info["usb_free_gb"] = round(free / 1e9, 2)
        info["usb_total_gb"] = round(total / 1e9, 2)
    except Exception:
        pass
    return json.dumps(info, indent=2)


TOOL_SCHEMAS: list[dict[str, Any]] = [
    {
        "type": "function",
        "function": {
            "name": "read_file",
            "description": "Read a UTF-8 text file from the USB drive.",
            "parameters": {
                "type": "object",
                "properties": {"path": {"type": "string"}},
                "required": ["path"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "write_file",
            "description": "Create or overwrite a text file. Restricted to workspace/.",
            "parameters": {
                "type": "object",
                "properties": {
                    "path": {"type": "string"},
                    "content": {"type": "string"},
                },
                "required": ["path", "content"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "list_dir",
            "description": "List files in a directory on the USB drive.",
            "parameters": {
                "type": "object",
                "properties": {"path": {"type": "string"}},
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "run_shell",
            "description": "Run a shell command. Sandboxed by allow-list by default.",
            "parameters": {
                "type": "object",
                "properties": {"command": {"type": "string"}},
                "required": ["command"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "remember",
            "description": "Append a durable fact about the user/project to MEMORY.md.",
            "parameters": {
                "type": "object",
                "properties": {"fact": {"type": "string"}},
                "required": ["fact"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "recall",
            "description": "Search long-term memory and daily notes for a keyword.",
            "parameters": {
                "type": "object",
                "properties": {"query": {"type": "string"}},
                "required": ["query"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "current_time",
            "description": "Get the current local date/time (ISO format).",
            "parameters": {"type": "object", "properties": {}},
        },
    },
    {
        "type": "function",
        "function": {
            "name": "system_info",
            "description": "Get OS / machine / disk info for the host running the USB.",
            "parameters": {"type": "object", "properties": {}},
        },
    },
]


def dispatch_tool(name: str, args: dict[str, Any], cfg: dict[str, Any]) -> str:
    try:
        if name == "read_file":
            return tool_read_file(args.get("path", ""))
        if name == "write_file":
            return tool_write_file(args.get("path", ""), args.get("content", ""))
        if name == "list_dir":
            return tool_list_dir(args.get("path", "."))
        if name == "run_shell":
            return tool_run_shell(args.get("command", ""), cfg)
        if name == "remember":
            return tool_remember(args.get("fact", ""))
        if name == "recall":
            return tool_recall(args.get("query", ""))
        if name == "current_time":
            return tool_current_time()
        if name == "system_info":
            return tool_system_info()
        return f"ERROR: unknown tool '{name}'"
    except Exception as e:
        return f"ERROR: tool {name} crashed: {e}"


# ---------------------------------------------------------------------------
# Ollama HTTP client (no external deps)
# ---------------------------------------------------------------------------

class OllamaClient:
    def __init__(self, host: str, port: int) -> None:
        self.base = f"http://{host}:{port}"

    def ping(self) -> bool:
        try:
            urllib.request.urlopen(f"{self.base}/api/tags", timeout=2)
            return True
        except Exception:
            return False

    def list_models(self) -> list[dict[str, Any]]:
        try:
            with urllib.request.urlopen(f"{self.base}/api/tags", timeout=5) as r:
                return json.loads(r.read()).get("models", [])
        except Exception:
            return []

    def chat(self, model: str, messages: list[dict[str, Any]],
             tools: list[dict[str, Any]] | None = None,
             stream: bool = False) -> dict[str, Any]:
        payload: dict[str, Any] = {"model": model, "messages": messages,
                                   "stream": stream}
        if tools:
            payload["tools"] = tools
        data = json.dumps(payload).encode()
        req = urllib.request.Request(
            f"{self.base}/api/chat", data=data,
            headers={"Content-Type": "application/json"},
        )
        if not stream:
            with urllib.request.urlopen(req, timeout=1200) as r:
                return json.loads(r.read())
        # Streaming: return a generator-like list
        out: list[dict[str, Any]] = []
        with urllib.request.urlopen(req, timeout=1200) as r:
            for line in r:
                if not line.strip():
                    continue
                out.append(json.loads(line))
        return {"_stream": out}


# ---------------------------------------------------------------------------
# Memory auto-extract (lightweight heuristic)
# ---------------------------------------------------------------------------

REMEMBER_TRIGGERS = re.compile(
    r"\b(my name is|i (?:am|'m) (?:a|an)?|i prefer|i use|i work|i live|"
    r"call me|remember (?:that )?|note that)\b",
    re.IGNORECASE,
)


def maybe_extract_memory(user_text: str) -> str | None:
    if REMEMBER_TRIGGERS.search(user_text) and len(user_text) < 400:
        return user_text.strip()
    return None


# ---------------------------------------------------------------------------
# Session persistence
# ---------------------------------------------------------------------------

def new_session_id(mode: str = "agent") -> str:
    return f"{mode}-" + dt.datetime.now().strftime("%Y%m%d-%H%M%S") + "-" + uuid.uuid4().hex[:6]


def save_session(session_id: str, messages: list[dict[str, Any]],
                 model: str) -> Path:
    f = SESSIONS_DIR / f"{session_id}.json"
    f.write_text(json.dumps({
        "id": session_id,
        "model": model,
        "saved_at": dt.datetime.now().isoformat(),
        "messages": messages,
    }, indent=2, default=str))
    return f


def load_session(session_id: str) -> dict[str, Any] | None:
    f = SESSIONS_DIR / f"{session_id}.json"
    if not f.exists():
        return None
    try:
        return json.loads(f.read_text())
    except Exception:
        return None


def list_sessions(limit: int = 20, mode: str | None = None) -> list[dict[str, Any]]:
    pattern = f"{mode}-*.json" if mode else "*.json"
    files = sorted(SESSIONS_DIR.glob(pattern), reverse=True)[:limit]
    out: list[dict[str, Any]] = []
    for f in files:
        try:
            d = json.loads(f.read_text())
            out.append({
                "id": d["id"],
                "model": d.get("model"),
                "turns": len(d.get("messages", [])),
                "saved_at": d.get("saved_at"),
            })
        except Exception:
            continue
    return out


# ---------------------------------------------------------------------------
# Agent loop
# ---------------------------------------------------------------------------

def build_system_prompt(cfg: dict[str, Any]) -> str:
    bootstrap = load_bootstrap_context()
    skills = load_skills() if cfg.get("enable_skills", True) else []
    skills_block = skills_prompt_block(skills) if skills else ""
    extra = cfg.get("system_prompt_extra", "")

    header = textwrap.dedent("""\
        # Claw — local AI agent

        You are Claw, a personal AI agent that runs locally on a USB drive
        via Ollama. The user's data never leaves this machine.

        Below you will find your bootstrap workspace files (your operating
        instructions, persona, memory, etc.) and any installed skills.
        Use tools when they help. Be concise.
        """)

    return "\n\n".join(p for p in [header, bootstrap, skills_block, extra] if p)


def run_agent_turn(client: OllamaClient, model: str, messages: list[dict[str, Any]],
                   cfg: dict[str, Any], on_token: Callable[[str], None] | None = None,
                   on_tool: Callable[[str, dict[str, Any], str], None] | None = None,
                   ) -> str:
    """One agentic turn. Returns the final assistant text."""
    tools = TOOL_SCHEMAS if cfg.get("enable_tools", True) else None
    iterations = 0
    final_text = ""
    while iterations < cfg.get("max_tool_iterations", 6):
        iterations += 1
        resp = client.chat(model=model, messages=messages,
                           tools=tools, stream=False)
        msg = resp.get("message", {})
        tool_calls = msg.get("tool_calls") or []
        if tool_calls:
            messages.append({
                "role": "assistant",
                "content": msg.get("content", "") or "",
                "tool_calls": tool_calls,
            })
            for call in tool_calls:
                fn = call.get("function", {})
                fname = fn.get("name", "")
                fargs = fn.get("arguments", {}) or {}
                if isinstance(fargs, str):
                    try:
                        fargs = json.loads(fargs)
                    except Exception:
                        fargs = {}
                result = dispatch_tool(fname, fargs, cfg)
                if on_tool:
                    on_tool(fname, fargs, result)
                messages.append({
                    "role": "tool",
                    "content": result,
                    "name": fname,
                })
            continue  # let the model see tool results
        # No tool calls -> final answer (re-stream for nicer UX)
        content = msg.get("content", "")
        final_text = content
        if on_token:
            on_token(content)
        messages.append({"role": "assistant", "content": content})
        break
    return final_text


# ---------------------------------------------------------------------------
# CLI commands
# ---------------------------------------------------------------------------

def cmd_doctor(_args: argparse.Namespace) -> int:
    cprint("🦞 Claw doctor — checking workspace", C.CYN)
    created = ensure_workspace(repair=True)
    if created:
        cprint(f"  Created/repaired: {', '.join(created)}", C.GRN)
    else:
        cprint("  Workspace OK", C.GRN)
    cfg = load_config()
    client = OllamaClient(cfg["ollama_host"], cfg["ollama_port"])
    if client.ping():
        cprint(f"  Ollama reachable at {client.base}", C.GRN)
        models = client.list_models()
        cprint(f"  Models installed: {len(models)}", C.GRN)
        for m in models[:10]:
            sz = m.get("size", 0) / 1e9
            cprint(f"    - {m.get('name')} ({sz:.1f} GB)", C.DIM)
    else:
        cprint(f"  Ollama NOT reachable at {client.base}. Start it first.", C.RED)
    skills = load_skills()
    cprint(f"  Skills loaded: {len(skills)}", C.GRN)
    for s in skills:
        cprint(f"    - {s['name']}: {s.get('summary', '')}", C.DIM)
    sessions = list_sessions()
    cprint(f"  Sessions on disk: {len(sessions)}", C.GRN)
    return 0


def cmd_chat(args: argparse.Namespace) -> int:
    cfg = load_config()
    if args.model:
        cfg["default_model"] = args.model
    if args.no_tools:
        cfg["enable_tools"] = False

    ensure_workspace()
    client = OllamaClient(cfg["ollama_host"], cfg["ollama_port"])
    if not client.ping():
        cprint(f"❌ Ollama is not running at {client.base}.", C.RED)
        cprint("   Start it from the main menu (option 5) or run `ollama serve`.", C.YEL)
        return 2

    model = cfg["default_model"]
    sid = args.session or new_session_id()
    session = load_session(sid) if args.session else None
    if session:
        messages: list[dict[str, Any]] = session["messages"]
        cprint(f"📂 Resumed session {sid} ({len(messages)} messages)", C.MAG)
    else:
        messages = [{"role": "system", "content": build_system_prompt(cfg)}]
        cprint(f"🆕 New session {sid}", C.MAG)

    cprint(f"🦞 Claw — model: {C.BOLD}{model}{C.R}{C.DIM} | tools: "
           f"{cfg['enable_tools']} | skills: {cfg['enable_skills']} | "
           f"workspace: workspace/", C.DIM)
    cprint("Type 'exit' / 'quit' to end. Type '/help' for commands.\n", C.DIM)

    while True:
        try:
            user = input(f"{C.GRN}you ›{C.R} " if use_color() else "you › ")
        except (EOFError, KeyboardInterrupt):
            print()
            break
        u = user.strip()
        if not u:
            continue
        if u.lower() in {"exit", "quit", ":q"}:
            break
        if u == "/help":
            cprint("/save             save session\n/recall <q>       search memory\n"
                   "/remember <fact>  store a durable fact\n/skills           list skills\n"
                   "/sessions         list sessions\n/model <name>     switch model\n"
                   "/tools on|off     toggle tool calling\nexit              quit", C.DIM)
            continue
        if u == "/save":
            p = save_session(sid, messages, model)
            cprint(f"saved → {p.relative_to(USB_ROOT)}", C.GRN)
            continue
        if u.startswith("/recall "):
            cprint(tool_recall(u[8:].strip()), C.CYN)
            continue
        if u.startswith("/remember "):
            cprint(tool_remember(u[10:].strip()), C.CYN)
            continue
        if u == "/skills":
            for s in load_skills():
                cprint(f"  • {s['name']}: {s.get('summary','')}", C.CYN)
            continue
        if u == "/sessions":
            for s in list_sessions():
                cprint(f"  • {s['id']} ({s['turns']} turns, {s['model']})", C.CYN)
            continue
        if u.startswith("/model "):
            model = u[7:].strip()
            cprint(f"switched to {model}", C.GRN)
            continue
        if u == "/tools on":
            cfg["enable_tools"] = True; cprint("tools ON", C.GRN); continue
        if u == "/tools off":
            cfg["enable_tools"] = False; cprint("tools OFF", C.YEL); continue

        # Auto-extract memory from user message
        if cfg.get("memory_auto_extract", True):
            fact = maybe_extract_memory(u)
            if fact:
                tool_remember(f"(auto) {fact}")

        messages.append({"role": "user", "content": u})

        def on_tool(name: str, args: dict[str, Any], result: str) -> None:
            preview = (result[:140] + "…") if len(result) > 140 else result
            cprint(f"  ⚙ {name}({json.dumps(args)[:80]}) → {preview}", C.YEL)

        cprint("claw ›", C.BLU)
        try:
            text = run_agent_turn(client, model, messages, cfg,
                                  on_tool=on_tool)
            print(text)
            print()
        except urllib.error.HTTPError as e:
            cprint(f"HTTP error from Ollama: {e}", C.RED)
        except Exception as e:
            cprint(f"Agent error: {e}", C.RED)

        # Auto-save every turn
        save_session(sid, messages, model)

    save_session(sid, messages, model)
    cprint(f"💾 session saved → workspace/sessions/{sid}.json", C.GRN)
    return 0


def cmd_serve(args: argparse.Namespace) -> int:
    """Run a tiny HTTP API the WebUI v2 can talk to."""
    from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

    cfg = load_config()
    ensure_workspace()
    client = OllamaClient(cfg["ollama_host"], cfg["ollama_port"])

    class Handler(BaseHTTPRequestHandler):
        def _json(self, code: int, payload: dict[str, Any]) -> None:
            body = json.dumps(payload).encode()
            self.send_response(code)
            self.send_header("Content-Type", "application/json")
            self.send_header("Access-Control-Allow-Origin", "*")
            self.send_header("Access-Control-Allow-Headers", "*")
            self.send_header("Access-Control-Allow-Methods", "*")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)

        def do_OPTIONS(self) -> None:  # noqa: N802
            self._json(200, {"ok": True})

        def do_GET(self) -> None:  # noqa: N802
            parsed = urllib.parse.urlparse(self.path)
            path = parsed.path
            query = urllib.parse.parse_qs(parsed.query)

            if path == "/health":
                self._json(200, {"ok": True, "ollama": client.ping(),
                                  "version": "2.0.0"})
                return
            if path == "/skills":
                self._json(200, {"skills": load_skills()})
                return
            if path == "/memory":
                self._json(200, {"memory": (WORKSPACE/"MEMORY.md").read_text(),
                                  "user": (WORKSPACE/"USER.md").read_text()})
                return
            if path == "/sessions":
                mode = query.get("mode", [None])[0]
                self._json(200, {"sessions": list_sessions(mode=mode)})
                return
            if path.startswith("/sessions/"):
                sid = path.split("/")[-1]
                f = SESSIONS_DIR / f"{sid}.json"
                if f.exists():
                    try:
                        self._json(200, json.loads(f.read_text()))
                    except Exception:
                        self._json(500, {"error": "invalid json"})
                else:
                    self._json(404, {"error": "not found"})
                return
            if path == "/config":
                self._json(200, cfg)
                return
            self._json(404, {"error": "not found"})

        def do_POST(self) -> None:  # noqa: N802
            length = int(self.headers.get("Content-Length", 0))
            raw = self.rfile.read(length) if length else b"{}"
            try:
                body = json.loads(raw)
            except Exception:
                body = {}

            if self.path == "/sessions_save":
                sid = body.get("id") or new_session_id("chat")
                model_used = body.get("model", cfg["default_model"])
                msgs = body.get("messages", [])
                save_session(sid, msgs, model_used)
                self._json(200, {"ok": True, "id": sid})
                return

            if self.path == "/agent":
                model = body.get("model", cfg["default_model"])
                user = body.get("message", "")
                sid = body.get("session_id") or new_session_id("agent")
                sess = load_session(sid)
                if sess:
                    messages = sess["messages"]
                else:
                    messages = [{"role": "system",
                                  "content": build_system_prompt(cfg)}]
                if cfg.get("memory_auto_extract", True):
                    fact = maybe_extract_memory(user)
                    if fact:
                        tool_remember(f"(auto) {fact}")
                messages.append({"role": "user", "content": user})
                tool_log: list[dict[str, Any]] = []

                def on_tool(name: str, args: dict[str, Any], result: str) -> None:
                    tool_log.append({"name": name, "args": args,
                                     "result": result[:1500]})

                try:
                    text = run_agent_turn(client, model, messages, cfg,
                                          on_tool=on_tool)
                except Exception as e:
                    self._json(500, {"error": str(e)})
                    return
                save_session(sid, messages, model)
                self._json(200, {
                    "session_id": sid,
                    "reply": text,
                    "tools": tool_log,
                    "turns": len(messages),
                })
                return

            if self.path == "/remember":
                self._json(200, {"result": tool_remember(body.get("fact", ""))})
                return
            if self.path == "/recall":
                self._json(200, {"result": tool_recall(body.get("query", ""))})
                return

            self._json(404, {"error": "not found"})

        def log_message(self, fmt, *args):  # quiet logs
            return

    port = args.port or 11500
    srv = ThreadingHTTPServer(("127.0.0.1", port), Handler)
    cprint(f"🦞 Claw agent API listening on http://127.0.0.1:{port}", C.CYN)
    cprint("   Open webui/index.html in your browser to use the new UI.", C.DIM)
    try:
        srv.serve_forever()
    except KeyboardInterrupt:
        cprint("\nbye!", C.MAG)
    return 0


def cmd_sessions(_args: argparse.Namespace) -> int:
    rows = list_sessions(50)
    if not rows:
        cprint("(no sessions yet)", C.DIM); return 0
    cprint(f"{'ID':40} {'MODEL':18} {'TURNS':>6}  SAVED", C.BOLD)
    for r in rows:
        cprint(f"{r['id']:40} {str(r['model'])[:18]:18} "
               f"{r['turns']:>6}  {r['saved_at']}", "")
    return 0


def cmd_skills(_args: argparse.Namespace) -> int:
    skills = load_skills()
    if not skills:
        cprint("(no skills installed)", C.DIM); return 0
    for s in skills:
        cprint(f"📦 {s['name']}", C.BOLD)
        cprint(f"   {s.get('summary','(no summary)')}", C.DIM)
    return 0


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Claw — Ollama USB Toolkit agent runtime")
    sub = parser.add_subparsers(dest="cmd")

    p_chat = sub.add_parser("chat", help="Interactive terminal chat")
    p_chat.add_argument("--model", help="Override default model")
    p_chat.add_argument("--session", help="Resume an existing session id")
    p_chat.add_argument("--no-tools", action="store_true",
                        help="Disable tool calling (plain chat)")
    p_chat.set_defaults(func=cmd_chat)

    p_serve = sub.add_parser("serve", help="Start the agent HTTP API for WebUI v2")
    p_serve.add_argument("--port", type=int, default=11500)
    p_serve.set_defaults(func=cmd_serve)

    p_doc = sub.add_parser("doctor", help="Validate & repair workspace")
    p_doc.set_defaults(func=cmd_doctor)

    p_ses = sub.add_parser("sessions", help="List saved sessions")
    p_ses.set_defaults(func=cmd_sessions)

    p_sk = sub.add_parser("skills", help="List installed skills")
    p_sk.set_defaults(func=cmd_skills)

    args = parser.parse_args(argv)
    if not getattr(args, "func", None):
        parser.print_help()
        return 0
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
