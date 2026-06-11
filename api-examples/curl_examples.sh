#!/usr/bin/env bash
# ============================================================================
#  Ollama API Examples - curl
#  Demonstrates how to use the Ollama REST API from the command line.
# ============================================================================

OLLAMA_URL="http://localhost:11434"
MODEL="tinyllama"

echo "=================================================="
echo "  Ollama API - curl Examples"
echo "=================================================="

# --- 1. Check if server is running ---
echo ""
echo "--- 1. Health Check ---"
curl -s "$OLLAMA_URL" && echo " (Server is running)" || echo "Server not running!"

# --- 2. List models ---
echo ""
echo "--- 2. List Models ---"
curl -s "$OLLAMA_URL/api/tags" | python3 -m json.tool 2>/dev/null || curl -s "$OLLAMA_URL/api/tags"

# --- 3. Generate text (non-streaming) ---
echo ""
echo "--- 3. Generate Text ---"
curl -s "$OLLAMA_URL/api/generate" \
  -H "Content-Type: application/json" \
  -d "{
    \"model\": \"$MODEL\",
    \"prompt\": \"What is Linux in one sentence?\",
    \"stream\": false
  }" | python3 -c "import sys,json; print(json.load(sys.stdin).get('response',''))" 2>/dev/null

# --- 4. Chat (non-streaming) ---
echo ""
echo "--- 4. Chat ---"
curl -s "$OLLAMA_URL/api/chat" \
  -H "Content-Type: application/json" \
  -d "{
    \"model\": \"$MODEL\",
    \"messages\": [
      {\"role\": \"system\", \"content\": \"You are a helpful assistant.\"},
      {\"role\": \"user\", \"content\": \"Explain Docker in 2 sentences.\"}
    ],
    \"stream\": false
  }" | python3 -c "import sys,json; print(json.load(sys.stdin).get('message',{}).get('content',''))" 2>/dev/null

# --- 5. Generate with streaming ---
echo ""
echo "--- 5. Streaming Generate ---"
curl -s "$OLLAMA_URL/api/generate" \
  -H "Content-Type: application/json" \
  -d "{
    \"model\": \"$MODEL\",
    \"prompt\": \"Write a haiku about open source.\",
    \"stream\": true
  }" | while read -r line; do
    echo "$line" | python3 -c "import sys,json; print(json.load(sys.stdin).get('response',''),end='',flush=True)" 2>/dev/null
  done
echo ""

# --- 6. Model info ---
echo ""
echo "--- 6. Model Info ---"
curl -s "$OLLAMA_URL/api/show" \
  -H "Content-Type: application/json" \
  -d "{\"name\": \"$MODEL\"}" | python3 -m json.tool 2>/dev/null | head -20

echo ""
echo "Done! Edit MODEL variable at the top to change the model."
