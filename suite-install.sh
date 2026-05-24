#!/usr/bin/env bash
set -euo pipefail

# Hermes SQLite Suite — Meta Installer
# Installs all 4 tools: memory-enhancer + skillctl + sqlite-toolkit + codex-cli-memory-enhancer

echo "═══════════════════════════════════════════"
echo "  Hermes SQLite Suite — Meta Installer"
echo "  4 tools, zero dependencies, one run."
echo "═══════════════════════════════════════════"

echo ""
echo "Step 1/4: hermes-memory-enhancer..."
if [[ -d "${HOME}/.hermes/plugins/memory-enhancer" ]] || command -v memory_enhancer_search &>/dev/null; then
    echo "  ✅ Already installed"
else
    echo "  ⚠️  Memory Enhancer requires a separate server (see docs). Skipping auto-install."
    echo "     git clone https://github.com/wmyung/hermes-memory-enhancer.git"
fi

echo ""
echo "Step 2/4: skillctl..."
if [[ -x "${HOME}/.hermes/bin/skillctl" ]]; then
    echo "  ✅ Already installed"
else
    mkdir -p "${HOME}/.hermes/bin"
    curl -sL https://raw.githubusercontent.com/wmyung/skillctl/main/skillctl -o "${HOME}/.hermes/bin/skillctl"
    chmod +x "${HOME}/.hermes/bin/skillctl"
    python3 "${HOME}/.hermes/bin/skillctl" init
fi

echo ""
echo "Step 3/4: sqlite-toolkit..."
if [[ -x "${HOME}/.hermes/bin/sqlite-suitectl" ]]; then
    echo "  ✅ Already installed"
else
    mkdir -p "${HOME}/.hermes/bin" "${HOME}/.hermes/tools"
    curl -sL https://raw.githubusercontent.com/wmyung/hermes-sqlite-toolkit/main/sqlite-suitectl -o "${HOME}/.hermes/bin/sqlite-suitectl"
    chmod +x "${HOME}/.hermes/bin/sqlite-suitectl"
    python3 "${HOME}/.hermes/bin/sqlite-suitectl" init
    curl -sL https://raw.githubusercontent.com/wmyung/hermes-sqlite-toolkit/main/tools/sqlite_tool.py -o "${HOME}/.hermes/tools/sqlite_tool.py"
fi

echo ""
echo "Step 4/4: codex-cli-memory-enhancer..."
if [[ -d "${HOME}/codex-cli-memory-enhancer" ]]; then
    echo "  ✅ Already cloned"
else
    git clone https://github.com/wmyung/codex-cli-memory-enhancer.git "${HOME}/codex-cli-memory-enhancer" 2>/dev/null || echo "  ⚠️  git not available; install manually"
fi

echo ""
echo "═══════════════════════════════════════════"
echo "  ✅ Hermes SQLite Suite installed!"
echo ""
echo "  sqlite_query    →  Query all DBs from Hermes"
echo "  sqlite-suitectl →  CLI for agent.db"
echo "  skillctl        →  Skill context manager"
echo "  memory-*        →  Memory Enhancer tools"
echo "  codex-memory    →  Codex CLI memory"
echo ""
echo "  Next session: agents auto-discover sqlite_query."
echo "═══════════════════════════════════════════"
