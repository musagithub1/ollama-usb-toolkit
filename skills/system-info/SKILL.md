---
name: system-info
summary: "Use the system_info / current_time tools when the user asks about their machine."
enabled: true
version: 0.1.0
---

# system-info skill

If the user asks about their host machine (OS, RAM, GPU, USB free space,
current time, hostname), call the `system_info` or `current_time` tools.

Do **not** make up specs — always call the tool and report what comes back.
