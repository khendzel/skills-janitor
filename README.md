# Skills Janitor

> Audit, track usage, and manage your AI coding skills - 7 focused skills, zero dependencies.

Works with **Claude Code** and **OpenAI Codex**.

![Skills Janitor](demo.gif)

A plugin that keeps your skills ecosystem clean, organized, and healthy. Automatically detects and scans skills from both Claude Code (`~/.claude/skills/`) and OpenAI Codex (`~/.agents/skills/`).

## What's New in v1.1

- **Cross-platform** - works with both Claude Code and OpenAI Codex
- **Pre-install overlap check** - check if a new skill duplicates existing ones before installing
- **Context window token cost** - see how many tokens each skill consumes and find unused waste
- **Consolidated from 9 to 7 commands** - fewer commands, same coverage

## Skills

| Command | What it does |
|---------|-------------|
| `/janitor-audit` | Full inventory of all installed skills |
| `/janitor-report` | Health check: lint, duplicates, broken skills, recommendations |
| `/janitor-fix` | Auto-fix issues + `--prune` to remove broken skills |
| `/janitor-usage` | Track which skills you use and which you never use |
| `/janitor-tokens` | Show context window token cost per skill |
| `/janitor-search` | Search GitHub for skills + `--compare` for market analysis |
| `/janitor-precheck` | Check overlap before installing a new skill |

## Install

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
/janitor-audit          -> full skill inventory
/janitor-report         -> health check (lint + duplicates + broken)
/janitor-usage          -> which skills you actually invoke
/janitor-tokens         -> context window cost per skill
/janitor-search         -> find skills on GitHub
/janitor-search --compare my-skill  -> market analysis vs alternatives
/janitor-precheck https://github.com/user/skill  -> check before installing
/janitor-fix            -> auto-fix (dry-run by default)
/janitor-fix --prune    -> find and remove broken skills
```

Or use natural language:
```
"audit my skills"
"which skills do I use?"
"how many tokens do my skills cost?"
"check this skill before installing"
"search for n8n skills"
```

## Usage tracking

Parses your conversation history to show which skills you invoke and which you never use:

```
=== Skills Janitor - Usage Report ===
Period: 2026-02-24 to 2026-03-23 (4 weeks)

Active skills: 4 / 36 (11%)
Unused skills: 32 (89%)
Most used: n8n-workflows (17 total)
Recommendation: Remove 32 unused skills
```

## Token cost analysis

Shows how many context window tokens each skill consumes:

```
=== Skills Janitor - Context Window Cost ===
Budget: 200,000 tokens

  Skill                               Tokens  Budget  Used?
  marketing-copywriting                2,340   1.2%    yes
  marketing-seo-audit                  1,560   0.8%     NO
  ...

  Total token cost: 18,720 (9.4% of budget)
  Unused skill cost: 14,300 (7.2% of budget wasted)
```

## Pre-install check

Check if a new skill overlaps with existing ones before installing:

```
=== Skills Janitor - Pre-Install Check ===

  Checking: marketing-seo-v2
  Scanned 35 installed skills

  --- HIGH OVERLAP (likely duplicates) ---
    [72%] marketing-seo-audit (user)
         Shared: seo, audit, ranking, meta

  VERDICT: High overlap detected - likely duplicate
```

## What it won't do

- Never deletes anything without explicit confirmation
- Never modifies plugin/marketplace skills
- Respects that some overlap is intentional
- Dry-run by default for all destructive operations

## Supported Platforms

| Platform | User skills | Project skills | Usage tracking |
|----------|-------------|----------------|----------------|
| Claude Code | `~/.claude/skills/` | `./.claude/skills/` | Full (history.jsonl) |
| OpenAI Codex | `~/.agents/skills/` | `./.agents/skills/` | Keyword matching |

Skills Janitor auto-detects which platforms are installed and scans all of them.

## Requirements

- Bash, Python 3, `curl`
- No pip installs, no node modules

## Structure

```
skills-janitor/
├── .claude-plugin/
│   └── marketplace.json      # Plugin manifest (7 skills)
├── skills/
│   ├── janitor-audit/SKILL.md
│   ├── janitor-report/SKILL.md
│   ├── janitor-fix/SKILL.md
│   ├── janitor-usage/SKILL.md
│   ├── janitor-tokens/SKILL.md
│   ├── janitor-search/SKILL.md
│   └── janitor-precheck/SKILL.md
├── scripts/                  # Shared bash+python scripts
├── demo.gif
├── LICENSE                   # MIT
└── README.md
```

## Migrating from v1.0

If you used v1.0 (9 skills), here's what changed:

| Old command | New equivalent |
|-------------|---------------|
| `/janitor-check` | `/janitor-report` (includes lint checks) |
| `/janitor-duplicates` | `/janitor-report` (includes duplicate detection) |
| `/janitor-cleanup` | `/janitor-fix --prune` |
| `/janitor-compare` | `/janitor-search --compare <name>` |

## Contributing

PRs welcome. Each skill is self-contained in `skills/janitor-*/SKILL.md`.

## License

MIT
