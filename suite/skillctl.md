# skillctl — Quick Reference

**Repo:** [github.com/wmyung/skillctl](https://github.com/wmyung/skillctl)  
**Install:** `curl -sL https://raw.githubusercontent.com/wmyung/skillctl/main/skillctl -o ~/.hermes/bin/skillctl && chmod +x ~/.hermes/bin/skillctl && skillctl init`  
**Deps:** Zero

### CLI commands
- `skillctl init` — scan ~/.hermes/skills/ → build SQLite index
- `skillctl status` — active / archived counts
- `skillctl search <query>` — search by name, description, tags
- `skillctl install <name>` — archive → active (~0.1s)
- `skillctl remove <name>` — active → archive
- `skillctl list [--all]` — show active or all skills

### DB
`~/.hermes/skill_registry.db` — also queryable via `sqlite_query(database="skill", ...)`.

### Usage pattern
```text
# Agent detects context pressure
skillctl status  → "100 active, 50 archived"
skillctl search "gwas" → find archived postgwas skills
skillctl install postgwas-comprehensive-report-builder  → restore
```
