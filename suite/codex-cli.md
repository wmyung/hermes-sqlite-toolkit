# Codex CLI Memory Enhancer — Quick Reference

**Repo:** [github.com/wmyung/codex-cli-memory-enhancer](https://github.com/wmyung/codex-cli-memory-enhancer)  
**Install:** `git clone https://github.com/wmyung/codex-cli-memory-enhancer.git && cd codex-cli-memory-enhancer && bash install.sh`  
**Deps:** Zero

### CLI commands
- `python3 memory.py save <text> [-p PROJECT] [-k KEY] [-i 1-5] [--ttl 7d]` — store
- `python3 memory.py search <query> [--semantic]` — FTS5 + optional vector
- `python3 memory.py list [-c category] [-t tag]` — browse
- `python3 memory.py stats` — memory counts
- `python3 memory.py context` — condensed context for Codex injection

### DB
Per-project SQLite files under `~/.codex/skills/local-memory/`.

### Usage pattern
```bash
# Codex CLI session — agent stores + retrieves
python3 memory.py save "deploy config: port 8080, --memory-limit 4GB" -p my-app
python3 memory.py context -p my-app  → condensed for system prompt
```
