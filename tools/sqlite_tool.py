"""
Hermes tool: sqlite_query — Persistent SQLite storage for agents.

Install: Copy this file to ~/.hermes/tools/sqlite_tool.py
Auto-discovered by Hermes on next session start.

Usage via Hermes agent:
  sqlite_query(database="agent", query="SELECT * FROM tool_cache LIMIT 5")
  sqlite_query(database="agent", query="INSERT INTO artifacts VALUES (...)")
  sqlite_query(database="skill", query="SELECT name FROM skills WHERE location='active'")
  sqlite_query(database="memory", query="SELECT uri, title FROM memories WHERE category='preference'")

Databases:
  - agent:   ~/.hermes/agent.db        (tool_cache, artifacts, decisions)
  - skill:   ~/.hermes/skill_registry.db (skillctl index)
  - memory:  ~/.hermes/shared_memory/memory.sqlite3 (Memory Enhancer)
"""

import sqlite3, json, time, hashlib
from pathlib import Path

HOME = Path.home()
HERMES = HOME / ".hermes"

DBS = {
    "agent": HERMES / "agent.db",
    "skill": HERMES / "skill_registry.db",
    "memory": HERMES / "shared_memory" / "memory.sqlite3",
}

# Guardrails: only allow these SQL operations
ALLOWED_DML = {"SELECT", "INSERT", "UPDATE", "DELETE", "CREATE", "DROP", "PRAGMA"}
BLOCKED_KEYWORDS = {"ATTACH", "DETACH", "load_extension", "VACUUM", "RECOVER"}


def check_sql_safe(sql: str) -> bool:
    """Basic safety check — blocks dangerous operations."""
    upper = sql.upper().strip()
    # Block dangerous commands
    for kw in BLOCKED_KEYWORDS:
        if kw in upper:
            return False
    # Must start with an allowed keyword
    first_word = upper.split()[0] if upper.split() else ""
    if first_word not in ALLOWED_DML:
        return False
    return True


def handler(args: dict, task_id: str = None) -> str:
    db_name = args.get("database", "agent")
    query = args.get("query", "")

    if db_name not in DBS:
        return json.dumps({"error": f"Unknown database: {db_name}. Choose: agent, skill, memory"})

    db_path = DBS[db_name]
    if not db_path.exists():
        return json.dumps({"error": f"Database not found: {db_path}. Run 'sqlite-suitectl init' first."})

    if not query.strip():
        return json.dumps({"error": "Empty query"})

    if not check_sql_safe(query):
        return json.dumps({"error": "Query blocked by safety guardrails"})

    try:
        conn = sqlite3.connect(str(db_path))
        conn.row_factory = sqlite3.Row
        cur = conn.execute(query)

        is_select = query.strip().upper().startswith("SELECT") or query.strip().upper().startswith("PRAGMA")

        if is_select:
            rows = cur.fetchall()
            cols = [desc[0] for desc in cur.description] if cur.description else []
            result = {
                "columns": cols,
                "rows": [[str(r[col])[:200] for col in cols] for r in rows[:100]],
                "count": len(rows),
                "truncated": len(rows) > 100,
            }
        else:
            conn.commit()
            result = {"affected": cur.rowcount, "status": "ok"}

        conn.close()
        return json.dumps(result)

    except Exception as e:
        return json.dumps({"error": str(e)})


# Registry schema
SCHEMA = {
    "name": "sqlite_query",
    "description": "Execute SQL queries against Hermes SQLite databases (agent.db, skill_registry.db, memory.sqlite3). Supports SELECT, INSERT, UPDATE, DELETE. Blocked: ATTACH, DETACH, VACUUM, load_extension.",
    "parameters": {
        "type": "object",
        "properties": {
            "database": {
                "type": "string",
                "enum": ["agent", "skill", "memory"],
                "description": "Target database. agent=agent.db (tool_cache, artifacts, decisions), skill=skill_registry.db, memory=memory.sqlite3",
                "default": "agent",
            },
            "query": {
                "type": "string",
                "description": "SQL query to execute. DDL is allowed. Safety guardrails block dangerous operations.",
            },
        },
        "required": ["query"],
    },
}


# Auto-registration for Hermes discovery
def register(registry):
    registry.register(
        name="sqlite_query",
        toolset="hermes_core",
        schema=SCHEMA,
        handler=handler,
    )
