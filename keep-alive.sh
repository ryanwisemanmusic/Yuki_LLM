#!/bin/bash
# keep-alive.sh
# Keeps the Phi model loaded in Ollama indefinitely.

OLLAMA_API="http://localhost:11434"
MODEL_NAME="phi"

echo "Waiting for Ollama API at $OLLAMA_API..."
until curl -sS --fail "$OLLAMA_API/"; do
    sleep 1
done

echo "Ollama API is up. Loading $MODEL_NAME model and keeping it alive indefinitely..."

while true; do
    # Send keep-alive request to Ollama
    curl -sS -X POST "$OLLAMA_API/api/generate" \
         -H "Content-Type: application/json" \
         -d "{\"model\":\"$MODEL_NAME\",\"prompt\":\"\",\"keep_alive\":\"-1\"}" \
         || echo "Warning: failed to send keep-alive request"
    
    # Sleep a bit before sending the next request to prevent flooding
    sleep 5
done