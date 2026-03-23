# Skills Janitor

A maintenance skill for Claude Code that keeps your skills ecosystem clean, organized, and healthy.

## What it does

| Action | What it checks |
|--------|---------------|
| **Audit** | Full inventory of all skills across user/project scopes |
| **Deduplicate** | Finds skills with overlapping trigger keywords and descriptions |
| **Lint** | Checks skills against best practices (frontmatter, descriptions, gotchas) |
| **Prune** | Detects broken symlinks, empty directories, orphaned skills |
| **Fix** | Auto-fixes common issues (with confirmation) |
| **Report** | Generates a full health report with severity levels |
| **Usage** | Tracks which skills you actually use vs. dead weight |
| **Search** | Finds Claude Code skills on GitHub by keyword |
| **Compare** | Market analysis - compares a skill against alternatives |

## Install

Copy the `skills-janitor` folder to your Claude Code skills directory:

```bash
cp -r skills-janitor ~/.claude/skills/
```

Or clone the repo and symlink:

```bash
git clone https://github.com/YOUR_USERNAME/skills-janitor.git
ln -s $(pwd)/skills-janitor ~/.claude/skills/skills-janitor
```

## Usage

Just tell Claude what you need:

- "audit my skills"
- "find duplicate skills"
- "lint my skills"
- "clean up broken skills"
- "give me a skills health report"

Or use the slash command style:

- `/skills-janitor audit`
- `/skills-janitor dupes`
- `/skills-janitor lint`
- `/skills-janitor prune`
- `/skills-janitor report`
- `/skills-janitor usage`
- `/skills-janitor search marketing`
- `/skills-janitor compare my-skill`

## What it checks

### Lint rules

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

### Duplicate detection

Uses Jaccard similarity on extracted keywords from skill descriptions. Flags pairs with > 30% keyword overlap, which may indicate redundant or confusingly-similar skills.

### What it won't do

- Never deletes anything without explicit confirmation
- Never modifies plugin/marketplace skills (they'd get overwritten on update)
- Respects that some overlap is intentional (e.g., copywriting vs copy-editing)

## Structure

```
skills-janitor/
├── SKILL.md              # Main skill definition
├── README.md             # This file
├── scripts/
│   ├── scan.sh           # Full inventory scanner (outputs JSON)
│   ├── detect_dupes.sh   # Keyword overlap analysis
│   ├── lint.sh           # Best practices checker
│   ├── usage.sh          # Usage tracking (parses history)
│   ├── search.sh         # GitHub skill discovery
│   └── compare.sh        # Market comparison & scoring
└── data/                 # Created at runtime
    ├── last-audit.json   # Most recent scan
    ├── changelog.log     # All janitor actions
    └── baseline.json     # First-run snapshot
```

## Contributing

PRs welcome. The best improvements come from real-world skill hygiene issues you've encountered.

## License

MIT
