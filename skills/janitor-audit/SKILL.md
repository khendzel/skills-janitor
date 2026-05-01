---
name: janitor-audit
description: "Show all your installed skills. Use when the user asks for a skill inventory, skill list, or wants to audit what's installed."
metadata:
  version: 2.0.0
---

# Skill Audit

Run a full inventory scan of all Claude Code skills across every scope.

The `<scripts_dir>` is the `scripts/` directory next to the `skills/` folder that contains this skill.

## How to Run

```bash
bash <scripts_dir>/scan.sh
```

## What It Scans

- **User scope**: `~/.claude/skills/`
- **Project scope**: `./.claude/skills/` (current project)
- **Plugin skills**: `~/.claude/plugins/` and marketplace sources
- **Source links**: `~/.claude/sources/`
- **Account-level**: `~/.claude-account-personal/plugins/`, `~/.claude-account-company/plugins/`

## Output

JSON inventory with per-skill details:
- Folder name, scope, full path
- Symlink status (valid/broken/target)
- Frontmatter fields (name, description, version)
- Body content presence
- Line counts, extra files

## After Scanning

Present findings as a summary table:

```
| Skill              | Scope   | Status   | Issues                    |
|--------------------|---------|----------|---------------------------|
| marketing-copy     | user    | OK       | -                         |
| seo-audit          | user    | WARNING  | Description too short     |
| old-deploy-helper  | user    | CRITICAL | Broken symlink            |
```

## Related Skills

- For duplicate detection: `/janitor-report`
- For auto-fixing issues: `/janitor-fix`
- For a full health report: `/janitor-report`
- For token cost: `/janitor-tokens`
