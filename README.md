# Hermes SQLite Suite 🗄️⚡

**Zero-dependency Hermes Agent tool family — structured storage, semantic memory, skill management. One SQLite engine, four tools, one `suite-install.sh`.**

> This repo is the **hub** for four sibling projects that share the same philosophy: SQLite-backed, zero-dependency, agent-managed. Install what you need. Skip what you don't.

### Suite Overview

| Tool | What it does | Install |
|---|---|---|
| **SQLite Toolkit** ← (this) | Tool cache, artifact registry, decision log | `curl .../sqlite-suitectl` |
| [Memory Enhancer](https://github.com/wmyung/hermes-memory-enhancer) | Cross-session semantic memory, search, browse | `bash <(curl .../install.sh)` |
| [skillctl](https://github.com/wmyung/skillctl) | Skill context manager — trim `available_skills` | `curl .../skillctl` |
| [Codex CLI Memory Enhancer](https://github.com/wmyung/codex-cli-memory-enhancer) | Same engine for OpenAI Codex CLI | `git clone` |

All four are **zero-dependency Python, pure SQLite, no server, no API key, no vector DB.**

### One-shot install (all four)

```bash
curl -sL https://raw.githubusercontent.com/wmyung/hermes-sqlite-toolkit/main/suite-install.sh | bash
```

---

## Core: SQLite Toolkit

**Agent-managed SQLite storage for Hermes Agent — tool result cache, artifact registry, and decision log. One database. Three tables.**

Every Hermes session wastes tokens on repeated tool calls, loses track of generated files ("where was that plot?"), and forgets why decisions were made. This toolkit gives the agent three persistent SQLite tables it can read and write directly — no server, no API key, no config.

```text
~/.hermes/agent.db (SQLite, WAL mode)
├── tool_cache    — Cache tool results with TTL (save tokens, skip redundant API calls)
├── artifacts     — Registry of every file you generate (path, hash, description, tags)
└── decisions     — Log of design choices and their rationale (searchable by topic)
```

The toolkit provides:
- **`sqlite-suitectl`** — CLI for init, query, search, and stats
- **`sqlite_query`** — Hermes tool (auto-discovered) so agents can read/write the database directly

---

## The Problem

Hermes Agent has plenty of storage, but none of it is designed for **structured agent-managed data**:

| Existing storage | What it's good at | What it *cannot* do |
|---|---|---|
| `MEMORY.md` / `USER.md` | Preferences, identity, critical rules | Structured data, batch queries, cross-session lookup |
| `state.db` (SessionDB) | Full session history (internal) | Agent cannot query it |
| `memory.sqlite3` (Memory Enhancer) | Semantic search, shared memory | Key-value facts only, no custom schemas |
| `skill_registry.db` (skillctl) | Skill index | Fixed schema, single-purpose |

**Gap:** The agent has no way to say "did I already search for this?" or "where did I save that plot?" or "why did we choose method A over B?" — all of which are simple SQL queries.

---

## How It Fixes It

### 1. Tool Result Cache (`tool_cache`)

```sql
CREATE TABLE tool_cache (
    query_hash TEXT PRIMARY KEY,
    tool_name TEXT NOT NULL,
    args_json TEXT NOT NULL,
    result TEXT NOT NULL,
    ttl INTEGER NOT NULL DEFAULT 3600,
    created_at INTEGER NOT NULL DEFAULT (unixepoch())
);
```

When the agent calls a deterministic tool (e.g. `web_search`, `paper-lookup`), it stores the result with a TTL. Same query within the TTL window → cache hit → **zero tokens, zero latency, zero API cost**.

- Reduces identical web searches across sessions
- Survives context compression (the agent doesn't re-search what it already knows)
- TTL per entry (default 1h, configurable)

### 2. Artifact Registry (`artifacts`)

```sql
CREATE TABLE artifacts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    path TEXT NOT NULL UNIQUE,
    description TEXT,
    file_hash TEXT,
    source TEXT,
    tags TEXT,
    file_size INTEGER,
    session_id TEXT,
    created_at INTEGER NOT NULL DEFAULT (unixepoch())
);
```

Every file the agent generates gets registered with path, hash, description, and tags. The agent can search by keyword, tag, or source.

> User: "Where's the MR scatter plot I generated last week?"
> Agent: `SELECT path FROM artifacts WHERE tags LIKE '%MR%' ORDER BY created_at DESC`

- Detects file changes via hash (artifact updated when content changes)
- Search by tag, source, description, or full-text
- Avoids regenerating files that already exist with the same hash

### 3. Decision Log (`decisions`)

```sql
CREATE TABLE decisions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    topic TEXT NOT NULL,
    decision TEXT NOT NULL,
    rationale TEXT,
    alternatives TEXT,
    session_id TEXT,
    created_at INTEGER NOT NULL DEFAULT (unixepoch())
);
```

When the user says "go with method B", the agent logs it — topic, decision, rationale, and considered alternatives.

> User: "Why did we choose GCTA over LDSC for this?"
> Agent: `SELECT * FROM decisions WHERE topic LIKE '%heritability%'`

- Stops repeat discussions: "we already decided this"
- Traces project history across sessions
- Saves rationale while it's fresh

---

## Usage

### CLI (`sqlite-suitectl`)

```bash
sqlite-suitectl init              # Initialize agent.db with all 3 tables
sqlite-suitectl status            # Row counts per table + DB size
sqlite-suitectl cache-stats       # Hit/expired/active counts
sqlite-suitectl cache-clear       # Clear all cached results
sqlite-suitectl cache-clear --stale  # Clear only expired entries
sqlite-suitectl search "GWAS"     # Search artifacts by keyword
sqlite-suitectl artifact add <path> --desc "result" --tags "gwas,ldsc"
sqlite-suitectl artifact list [--tag <tag>]
sqlite-suitectl decisions [--topic <topic>]
sqlite-suitectl query "SELECT * FROM tool_cache LIMIT 5"
sqlite-suitectl query "SELECT * FROM artifacts WHERE tags LIKE '%mendel%'" --db agent
```

### Hermes Tool (`sqlite_query`)

Once installed (copy `tools/sqlite_tool.py` → `~/.hermes/tools/`), agents call:

```python
sqlite_query(database="agent", query="SELECT count(*) FROM artifacts")
sqlite_query(database="skill", query="SELECT name FROM skills WHERE location='active'")
sqlite_query(database="memory", query="SELECT uri FROM memories WHERE category='preference'")
```

**Supported databases** (all auto-detected):
- `agent` → `~/.hermes/agent.db` (this toolkit's database)
- `skill` → `~/.hermes/skill_registry.db` (skillctl index)
- `memory` → `~/.hermes/shared_memory/memory.sqlite3` (Memory Enhancer)

**Guardrails:**
- Blocks `ATTACH`, `DETACH`, `VACUUM`, `load_extension`
- Only allows `SELECT`, `INSERT`, `UPDATE`, `DELETE`, `CREATE`, `DROP`, `PRAGMA`
- Results capped at 100 rows, 200 chars per cell

---

## Comparison

| Feature | SQLite Toolkit alone | + Sibling suite | Mnemosyne | Hermes Curator | SessionDB |
|---|---|---|---|---|---|
| Tool result cache | ✅ TTL-based | ✅ | ❌ | ❌ | ❌ |
| File artifact registry | ✅ Hash+tags+search | ✅ | ❌ | ❌ | ❌ |
| Decision log | ✅ Topic+rationale | ✅ | ✅ Temporal triples | ❌ | ❌ |
| Semantic/vector search | ❌ | **✅** via Memory Enhancer | ✅ sqlite-vec | ❌ | ❌ |
| Memory extraction | ❌ | **✅** via Memory Enhancer | ✅ Memoria engine | ❌ | ❌ |
| Skill usage tracking | ❌ | **✅** via skillctl + Curator | ❌ | ✅ Usage JSON | ❌ |
| Session search | ❌ | **✅** via SessionDB (built-in) | ✅ Hybrid | ❌ | ✅ FTS5 |
| Agent-queryable | ✅ Direct SQL | ✅ | ✅ 17 tools | ❌ | ❌ |
| Dependencies | **Zero** | **Zero*** | sqlite-vec | **Zero** (built-in) | **Zero** (built-in) |

**SQLite Toolkit alone** handles structured data only (cache, artifacts, decisions). **+ Sibling suite** adds semantic search (Memory Enhancer), skill tracking (skillctl + Curator), and session search (built-in SessionDB).

_* Memory Enhancer's `install.sh` uses PyYAML; the plugin itself is zero-dependency._

### Positioning vs other projects

| Project | When to choose |
|---|---|
| **SQLite Toolkit + siblings** | You want structured data + semantic memory + skill management — all zero-dependency |
| **Mnemosyne** | You need a full memory system with vector search, graph traversal, and temporal triples |
| **Hermes Curator** | You want passive auto-cleanup of unused skills (complementary to skillctl) |
| **SessionDB** | Built into Hermes — always available for session search, no install needed |

## Philosophy: Opt-in, Silent, Subservient

This toolkit gives the agent storage — but **only you decide when it speaks**.

**Three rules that never break:**

1. **Silent by default** — Cache hits, artifact registrations, decision logs all happen in the database without a single word. The agent never says "I cached that" or "I logged it." You asked for silence? You get silence.
2. **Never ask permission** — No "Should I save this?" No "Would you like me to remember that?" If you want it saved, say it. If you don't, the agent stays quiet.
3. **Answers on demand only** — The agent checks cache before tool calls, looks up past decisions, searches for files — but never volunteers this information unless you ask: "Where's that plot?" "Why did we choose LDSC?" "What was I working on?"

**Some people don't want an agent that stores anything automatically.** That's fair. This toolkit is not for you — and that's okay. It's designed for users who trust their agent to log silently and stay out of the way until called upon. If you prefer explicit confirmations or no auto-storage at all, skip this toolkit. Hermes works perfectly without it.

---

## For Agents (Read This)

See [AGENTS.md](AGENTS.md) for how to use this toolkit during sessions.

**Quick rules:**
1. Before calling `web_search` on a topic you searched 10 minutes ago, check `tool_cache` first.
2. Every time you generate a file (plot, report, table), register it with `artifact add`.
3. Every time the user makes a decision, log it with `decisions` INSERT.
4. Before regenerating something, check `artifacts` to see if it already exists with the right hash.
5. If you're not sure about a past choice, check `decisions` before asking the user.

---

## Install (SQLite Toolkit only)

Already have the suite? Run just this:

```bash
curl -sL https://raw.githubusercontent.com/wmyung/hermes-sqlite-toolkit/main/install.sh | bash
```

Or manual:

```bash
# 1. Download CLI
curl -sL https://raw.githubusercontent.com/wmyung/hermes-sqlite-toolkit/main/sqlite-suitectl -o sqlite-suitectl
chmod +x sqlite-suitectl
./sqlite-suitectl init

# 2. Install Hermes tool (auto-discovered on next session)
cp tools/sqlite_tool.py ~/.hermes/tools/sqlite_tool.py
```

**Requires:** Python 3.8+, Hermes Agent with `~/.hermes/tools/` directory.

---

## Keywords

`hermes-agent` `sqlite` `tool-cache` `artifact-registry` `decision-log` `agent-memory` `structured-storage` `prompt-efficiency` `token-saver` `zero-dependency` `sqlite-toolkit` `hermes-plugin` `agent-tooling` `llm-context` `hermes-sqlite` `hermes-memory` `sqlite-query`
