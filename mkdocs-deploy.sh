#!/bin/bash
# Build and deploy the mkdocs site to the remote server via rsync.
#
# Usage:
#   ./mkdocs-deploy.sh           # build + deploy
#   ./mkdocs-deploy.sh --build   # build only, no deploy
#   ./mkdocs-deploy.sh --deploy  # deploy existing site/, skip build
#
# Required env vars (in root .env):
#   DOCS_SSH_HOST         remote hostname
#   DOCS_SSH_USER         remote SSH user
#   DOCS_SSH_PRIVATE_KEY  path to local private key
#   DOCS_SSH_PATH         remote base path (site deploys to $DOCS_SSH_PATH/site)
#
# Optional env vars:
#   DOCS_SSH_PORT         SSH port (default: 22)
#   MKDOCS_REMOTE_PATH    override remote docs path entirely

set -e

# ── Paths ────────────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"
SITE_DIR="$PROJECT_ROOT/site"

# ── Colors ───────────────────────────────────────────────────────────────────

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# ── Load env ─────────────────────────────────────────────────────────────────

ENV_FILE="$PROJECT_ROOT/.env"

if [ ! -f "$ENV_FILE" ]; then
    echo -e "${RED}Error: .env not found at $ENV_FILE${NC}"
    exit 1
fi

_env_tmp=$(mktemp)
grep -E '^[A-Za-z_][A-Za-z0-9_]*=' "$ENV_FILE" > "$_env_tmp"
set -a
source "$_env_tmp"
set +a
rm -f "$_env_tmp"

# ── Validate required vars ───────────────────────────────────────────────────

MISSING=()
[ -z "$DOCS_SSH_HOST" ]        && MISSING+=("DOCS_SSH_HOST")
[ -z "$DOCS_SSH_USER" ]        && MISSING+=("DOCS_SSH_USER")
[ -z "$DOCS_SSH_PRIVATE_KEY" ] && MISSING+=("DOCS_SSH_PRIVATE_KEY")
[ -z "$DOCS_SSH_PATH" ]        && MISSING+=("DOCS_SSH_PATH")

if [ ${#MISSING[@]} -gt 0 ]; then
    echo -e "${RED}Error: missing required env vars: ${MISSING[*]}${NC}"
    exit 1
fi

if [ ! -f "$DOCS_SSH_PRIVATE_KEY" ]; then
    echo -e "${RED}Error: SSH key not found at $DOCS_SSH_PRIVATE_KEY${NC}"
    exit 1
fi

REMOTE_PATH="${MKDOCS_REMOTE_PATH:-${DOCS_SSH_PATH}/site}"
SSH_PORT="${DOCS_SSH_PORT:-22}"

# ── Parse arguments ──────────────────────────────────────────────────────────

DO_BUILD=true
DO_DEPLOY=true

case "${1:-}" in
    --build)  DO_DEPLOY=false ;;
    --deploy) DO_BUILD=false  ;;
    "")       ;;
    *)
        echo -e "${RED}Unknown argument: $1${NC}"
        echo "Usage: $0 [--build|--deploy]"
        exit 1
        ;;
esac

# ── Header ───────────────────────────────────────────────────────────────────

echo -e "${GREEN}=== MkDocs Deploy ===${NC}"
echo -e "  Source : ${YELLOW}$SITE_DIR${NC}"
echo -e "  Remote : ${YELLOW}${DOCS_SSH_USER}@${DOCS_SSH_HOST}:${REMOTE_PATH}${NC}"
echo -e "  Mode   : ${YELLOW}$([ "$DO_BUILD" = true ] && echo "build + " || echo "")$([ "$DO_DEPLOY" = true ] && echo "deploy" || echo "build only")${NC}"
echo ""

# ── Build ────────────────────────────────────────────────────────────────────

if [ "$DO_BUILD" = true ]; then
    echo -e "${YELLOW}Installing mkdocs dependencies...${NC}"
    pip3 install --quiet --break-system-packages pymdown-extensions

    echo -e "${YELLOW}Building mkdocs site...${NC}"
    cd "$PROJECT_ROOT"

    echo -e "${YELLOW}Fixing markdown formatting...${NC}"
    python3 "$HOME/.claude/scripts/fix-markdown.py"

    mkdocs build --clean

    if [ ! -d "$SITE_DIR" ]; then
        echo -e "${RED}Error: build succeeded but site/ directory not found${NC}"
        exit 1
    fi

    echo -e "${GREEN}✓ Build complete → $SITE_DIR${NC}"
    echo ""
fi

# ── Deploy ───────────────────────────────────────────────────────────────────

if [ "$DO_DEPLOY" = true ]; then
    if [ ! -d "$SITE_DIR" ]; then
        echo -e "${RED}Error: site/ directory not found — run without --deploy to build first${NC}"
        exit 1
    fi

    echo -e "${YELLOW}Deploying to ${DOCS_SSH_HOST}...${NC}"

    SSH_CMD="ssh -i $DOCS_SSH_PRIVATE_KEY -p $SSH_PORT -o StrictHostKeyChecking=no"

    RSYNC=$(command -v /usr/local/bin/rsync || command -v /opt/homebrew/bin/rsync || command -v rsync)

    "$RSYNC" -avz --delete \
        --exclude='.DS_Store' \
        -e "$SSH_CMD" \
        "$SITE_DIR/" \
        "${DOCS_SSH_USER}@${DOCS_SSH_HOST}:${REMOTE_PATH}/"

    echo -e "${GREEN}✓ Deployed to ${DOCS_SSH_USER}@${DOCS_SSH_HOST}:${REMOTE_PATH}${NC}"
fi

echo ""
echo -e "${GREEN}=== Done ===${NC}"
