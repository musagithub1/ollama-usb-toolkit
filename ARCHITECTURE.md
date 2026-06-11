# Ollama USB Toolkit — Architecture

The **Ollama USB Toolkit (v2.0.0 Claw Edition)** transforms a standard local LLM into a highly capable, autonomous agent. 

This document breaks down the technical architecture, data flow, and sandbox security mechanics that make the "Claw" agent function.

---

## The 3-Tier Architecture

### 1. The Engine: Ollama
- **Role:** LLM inference and generation.
- **Port:** `11434`
- **Details:** Ollama runs entirely offline. It accepts a prompt, evaluates it using the loaded model (e.g., `qwen2.5:0.5b`), and streams back the generated text. By default, the `OLLAMA_MODELS` path is hijacked during startup to point to the `models/` folder inside the USB drive, ensuring portability.

### 2. The Brain: Claw Agent API (`agent/claw_agent.py`)
- **Role:** Prompt construction, tool dispatch, and memory management.
- **Port:** `11500`
- **Details:** This Python script is the core of the v2.0.0 update. It acts as a middle-tier reverse proxy between the Web UI and Ollama. 
  - It intercepts incoming chat messages from the user.
  - It dynamically builds a massive "System Prompt" (combining `IDENTITY.md`, `TOOLS.md`, `SOUL.md`, and the user's `MEMORY.md`).
  - If Ollama decides to use a tool, it outputs a specialized JSON block. The Agent API intercepts this JSON, executes the corresponding local Python function, and feeds the output *back* to Ollama to summarize.

### 3. The Frontend: Web UI (`webui/claw.html`)
- **Role:** User interface and state visualization.
- **Port:** `8888`
- **Details:** A lightweight HTML/JS/CSS frontend served by Python's built-in `http.server`. It allows the user to easily switch between "Chat" mode (raw Ollama connection) and "Agent" mode (routed through the Agent API). It visualizes tool execution logs, handles session creation, and displays the long-term memory box.

---

## The Agentic Loop

When you are in **"Agent"** mode, the following loop occurs for every message:

1. **Input:** User sends a prompt (e.g., "What time is it?").
2. **Contextualization:** The Agent API prepends the System Prompt containing the tool schemas.
3. **Inference (Pass 1):** Ollama reads the context and realizes the user needs the time. Because of `TOOLS.md`, it outputs a tool call: `{"name": "current_time"}`.
4. **Execution:** The Agent API catches this JSON, pauses the generation, runs `time.time()` in Python, and formats the output.
5. **Inference (Pass 2):** The Agent API sends the tool output back to Ollama.
6. **Output:** Ollama reads the time, formats it into a human-readable sentence, and sends the final string to the Web UI.

*(Note: The maximum number of consecutive tool iterations is defined by `max_tool_iterations` in `config/agent.json` to prevent infinite loops).*

---

## The Security Sandbox

Because giving an AI access to run local shell commands (`run_shell`) is inherently dangerous, the Claw Agent implements a strict security sandbox.

- **Sandbox Mode:** Controlled by `config/agent.json`.
- **Allow List:** By default, the `shell_allow_list` restricts the AI to non-destructive read-only commands (e.g., `ls`, `cat`, `date`, `whoami`, `python`). 
- **Execution Blocking:** If the agent hallucinates or attempts to run a malicious command like `rm -rf /` or `curl`, the `claw_agent.py` script intercepts the string, checks it against the allow-list, and immediately returns a hard rejection back to the model without executing it.

## Skills

Skills (`skills/` directory) are modular capabilities that can be dropped into the project. Each skill consists of:
- `SKILL.md`: The markdown instructions injected into the system prompt.
- `skill.py` (optional): The supporting Python script executed by `run_shell` when the AI triggers the skill.
