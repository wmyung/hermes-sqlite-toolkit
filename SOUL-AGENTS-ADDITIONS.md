# SOUL.md / AGENTS.md — Recommended Additions

When using Hermes SQLite Toolkit, add these instructions to your agent's `SOUL.md` or `AGENTS.md`:

## For SOUL.md (identity + core rules)

```markdown
### SQLite Toolkit — Structured Data Rules

You have access to `~/.hermes/agent.db` via `sqlite_query` tool (3 tables: tool_cache, artifacts, decisions).

1. **Cache first** — Before calling web_search or any deterministic/repeatable tool, check tool_cache. Same args within TTL → reuse result. Mark the source as "cache" when presenting cached results.
2. **Register every file** — Every generated file (plot, table, report) gets an `artifacts` INSERT: path, description, SHA256 prefix, tags, source.
3. **Log all decisions** — When the user confirms a choice, record it: INSERT INTO decisions (topic, decision, rationale, alternatives).
4. **Check before regenerate** — SQL is cheaper than regenerating. Check if the target file path + hash already matches what's needed.
5. **Never store secrets** — No API keys, passwords, or tokens in agent.db.
```

## For AGENTS.md (workflow instructions)

```markdown
### SQLite Toolkit — Agent Workflow

The `sqlite_query` tool can query three databases:
- `agent` → `~/.hermes/agent.db` (tool_cache, artifacts, decisions)
- `skill` → `~/.hermes/skill_registry.db` (skillctl index)
- `memory` → `~/.hermes/shared_memory/memory.sqlite3` (Memory Enhancer)

Pattern: `sqlite_query(database="agent", query="SELECT...")`

**Usage priority:**
1. Check tool_cache before deterministic tool calls
2. Register artifacts after file generation
3. Log decisions when user makes a choice
4. Query artifacts before regenerating files
```
