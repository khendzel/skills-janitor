---
name: jan-audit
description: "When the user wants a full inventory of their Claude Code skills across all scopes. Also use when the user mentions 'skill audit,' 'how many skills,' 'list my skills,' 'skill inventory,' 'what skills do I have,' or 'scan my skills.' Scans user, project, and plugin scopes. For duplicates, see jan-dupes. For best practices check, see jan-lint. For usage tracking, see jan-usage."
metadata:
  version: 1.2.0
---

# Skill Audit

Run a full inventory scan of all Claude Code skills across every scope.

## How to Run

```bash
bash ~/.claude/skills/skills-janitor/scripts/scan.sh
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

- For duplicate detection: `/jan-dupes`
- For best practices check: `/jan-lint`
- For auto-fixing issues: `/jan-fix`
- For a full health report: `/jan-report`
