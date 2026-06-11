---
name: calculator
summary: "Safe arithmetic / unit math — never compute hard math in your head."
enabled: true
version: 0.1.0
---

# calculator skill

Whenever the user asks for a non-trivial calculation, you must compute it
deterministically rather than guess. Use:

```
run_shell("python3 skills/calculator/calc.py '1+2*sin(0.5)'")
```

Supports: `+ - * / ** % //`, parentheses, and `math.*` functions.
Reject anything else (no `import`, no names, no attribute access on objects
other than the `math` module).
