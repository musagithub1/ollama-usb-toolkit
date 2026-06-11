---
name: code-helper
summary: "Read project files and propose patches before writing them."
enabled: true
version: 0.1.0
---

# code-helper skill

When the user asks for help with code:

1. If they reference a file, call `read_file` first — never invent file contents.
2. Show a diff-like proposal in your reply (before/after).
3. Only call `write_file` after the user says yes (or if the user explicitly
   asked you to "just edit it").
4. Use fenced code blocks with the correct language tag.
5. After writing, suggest a quick test command (e.g. `run_shell("python3 -m py_compile path/to/file.py")`).
