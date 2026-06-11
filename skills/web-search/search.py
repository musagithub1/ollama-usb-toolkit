#!/usr/bin/env python3
"""Tiny DuckDuckGo HTML search. Stdlib only. Used by the web-search skill."""
import html
import re
import sys
import urllib.parse
import urllib.request


def search(query: str, n: int = 5) -> list[dict]:
    url = "https://duckduckgo.com/html/?q=" + urllib.parse.quote(query)
    req = urllib.request.Request(
        url, headers={"User-Agent": "ClawAgent/2.0 (USB)"}
    )
    try:
        with urllib.request.urlopen(req, timeout=8) as r:
            body = r.read().decode("utf-8", errors="replace")
    except Exception as e:
        return [{"error": f"network unavailable: {e}"}]

    pat = re.compile(
        r'<a [^>]*class="result__a"[^>]*href="([^"]+)"[^>]*>(.*?)</a>'
        r'.*?<a [^>]*class="result__snippet"[^>]*>(.*?)</a>',
        re.DOTALL,
    )
    out: list[dict] = []
    for m in pat.finditer(body):
        href = html.unescape(m.group(1))
        title = re.sub(r"<[^>]+>", "", m.group(2))
        snippet = re.sub(r"<[^>]+>", "", m.group(3))
        out.append({
            "title": html.unescape(title).strip(),
            "url": href,
            "snippet": html.unescape(snippet).strip(),
        })
        if len(out) >= n:
            break
    return out


if __name__ == "__main__":
    q = " ".join(sys.argv[1:]) or "ollama"
    for i, hit in enumerate(search(q), 1):
        if "error" in hit:
            print(hit["error"]); break
        print(f"{i}. {hit['title']}\n   {hit['url']}\n   {hit['snippet']}\n")
