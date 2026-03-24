---
name: skills-janitor
description: "Use when the user wants to audit, clean up, deduplicate, lint, or manage their Claude Code skills. Also use when the user mentions 'skill audit,' 'duplicate skills,' 'clean up skills,' 'skill health,' 'skill report,' 'unused skills,' 'broken skills,' 'skill inventory,' 'skill maintenance,' 'how many skills,' 'list my skills,' 'organize skills,' 'skill conflicts,' 'too many skills,' 'skill health check,' 'verify my skills,' 'check my skills,' 'review Claude Code setup,' 'spring cleaning skills,' 'skill hygiene,' 'skill usage,' 'how often,' 'find skills,' 'search skills,' 'skill alternatives,' 'compare skills,' 'skill marketplace,' 'better skill,' or 'skill market.' Provides comprehensive skill hygiene, usage tracking, discovery, and market comparison."
version: "1.2.0"
---

# Skills Janitor

A maintenance skill for keeping your Claude Code skills ecosystem clean, organized, and healthy.

## Capabilities

1. **Audit** - Full inventory of all skills across all scopes
2. **Deduplicate** - Find skills with overlapping functionality
3. **Lint** - Check skills against best practices
4. **Fix** - Auto-fix common skill issues
5. **Prune** - Find broken symlinks, orphaned skills, or unused skills
6. **Report** - Generate a health report
7. **Usage** - Track which skills you actually use (and which are dead weight)
8. **Search** - Find Claude Code skills on GitHub by keyword
9. **Compare** - Market analysis: compare a skill against alternatives

## How to Use

When invoked, ask the user what they want to do. If unclear, run a full audit first.

### Available Actions

| Action | Command | Description |
|--------|---------|-------------|
| Full Audit | `/skills-janitor audit` | Scan all scopes, generate inventory |
| Find Duplicates | `/skills-janitor dupes` | Find overlapping/redundant skills |
| Lint Skills | `/skills-janitor lint` | Check all skills against best practices |
| Fix Issues | `/skills-janitor fix` | Auto-fix common problems |
| Prune | `/skills-janitor prune` | Find broken links, orphans |
| Report | `/skills-janitor report` | Full health report with recommendations |
| Diff | `/skills-janitor diff` | Compare two skills side-by-side |
| Usage Report | `/skills-janitor usage` | Track skill invocation frequency |
| Search | `/skills-janitor search <keyword>` | Find skills on GitHub |
| Compare | `/skills-janitor compare <skill>` | Market analysis vs alternatives |

## Workflow

### Step 1: Discover Skills

Run the scan script to build a complete inventory:

```bash
bash ~/.claude/skills/skills-janitor/scripts/scan.sh
```

This outputs a JSON inventory of every skill found across:
- **User scope**: `~/.claude/skills/`
- **Project scope**: `./.claude/skills/` (current project)
- **Plugin skills**: `~/.claude/plugins/` and marketplace sources
- **Source links**: `~/.claude/sources/`

### Step 2: Analyze

Based on what the user asked for, run the appropriate analysis.

#### Duplicate Detection

Run the duplicate detection script:

```bash
bash ~/.claude/skills/skills-janitor/scripts/detect_dupes.sh
```

This compares skills by:
- **Name similarity** - skills with similar names (e.g., `marketing-copywriting` vs `marketing-copy-editing`)
- **Description overlap** - skills whose descriptions cover the same triggers
- **Keyword collision** - skills that trigger on the same keywords

After running the script, review the output and use your judgment to determine which are true duplicates vs complementary skills. Present findings as a table.

#### Lint Check

Run the lint script:

```bash
bash ~/.claude/skills/skills-janitor/scripts/lint.sh
```

#### Auto-Fix

Run the fix script (dry-run by default):

```bash
bash ~/.claude/skills/skills-janitor/scripts/fix.sh          # preview changes
bash ~/.claude/skills/skills-janitor/scripts/fix.sh --apply   # apply changes
```

Checks each skill for:
- Missing or empty `name` field
- Missing or empty `description` field
- Description too short (< 30 chars) or too long (> 200 chars)
- Missing `---` frontmatter delimiters
- No body content after frontmatter
- Description doesn't explain trigger conditions (missing "when" / "use when" / "also use when")
- Skill folder name doesn't match `name` field
- Empty skill directory (no SKILL.md)
- Broken symlinks

#### Prune Check

Find skills that need attention:
- **Broken symlinks** - point to deleted sources
- **Empty directories** - skill folders with no SKILL.md
- **Orphaned skills** - skills in user scope that duplicate a plugin skill (plugin should be canonical)

### Step 3: Report & Act

