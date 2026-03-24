# Skills Janitor

> Audit, track usage, and compare your Claude Code skills - 9 focused skills, zero dependencies.

![Skills Janitor demo](demo.gif)

A plugin for [Claude Code](https://claude.ai/claude-code) that keeps your skills ecosystem clean, organized, and healthy. Each action is its own skill with dedicated autocomplete.

## Skills

| Command | What it does |
|---------|-------------|
| `/janitor-audit` | Show all your installed skills |
| `/janitor-dupes` | Find duplicate skills that do the same thing |
| `/janitor-lint` | Check skills for errors and missing info |
| `/janitor-fix` | Automatically fix skill problems (safe preview first) |
| `/janitor-prune` | Find and remove broken skills |
| `/janitor-report` | Full health check of all your skills in one report |
| `/janitor-usage` | Show which skills you use and which you never use |
| `/janitor-search` | Search GitHub for new skills to install |
| `/janitor-compare` | Compare your skill with similar ones on GitHub |

## Install

![Install demo](install.gif)

**Plugin install (recommended):**
```
/plugin marketplace add khendzel/skills-janitor
/plugin install skills-janitor
```

**Or clone directly:**
```bash
git clone https://github.com/khendzel/skills-janitor ~/.claude/skills/skills-janitor
```

## Usage examples

Each skill has its own slash command with autocomplete:

```
/janitor-audit          → full skill inventory
/janitor-usage          → which skills you actually invoke
/janitor-search         → find skills on GitHub
/janitor-compare        → market analysis vs alternatives
/janitor-lint           → best practices check
/janitor-fix            → auto-fix (dry-run by default)
```

Or use natural language - skills trigger from keywords in their descriptions:
```
"audit my skills"
"which skills do I use?"
"search for n8n skills"
"compare my-skill against alternatives"
```

## Usage tracking

Parses your conversation history to show which skills you invoke and which are dead weight:

```
=== Skills Janitor - Usage Report ===
Period: 2026-02-24 to 2026-03-23 (4 weeks)

Active skills: 4 / 36 (11%)
Unused skills: 32 (89%)
Most used: n8n-workflows (17 total)
Recommendation: Remove 32 unused skills
```

## Skill discovery

Search GitHub for Claude Code skills by keyword:

```
=== Skills Janitor - Skill Discovery ===
Search: "marketing"

  #  Repository                    Stars  Status
  1  coreyhaines31/marketingskills  1,234  INSTALLED
  2  acme/marketing-automation        456  AVAILABLE
```

Set `GITHUB_TOKEN` env var for better results and higher rate limits.

## What it won't do

- Never deletes anything without explicit confirmation
- Never modifies plugin/marketplace skills
- Respects that some overlap is intentional
- Dry-run by default for all destructive operations

## Requirements

- Bash, Python 3, `curl`
- No pip installs, no node modules

## Structure

```
skills-janitor/
├── .claude-plugin/
│   └── marketplace.json      # Plugin manifest (9 skills)
├── skills/
│   ├── janitor-audit/SKILL.md
│   ├── janitor-dupes/SKILL.md
│   ├── janitor-lint/SKILL.md
│   ├── janitor-fix/SKILL.md
│   ├── janitor-prune/SKILL.md
│   ├── janitor-report/SKILL.md
│   ├── janitor-usage/SKILL.md
│   ├── janitor-search/SKILL.md
│   └── janitor-compare/SKILL.md
├── scripts/                  # Shared bash+python scripts
├── demo.gif
├── LICENSE                   # MIT
└── README.md
```

## Contributing

PRs welcome. Each skill is self-contained in `skills/janitor-*/SKILL.md`.

## License

MIT
