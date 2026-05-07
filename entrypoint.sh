#!/bin/bash
set -e

# ============================================================
# Ollama background server
# ============================================================
echo "[INFO] Starting Ollama..."
ollama serve > /var/log/ollama.log 2>&1 &

echo "[INFO] Waiting for Ollama to be ready..."
until curl -s http://localhost:11434 > /dev/null 2>&1; do
    sleep 1
done
echo "[INFO] Ollama ready."

# ============================================================
# Welcome message
# ============================================================
cat << EOF

==================================================================
  OpenClaude container is ready
==================================================================

  Provider:  ${OPENAI_BASE_URL:-${ANTHROPIC_BASE_URL:-anthropic native}}
  Model:     ${OPENAI_MODEL:-${ANTHROPIC_MODEL:-default}}

  To start, run:
    \$ openclaude

  Useful slash commands inside openclaude:
    /help      - List all available commands
    /provider  - Add or switch provider (guided wizard)
    /model     - Change current model
    /cost      - Show token usage and cost
    /doctor    - Diagnose configuration

  Useful CLI commands:
    \$ openclaude --print "your task here"   # one-shot mode
    \$ openclaude --version                  # check version
    \$ ollama list                           # list pulled local models
    \$ ollama pull <model>                   # pull a local model

==================================================================

EOF

# ============================================================
# Keep container alive
# ============================================================
tail -f /dev/null