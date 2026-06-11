#!/usr/bin/env python3
"""
Ollama API Examples - Python
Demonstrates how to use the Ollama REST API from Python.
No external libraries needed (uses built-in urllib).
"""

import json
import urllib.request
import urllib.error

OLLAMA_URL = "http://localhost:11434"


def list_models():
    """List all available models."""
    print("\n--- List Models ---")
    try:
        req = urllib.request.urlopen(f"{OLLAMA_URL}/api/tags")
        data = json.loads(req.read())
        for m in data.get("models", []):
            size_gb = m["size"] / 1e9
            print(f"  {m['name']:30s} {size_gb:.1f} GB")
    except urllib.error.URLError:
        print("  Error: Cannot connect to Ollama. Is the server running?")


def generate_text(model, prompt):
    """Generate text (non-streaming)."""
    print(f"\n--- Generate ({model}) ---")
    print(f"  Prompt: {prompt}")
    print(f"  Response: ", end="", flush=True)

    payload = json.dumps({
        "model": model,
        "prompt": prompt,
        "stream": False
    }).encode()

    req = urllib.request.Request(
        f"{OLLAMA_URL}/api/generate",
        data=payload,
        headers={"Content-Type": "application/json"}
    )
    try:
        res = urllib.request.urlopen(req)
        data = json.loads(res.read())
        print(data.get("response", ""))
    except urllib.error.URLError as e:
        print(f"\n  Error: {e}")


def chat(model, messages):
    """Chat with a model (non-streaming)."""
    print(f"\n--- Chat ({model}) ---")

    payload = json.dumps({
        "model": model,
        "messages": messages,
        "stream": False
    }).encode()

    req = urllib.request.Request(
        f"{OLLAMA_URL}/api/chat",
        data=payload,
        headers={"Content-Type": "application/json"}
    )
    try:
        res = urllib.request.urlopen(req)
        data = json.loads(res.read())
        reply = data.get("message", {}).get("content", "")
        print(f"  Assistant: {reply}")
        return reply
    except urllib.error.URLError as e:
        print(f"  Error: {e}")
        return ""


def generate_streaming(model, prompt):
    """Generate text with streaming output."""
    print(f"\n--- Streaming Generate ({model}) ---")
    print(f"  Prompt: {prompt}")
    print(f"  Response: ", end="", flush=True)

    payload = json.dumps({
        "model": model,
        "prompt": prompt,
        "stream": True
    }).encode()

    req = urllib.request.Request(
        f"{OLLAMA_URL}/api/generate",
        data=payload,
        headers={"Content-Type": "application/json"}
    )
    try:
        res = urllib.request.urlopen(req)
        for line in res:
            data = json.loads(line)
            token = data.get("response", "")
            print(token, end="", flush=True)
        print()
    except urllib.error.URLError as e:
        print(f"\n  Error: {e}")


def interactive_chat(model):
    """Interactive chat loop."""
    print(f"\n--- Interactive Chat with {model} ---")
    print("  Type 'quit' to exit.\n")

    messages = []
    while True:
        user_input = input("  You: ").strip()
        if user_input.lower() in ("quit", "exit", "q"):
            break

        messages.append({"role": "user", "content": user_input})

        payload = json.dumps({
            "model": model,
            "messages": messages,
            "stream": True
        }).encode()

        req = urllib.request.Request(
            f"{OLLAMA_URL}/api/chat",
            data=payload,
            headers={"Content-Type": "application/json"}
        )

        print("  AI: ", end="", flush=True)
        full_response = ""
        try:
            res = urllib.request.urlopen(req)
            for line in res:
                data = json.loads(line)
                token = data.get("message", {}).get("content", "")
                print(token, end="", flush=True)
                full_response += token
            print("\n")
        except urllib.error.URLError as e:
            print(f"\n  Error: {e}\n")
            continue

        messages.append({"role": "assistant", "content": full_response})


if __name__ == "__main__":
    print("=" * 50)
    print("  Ollama API - Python Examples")
    print("=" * 50)

    # 1. List models
    list_models()

    # 2. Simple generation
    generate_text("tinyllama", "What is Python in one sentence?")

    # 3. Streaming generation
    generate_streaming("tinyllama", "Write a haiku about coding.")

    # 4. Chat with context
    chat("tinyllama", [
        {"role": "system", "content": "You are a helpful coding assistant."},
        {"role": "user", "content": "What is a for loop?"}
    ])

    # 5. Interactive chat (uncomment to use)
    # interactive_chat("tinyllama")

    print("\nDone! See the code for more examples.")
