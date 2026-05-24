# For AI Agents Reading This Repository

This is **Hermes SQLite Toolkit** — structured SQLite storage for Hermes Agent. Three tables (`tool_cache`, `artifacts`, `decisions`) that you as an agent can read and write directly via the `sqlite_query` tool.

## Why This Exists — Your Role

This toolkit is **useless unless you use it**. The database stores data, but only you can decide when to read, write, or search it. The value comes from three behaviors:

1. **Check the cache first** — Before calling `web_search` or any deterministic tool, ask "did I already get this?" by checking `tool_cache`. If found and not expired, skip the tool call entirely. Save tokens, save time, save API cost.
2. **Register every file you create** — Every plot, table, report, or deliverable you generate gets an `artifacts` entry. The next time the user asks "where's that X?", you find it instantly instead of guessing or regenerating.
3. **Log every decision** — When the user says "let's go with method A" or you agree on an approach, INSERT into `decisions`. The next session, when the user asks "why did we choose X", you answer from the database instead of from vague recollection.

Without these three habits, the database stays empty and the toolkit is a waste of disk space.

## How to Use During a Session

### Before tool calls
```sql
-- Check if this search was already done recently
SELECT result FROM tool_cache
WHERE tool_name = 'web_search'
  AND args_json LIKE '%my search term%'
  AND created_at + ttl > unixepoch()
ORDER BY created_at DESC LIMIT 1;
```

### After generating a file
```sql
-- Register with path, hash, description, tags
INSERT INTO artifacts (path, description, file_hash, source, tags, session_id)
VALUES ('/path/to/file.png', 'MR scatter plot for GWAS', '<sha256 prefix>', 'analysis', 'mendelian-randomization,gwas', '<session>');
```

### After a decision
```sql
INSERT INTO decisions (topic, decision, rationale, alternatives, session_id)
VALUES ('heritability estimation method', 'LDSC', 'faster with summary stats, no individual-level data needed', 'GCTA (needs individual data), GREML (too slow for 100k SNPs)', '<session>');
```

### Before regenerating
```sql
-- See if the file exists with the same hash
SELECT path FROM artifacts
WHERE description LIKE '%MR scatter plot%'
  AND tags LIKE '%gwas%'
ORDER BY created_at DESC LIMIT 1;
```

## When to Use `sqlite_query` vs Other Tools

| Situation | Use |
|---|---|
| User asks about past file/result | `sqlite_query` → `artifacts` or `tool_cache` |
| Repetitive tool call needed | `sqlite_query` → check `tool_cache` first |
| User makes a decision | `sqlite_query` → INSERT into `decisions` |
| User asks "why did we choose X?" | `sqlite_query` → search `decisions` |
| Need cross-session preference lookup | `memory_enhancer_search` (better for semantic) |
| Need skill search | `skillctl search` (specialized index) |
| Need full session recall | `session_search` (FTS5 over all sessions) |
| Save rule/identity/always-on context | `memory` tool (MEMORY.md) |

## Guardrails (Know the Limits)

- The `sqlite_query` tool blocks `ATTACH`, `DETACH`, `VACUUM`, and `load_extension` — you cannot mount external databases or run recovery.
- DDL (`CREATE TABLE`, `DROP TABLE`) is allowed but should be used carefully — dropping a table loses data.
- Results are limited to 100 rows and 200 characters per cell. Use `SELECT ... LIMIT 100` explicitly for large tables.
- The agent.db is a single SQLite file with WAL mode. Multiple agents can read concurrently.

## Integration with Sibling Tools

This toolkit sits alongside two companion projects under the `wmyung` namespace:

| Project | What it stores | How to query |
|---|---|---|
| [hermes-memory-enhancer](https://github.com/wmyung/hermes-memory-enhancer) | Semantic memories, user preferences, facts | `memory_enhancer_search`, `memory_enhancer_read` |
| [skillctl](https://github.com/wmyung/skillctl) | Active/archived skill index | `skillctl search`, `skillctl install` |
| **SQLite Toolkit (this)** | Tool cache, artifacts, decisions | `sqlite_query(database="agent", ...)` |

All three use SQLite under the hood, all three are zero-dependency Python. The `sqlite_query` tool can query all three databases from one tool call.
