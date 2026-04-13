#!/usr/bin/env bash
# claude-code-saver installer — one-command setup for other engineers.
#
# Usage:
#   curl -fsSL <url>/install.sh | bash
#   OR
#   bash install.sh
#
# Idempotent: safe to re-run.
set -euo pipefail

INSTALL_DIR="$HOME/.claude/claude-code-saver"
# Set this to the GitHub owner hosting the repo (user or org).
# Override with CCS_URL for forks/dev — e.g. CCS_URL=https://raw.githubusercontent.com/myorg/claude-code-saver/main/claude-code-saver
REPO_OWNER="${CCS_OWNER:-OWNER}"
SCRIPT_URL="${CCS_URL:-https://raw.githubusercontent.com/${REPO_OWNER}/claude-code-saver/main/claude-code-saver}"
SCRIPT_SRC="${CCS_SRC:-}"   # path to local source (if installing from cloned repo)

red() { printf '\033[31m%s\033[0m' "$*"; }
green() { printf '\033[32m%s\033[0m' "$*"; }
yellow() { printf '\033[33m%s\033[0m' "$*"; }
bold() { printf '\033[1m%s\033[0m' "$*"; }

step() { printf "\n%s %s\n" "$(bold "→")" "$(bold "$1")"; }
ok() { printf "  %s %s\n" "$(green "✓")" "$1"; }
fail() { printf "  %s %s\n" "$(red "✗")" "$1"; }
warn() { printf "  %s %s\n" "$(yellow "⚠")" "$1"; }

# ─── Preflight ────────────────────────────────────────────────────────────

printf "\n%s\n" "$(bold "  claude-code-saver installer")"
printf "  %s\n\n" "────────────────────────────────────────"

# macOS only (uses Keychain)
if [[ "$(uname)" != "Darwin" ]]; then
    fail "This tool only works on macOS (uses Keychain)."
    exit 1
fi
ok "Platform: macOS"

# Python 3
if ! command -v python3 >/dev/null 2>&1; then
    fail "python3 not found. Install it first (brew install python)."
    exit 1
fi
PY_VERSION=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
ok "Python $PY_VERSION"

# Claude CLI (warn but don't block)
if command -v claude >/dev/null 2>&1; then
    ok "Claude CLI: $(command -v claude)"
else
    warn "Claude CLI not found. You'll need to install it: https://claude.com/claude-code"
fi

# ─── Install script ───────────────────────────────────────────────────────

step "Installing claude-code-saver to $INSTALL_DIR"
mkdir -p "$INSTALL_DIR"

if [[ -n "$SCRIPT_SRC" ]] && [[ -f "$SCRIPT_SRC" ]]; then
    # Local install from a source path (dev mode)
    cp "$SCRIPT_SRC" "$INSTALL_DIR/claude-code-saver"
    ok "Copied from $SCRIPT_SRC"
elif [[ -n "$SCRIPT_URL" ]]; then
    # Remote download
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$SCRIPT_URL" -o "$INSTALL_DIR/claude-code-saver"
    elif command -v wget >/dev/null 2>&1; then
        wget -q "$SCRIPT_URL" -O "$INSTALL_DIR/claude-code-saver"
    else
        fail "Neither curl nor wget available."
        exit 1
    fi
    ok "Downloaded from $SCRIPT_URL"
else
    # Assume install.sh is run next to claude-code-saver (local dev)
    SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [[ -f "$SELF_DIR/claude-code-saver" ]]; then
        cp "$SELF_DIR/claude-code-saver" "$INSTALL_DIR/claude-code-saver"
        ok "Copied from $SELF_DIR/claude-code-saver"
    else
        fail "No source found. Set CCS_URL or CCS_SRC, or run from the directory containing claude-code-saver."
        exit 1
    fi
fi

chmod +x "$INSTALL_DIR/claude-code-saver"
ok "Made executable"

# ─── Launch the wizard ────────────────────────────────────────────────────

step "Launching setup wizard"
printf "\n"
exec "$INSTALL_DIR/claude-code-saver" init
