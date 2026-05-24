# Memory Enhancer — Quick Reference

**Repo:** [github.com/wmyung/hermes-memory-enhancer](https://github.com/wmyung/hermes-memory-enhancer)  
**Install:** `bash <(curl -sL https://raw.githubusercontent.com/wmyung/hermes-memory-enhancer/main/install.sh)`  
**Deps:** Zero (PyYAML only in install.sh)

### Tools provided
- `memory_enhancer_search` — semantic search (fast/deep/auto)
- `memory_enhancer_read` — read memory:// URIs at abstract/overview/full
- `memory_enhancer_browse` — filesystem-style list/tree/stat
- `memory_enhancer_remember` — store a durable fact
- `memory_enhancer_add_resource` — import files (opt-in)

### DB
`~/.hermes/shared_memory/memory.sqlite3` — shared across agents.

### Usage pattern
```python
# Session start: restore context
memory_enhancer_search("GWAS B003 progress")

# Save a finding
memory_enhancer_remember("LDSC h2 = 0.15 for B003", category="entity")
```
