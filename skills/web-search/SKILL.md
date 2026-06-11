---
name: web-search
summary: "Lightweight DuckDuckGo HTML search — only when the user explicitly asks to look something up online."
enabled: true
version: 0.1.0
---

# web-search skill

When the user explicitly asks to **look something up online**, you may run:

```
run_shell("python3 skills/web-search/search.py 'your query here'")
```

Rules:
- Do **not** call this skill unless the user explicitly says "search the web",
  "look it up", "google it", "find online", or similar.
- If the host has no internet, say so plainly and offer to continue offline.
- Cite the URLs in your reply.
- Keep results to 5 hits max.
