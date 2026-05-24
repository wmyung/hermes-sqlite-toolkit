#!/usr/bin/env bash
set -euo pipefail

# Install script for Hermes SQLite Toolkit
# Usage: curl -sL https://raw.githubusercontent.com/wmyung/hermes-sqlite-toolkit/main/install.sh | bash

REPO="https://raw.githubusercontent.com/wmyung/hermes-sqlite-toolkit/main"
HERMES="${HOME}/.hermes"
BINDIR="${HERMES}/bin"
TOOLSDIR="${HERMES}/tools"

mkdir -p "${BINDIR}" "${TOOLSDIR}"

echo "📦 Installing sqlite-suitectl..."
curl -sL "${REPO}/sqlite-suitectl" -o "${BINDIR}/sqlite-suitectl"
chmod +x "${BINDIR}/sqlite-suitectl"
echo "   → ${BINDIR}/sqlite-suitectl"

echo "📦 Installing sqlite_query Hermes tool..."
curl -sL "${REPO}/tools/sqlite_tool.py" -o "${TOOLSDIR}/sqlite_tool.py"
echo "   → ${TOOLSDIR}/sqlite_tool.py"

echo "📦 Initializing agent.db..."
python3 "${BINDIR}/sqlite-suitectl" init

echo ""
echo "✅ Hermes SQLite Toolkit installed!"
echo ""
echo "   Next session, agents will have 'sqlite_query' tool available."
echo "   Try:  sqlite-suitectl status"
echo ""

# Add to PATH hint
if [[ ":$PATH:" != *":${BINDIR}:"* ]]; then
    echo "💡 Add to your shell profile:"
    echo "   export PATH=\"\${HOME}/.hermes/bin:\${PATH}\""
fi
