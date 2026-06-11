---
name: file-manager
summary: "Safe read/list/write inside the USB workspace folder."
enabled: true
version: 0.1.0
---

# file-manager skill

Use the built-in tools `read_file`, `write_file`, and `list_dir` to manage
files on the USB.

Safety contract:
- `write_file` is hard-restricted to `workspace/`. Do not try to write outside.
- For other locations, ask the user first and use `run_shell` with their consent.
- Always show the user what you wrote (path + size + first lines).
