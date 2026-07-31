#!/bin/bash
# Serve MkDocs docs locally with live-reload.
# Run from the project root.
#
# Usage:
#   ./mkdocs-serve.sh           # serves on port 8000
#   ./mkdocs-serve.sh 8001      # serves on a custom port

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PORT="${1:-8000}"

# Kill any existing mkdocs process on the target port.
EXISTING_PID=$(lsof -ti :"$PORT" 2>/dev/null)
if [ -n "$EXISTING_PID" ]; then
    echo "Killing existing process on port $PORT (PID $EXISTING_PID)..."
    kill "$EXISTING_PID"
    sleep 1
fi

cd "$SCRIPT_DIR"

# Ensure watchdog is installed into the same Python env that mkdocs uses.
# Required for live-reload on macOS — without it, MkDocs has no filesystem
# event listener and won't detect saved files.
#
# Read the shebang from the mkdocs binary to find its exact Python interpreter.
# Falling back to $(dirname $(which mkdocs))/python3 is unreliable because
# on Homebrew the mkdocs wrapper and its Python live in different directories.
MKDOCS_BIN="$(command -v mkdocs)"
MKDOCS_PYTHON=""
if [ -f "$MKDOCS_BIN" ]; then
    MKDOCS_PYTHON=$(head -1 "$MKDOCS_BIN" | sed 's/^#!//' | awk '{print $1}')
fi

if [ -x "$MKDOCS_PYTHON" ]; then
    "$MKDOCS_PYTHON" -m pip install --quiet watchdog 2>/dev/null || true
else
    # Fallback: try the active python3 in PATH
    python3 -m pip install --quiet watchdog 2>/dev/null || true
fi

# Fix markdown formatting once before starting the server.
echo "Fixing markdown formatting..."
python3 "$HOME/.claude/scripts/fix-markdown.py"

mkdocs serve --dev-addr="127.0.0.1:$PORT"
