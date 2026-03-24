# Skills Janitor

> Audit, track usage, and compare your Claude Code skills - in one command.

A maintenance skill for [Claude Code](https://claude.ai/claude-code) that keeps your skills ecosystem clean, organized, and healthy. Think of it as a package manager meets analytics for your Claude Code skills.

## Why

If you use Claude Code daily, you probably have 20+ skills scattered across `~/.claude/skills/`, project `.claude/skills/`, and plugin scopes. Over time they accumulate - duplicates, half-finished ones, skills you installed and never used. You have no idea if better alternatives exist.

Skills Janitor fixes that.

## What it does

| Action | Command | Description |
|--------|---------|-------------|
| **Audit** | `/skills-janitor audit` | Full inventory across all scopes |
| **Deduplicate** | `/skills-janitor dupes` | Finds overlapping skills (Jaccard similarity) |
| **Lint** | `/skills-janitor lint` | Checks against best practices |
| **Fix** | `/skills-janitor fix` | Auto-fixes common issues (dry-run by default) |
| **Prune** | `/skills-janitor prune` | Finds broken symlinks, orphaned skills |
| **Report** | `/skills-janitor report` | Full health report with severity levels |
| **Usage** | `/skills-janitor usage` | Tracks which skills you actually use |
| **Search** | `/skills-janitor search <keyword>` | Finds skills on GitHub |
| **Compare** | `/skills-janitor compare <skill>` | Market analysis vs alternatives |

## Install

```bash
git clone https://github.com/khendzel/skills-janitor ~/.claude/skills/skills-janitor
```

Then use `/skills-janitor` in Claude Code. That's it.

## Usage examples

Just tell Claude what you need:

```
"audit my skills"
"find duplicate skills"
"which skills do I actually use?"
"search for n8n skills on GitHub"
"compare my-skill against alternatives"
"give me a skills health report"
```

Or use slash commands directly:

```
/skills-janitor audit
/skills-janitor usage --weeks 8
/skills-janitor search marketing
/skills-janitor compare skills-janitor
```

## Usage tracking

Parses your Claude Code conversation history to show which skills you invoke and which are dead weight:

```
=== Skills Janitor - Usage Report ===
Period: 2026-02-24 to 2026-03-23 (4 weeks)

--- Most Used ---
  Skill                    Explicit  Estimated  Total
  n8n-workflows                   2          0      2
  23studio-social-post            1          0      1

--- Never Used (32 skills) ---
  marketing-ab-test        (user)
  marketing-analytics      (user)
  ... and 30 more

=== Summary ===
  Active skills: 4 / 36 (11%)
  Unused skills: 32 (89%)
```

## Skill discovery

Search GitHub for Claude Code skills by keyword:

```
=== Skills Janitor - Skill Discovery ===
Search: "marketing"

  #  Repository                    Stars  Updated     Status
  1  coreyhaines31/marketingskills  1,234  2026-03-15  INSTALLED
  2  acme/marketing-automation        456  2026-03-10  AVAILABLE
  3  user/claude-marketing-seo         89  2026-02-28  AVAILABLE
```

Set `GITHUB_TOKEN` env var for better results and higher rate limits.

## Market comparison

Compare any skill against alternatives with composite scoring:

```
=== Skills Janitor - Market Analysis ===
Analyzing: skills-janitor

--- Alternatives Found ---
  #  Repository                Score  Stars  Overlap  Updated
  1  obra/superpowers           72.3  106k     45%    2026-03-22
  2  user/skill-manager         58.1  2.1k     62%    2026-03-18

--- Related Marketplace Plugins (install counts) ---
   169,670  code-review
    77,603  skill-creator
```

## Lint rules

- Missing or empty `name` / `description` fields
- Description too short (< 30 chars) or too long (> 200 chars)
- Description doesn't explain trigger conditions
- Folder name doesn't match skill `name` field
- Missing frontmatter delimiters
- No body content after frontmatter
- No Gotchas section
- Large skill files without progressive disclosure
- Broken symlinks
- Empty skill directories

## What it won't do

- Never deletes anything without explicit confirmation
- Never modifies plugin/marketplace skills (they'd get overwritten on update)
- Respects that some overlap is intentional
- Dry-run by default for all destructive operations

## Requirements

- Bash
- Python 3
- `curl` (for GitHub search/compare features)

No pip installs, no node modules - just what you already have.

## Structure

```
skills-janitor/
├── SKILL.md              # Main skill definition
├── README.md             # This file
├── LICENSE               # MIT
├── scripts/
│   ├── scan.sh           # Full inventory scanner (JSON output)
│   ├── detect_dupes.sh   # Keyword overlap analysis
│   ├── lint.sh           # Best practices checker
│   ├── fix.sh            # Auto-fix engine
│   ├── usage.sh          # Usage tracking (parses history)
│   ├── search.sh         # GitHub skill discovery
│   └── compare.sh        # Market comparison & scoring
└── data/                 # Created at runtime (gitignored)
    ├── usage-history.json
    ├── search-cache.json
    └── ...
```

## Contributing

PRs welcome. The best improvements come from real-world skill hygiene issues you've encountered.

## License

MIT