Present findings clearly with:
- A summary table of issues found
- Severity levels: `critical` (broken), `warning` (suboptimal), `info` (suggestion)
- Recommended actions for each issue
- Ask user confirmation before making ANY changes

### Step 4: Fix (with confirmation)

When fixing issues:
- **NEVER delete skills without explicit user confirmation**
- **NEVER modify skill content without showing the diff first**
- For duplicate resolution, suggest which to keep and why
- For lint fixes, show before/after of frontmatter changes
- Log all changes to `~/.claude/skills/skills-janitor/data/changelog.log`

## Example Output

A typical audit produces a summary like this:

```
=== Skills Janitor - Audit Summary ===

| Skill              | Scope   | Status      | Issues                          |
|--------------------|---------|-------------|---------------------------------|
| marketing-copy     | user    | OK          | -                               |
| seo-audit          | user    | WARNING     | Description too short (28 chars) |
| old-deploy-helper  | user    | CRITICAL    | Broken symlink                  |
| my-formatter       | project | WARNING     | No Gotchas section              |
| marketing-copy-v2  | user    | DUPLICATE?  | 72% overlap with marketing-copy |

Totals: 12 skills scanned, 1 critical, 2 warnings, 1 potential duplicate
```

## Common Questions

**How many skills is too many?**
There's no hard limit, but 30+ skills adds context overhead. Focus on quality over quantity - each skill should have a clear, distinct trigger.

**Should I delete duplicates from a plugin?**
No. Plugin skills are managed by the plugin author. If a plugin has internal overlap, uninstall the plugin or raise an issue upstream.

**Can I scan a specific project?**
Yes - run `cd /path/to/project && bash ~/.claude/skills/skills-janitor/scripts/scan.sh` to scan that project's `.claude/skills/` directory.

**What does fix.sh do exactly?**
It adds missing frontmatter delimiters (`---`), fills empty descriptions with a template, and adds missing version fields. It runs in `--dry-run` mode by default - you must pass `--apply` to write changes.

## Gotchas

- Symlinked skills are common and expected - don't flag them as issues unless the target is broken
- Marketing skills from the `marketingskills` plugin are supposed to be numerous - don't flag the quantity itself
- Skills from plugins/marketplaces should NOT be edited directly (changes get overwritten on update)
- The `description` field is for the MODEL, not the human - it should contain trigger keywords
- Some skills intentionally overlap (e.g., `marketing-copywriting` and `marketing-copy-editing` serve different purposes)
- When comparing descriptions for duplicates, look at the actual trigger words, not just topic similarity
- Project-scope skills (`.claude/skills/`) are separate from user-scope and should be analyzed in context of their project

## Best Practices Reference

When linting or fixing skills, apply these standards:

### Description Quality
- Should be 50-200 characters
- Must explain WHEN to trigger (not just WHAT it does)
- Should include trigger keywords the user might say
- Format: "Use when [condition]. Also use when [user says X, Y, Z]."

### Frontmatter Requirements
- `name` - required, human-friendly, matches folder name
- `description` - required, model-facing trigger description
- `version` - recommended for tracking changes

### Content Quality
- Should have clear workflow steps
- Should include a Gotchas section (built up over time)
- Should use progressive disclosure (reference files for details)
- Should not be overly prescriptive (let Claude adapt)

## Data Storage

Store all janitor data in a stable location:

```
~/.claude/skills/skills-janitor/data/
├── last-audit.json      # Most recent audit results
├── changelog.log        # All changes made by janitor
├── baseline.json        # First audit snapshot for comparison
├── usage-history.json   # Weekly skill usage tracking
└── search-cache.json    # Cached GitHub search results (24h TTL)
```

Create the data directory if it doesn't exist before writing.

## Usage Tracking

Run the usage script to see which skills you actually invoke:

```bash
bash ~/.claude/skills/skills-janitor/scripts/usage.sh [--weeks N] [--json]
```

Parses conversation history to detect both explicit slash commands and natural language invocations. Shows most used, never used, and weekly trends. Data persists across runs in `data/usage-history.json`.

## Skill Discovery

Search GitHub for Claude Code skills:

```bash
bash ~/.claude/skills/skills-janitor/scripts/search.sh <keyword> [--limit N] [--json]
```

Uses GitHub repository search (unauthenticated). Set `GITHUB_TOKEN` env var for better results and higher rate limits. Results are cached for 24 hours.

## Market Comparison

Compare a local skill against alternatives:

```bash
bash ~/.claude/skills/skills-janitor/scripts/compare.sh <skill-name> [--json]
```

Searches GitHub for similar skills, scores them by keyword overlap + popularity + recency, and shows marketplace install counts from `~/.claude/plugins/install-counts-cache.json`.
