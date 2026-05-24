#!/usr/bin/env bash
set -euo pipefail

# Meta-installer: Hermes SQLite Suite
# Installs all 3 tools: hermes-memory-enhancer + skillctl + sqlite-toolkit

echo "═══════════════════════════════════════════"
echo "  Hermes SQLite Suite — Meta Installer"
echo "═══════════════════════════════════════════"

echo ""
echo "Step 1/3: hermes-memory-enhancer..."
if [[ -d "${HOME}/.hermes/plugins/memory-enhancer" ]]; then
    echo "  ✅ Already installed"
else
    echo "  Installing..."
    bash <(curl -sL https://raw.githubusercontent.com/wmyung/hermes-memory-enhancer/main/install.sh)
fi

echo ""
echo "Step 2/3: skillctl..."
if [[ -x "${HOME}/.hermes/bin/skillctl" ]]; then
    echo "  ✅ Already installed"
else
    echo "  Installing..."
    curl -sL https://raw.githubusercontent.com/wmyung/skillctl/main/skillctl -o "${HOME}/.hermes/bin/skillctl"
    chmod +x "${HOME}/.hermes/bin/skillctl"
    echo "  Running init..."
    python3 "${HOME}/.hermes/bin/skillctl" init
fi

echo ""
echo "Step 3/3: sqlite-toolkit..."
if [[ -x "${HOME}/.hermes/bin/sqlite-suitectl" ]]; then
    echo "  ✅ Already installed"
else
    bash <(curl -sL https://raw.githubusercontent.com/wmyung/hermes-sqlite-toolkit/main/install.sh)
fi

echo ""
echo "═══════════════════════════════════════════"
echo "  ✅ All 3 tools installed!"
echo ""
echo "  sqlite_query  →  Query all 3 databases from Hermes"
echo "  sqlite-suitectl  →  CLI for agent.db"
echo "  skillctl      →  Skill context manager"
echo "  memory-*      →  Memory Enhancer tools"
echo "═══════════════════════════════════════════"
