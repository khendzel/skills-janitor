# Skills Janitor

> Audit, track usage, and manage your AI coding skills — 4 focused commands, zero dependencies.

Works with **Claude Code** and **OpenAI Codex**.

![Skills Janitor](demo.gif)

A plugin that keeps your skills ecosystem clean, organized, and healthy. Scans every place skills live — user, project, codex, and (as of v1.3) plugin-namespaced skills from `/plugin install`.

## What's New in v1.3

**Plugin skills are now visible.** Janitor finally sees every skill installed via `/plugin install` — marketplace, cache (active version only), and source-loaded. On a typical machine with `marketing-skills`, `figma`, `vercel`, `interface-design`, `impeccable` and similar plugins installed, the scanned skill count more than doubles. The duplicate detector also surfaces cross-scope collisions like `marketing-seo-audit` (user) ↔ `marketing-skills:seo-audit` (plugin) — the situation that was completely invisible in v1.2.

**Commands consolidated 7 → 4.** Fewer entry points, same coverage:

| Now (v1.3) | Replaces |
|---|---|
| `/janitor-report` (`--brief` for inventory) | `/janitor-audit` + `/janitor-report` |
| `/janitor-value` | `/janitor-usage` + `/janitor-tokens` |
| `/janitor-discover` | `/janitor-search` + `/janitor-precheck` |
| `/janitor-fix` | unchanged |

The four removed commands keep working as deprecated aliases for one release; they'll be removed in v1.4.

### What's still in v1.2 / v1.1

- Cross-platform (Claude Code + OpenAI Codex)
- Symlink-shadow dedup
- Name-collision detection in `/janitor-report`
- `installed_plugins.json` v2 schema parsing
- `--prune` flag on `/janitor-fix` for broken symlinks and empty dirs

## Skills

| Command | What it does |
|---------|-------------|
| `/janitor-report` | Full health check: inventory + lint + duplicates + broken skills. `--brief` for inventory only. |
| `/janitor-fix` | Auto-fix issues + `--prune` to remove broken skills |
| `/janitor-value` | Combined token cost + usage — "is each skill earning its context budget?" |
| `/janitor-discover` | Search GitHub for new skills, or check a URL/path before installing |

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
/janitor-report                        -> full health check (lint + duplicates + broken)
/janitor-report --brief                -> inventory only
/janitor-value                         -> tokens + usage, sorted by waste
/janitor-discover seo                  -> search GitHub for SEO skills
/janitor-discover --compare my-skill   -> market analysis vs alternatives
/janitor-discover user/skill           -> check before installing
/janitor-fix                           -> auto-fix (dry-run by default)
/janitor-fix --prune                   -> find and remove broken skills
```

Or use natural language:
```
"check my skills"
"which skills are wasting context?"
"find me a skill for n8n workflows"
"check this skill before I install it"
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

## Duplicate detection (new in v1.2)

`/janitor-report` now flags two distinct kinds of duplicates separately:

```
=== Skills Janitor - Duplicate Detection ===

Total skill records: 73
Unique skill files (after symlink dedup): 60

--- Name Collisions ---
Found 2 skill name(s) at multiple distinct paths:

  baseline-ui
    [user] ~/.claude-account-personal/skills/baseline-ui
    [user] ~/.agents/skills/baseline-ui

  fixing-accessibility
    [user] ~/.claude-account-personal/skills/fixing-accessibility
    [user] ~/.agents/skills/fixing-accessibility

--- Description Overlap (Jaccard > 30%) ---
Found 3 potential overlap(s):

  [50%] janitor-audit <-> janitor-usage
       Scopes: user / user
       Shared keywords: show, skills

  [33%] n8n-code-javascript <-> n8n-code-python
       Scopes: user / user
       Shared keywords: code, input, json, node, nodes, syntax
```

**Name collisions** are exact-name conflicts at different real paths — the situation that makes Claude pick the wrong skill ambiguously. **Description overlaps** are semantic-similarity warnings for skills with overlapping triggers but different names.

Symlink shadows (the same physical SKILL.md reachable from both `~/.claude/skills/` and `~/.agents/skills/`) are deduped via `realpath` and no longer counted as duplicates.

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
│   └── marketplace.json
├── skills/
│   ├── janitor-report/SKILL.md       # full health check
│   ├── janitor-fix/SKILL.md          # auto-fix
│   ├── janitor-value/SKILL.md        # tokens + usage
│   ├── janitor-discover/SKILL.md     # search + precheck
│   └── (deprecated aliases for one release: audit, usage, tokens, search, precheck)
├── scripts/                          # bash+python, no other deps
├── demo.gif
├── LICENSE                           # MIT
└── README.md
```

## Migrating

| Old command | New equivalent |
|-------------|---------------|
| `/janitor-check` (v1.0) | `/janitor-report` |
| `/janitor-duplicates` (v1.0) | `/janitor-report` |
| `/janitor-cleanup` (v1.0) | `/janitor-fix --prune` |
| `/janitor-compare` (v1.0) | `/janitor-discover --compare <name>` |
| `/janitor-audit` (v1.2) | `/janitor-report --brief` |
| `/janitor-usage` (v1.2) | `/janitor-value` |
| `/janitor-tokens` (v1.2) | `/janitor-value` |
| `/janitor-search` (v1.2) | `/janitor-discover` |
| `/janitor-precheck` (v1.2) | `/janitor-discover <url>` |

All v1.2 commands keep working as deprecated aliases until v1.4.

## Contributing

PRs welcome. Each skill is self-contained in `skills/janitor-*/SKILL.md`.

## License

MIT
