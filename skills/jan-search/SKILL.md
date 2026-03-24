---
name: jan-search
description: "When the user wants to find Claude Code skills on GitHub. Also use when the user mentions 'find skills,' 'search skills,' 'skill marketplace,' 'discover skills,' 'what skills exist,' or 'GitHub skills.' Searches repos by keyword, shows stars/forks, marks installed vs available. For comparing against alternatives, see jan-compare. For tracking what you use, see jan-usage."
metadata:
  version: 1.2.0
---

# Skill Discovery

Search GitHub for Claude Code skills by keyword.

## How to Run

```bash
bash ~/.claude/skills/skills-janitor/scripts/search.sh <keyword> [--limit N] [--json]
```

- `<keyword>` - required search term (e.g., "marketing", "deployment", "testing")
- `--limit N` - max results (default: 10)
- `--json` - raw JSON output

## How It Works

1. Searches GitHub repos matching `{keyword} claude skill` in name/description/README
2. Also searches by topic tag `claude-code`
3. Cross-references results against your installed skills and plugins
4. Marks each result as `INSTALLED` or `AVAILABLE`

## Example Output

```
=== Skills Janitor - Skill Discovery ===
Search: "marketing"

  #  Repository                    Stars  Updated     Status
  1  coreyhaines31/marketingskills  1,234  2026-03-15  INSTALLED
  2  acme/marketing-automation        456  2026-03-10  AVAILABLE
  3  user/claude-marketing-seo         89  2026-02-28  AVAILABLE

Total: 3 results (1 installed, 2 available)
```

## Rate Limits

- Unauthenticated: 60 requests/hour (repo search only)
- Set `GITHUB_TOKEN` env var for 5,000 requests/hour + code search
- Results are cached for 24 hours in `data/search-cache.json`

## Related Skills

- For comparing your skills against alternatives: `/jan-compare`
- For checking which skills you actually use: `/jan-usage`
- For full inventory of installed skills: `/jan-audit`
