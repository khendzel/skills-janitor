---
name: jan-prune
description: "When the user wants to find broken, orphaned, or dead Claude Code skills. Also use when the user mentions 'broken skills,' 'dead skills,' 'orphaned skills,' 'broken links,' 'clean up broken,' or 'prune skills.' Finds broken symlinks, empty directories, and orphaned user-scope duplicates. For full inventory, see jan-audit. For fixing, see jan-fix."
metadata:
  version: 1.2.0
---

# Prune

Find skills that need attention: broken symlinks, empty directories, and orphaned skills.

## What It Finds

### Broken Symlinks
Skills that point to deleted sources. These are dead weight - the skill folder exists but the target is gone.

### Empty Directories
Skill folders with no SKILL.md file. Often leftover from incomplete installations or failed deletions.

### Orphaned Skills
User-scope skills that duplicate a plugin skill. The plugin version is canonical and should be used instead.

## How to Run

Run the scan script and filter for issues:

```bash
bash ~/.claude/skills/skills-janitor/scripts/scan.sh
```

Look for entries where `is_symlink: true` and `symlink_target` starts with "BROKEN:".

## After Finding Issues

- Broken symlinks: safe to remove (target is gone)
- Empty directories: safe to remove
- Orphaned skills: suggest removing the user-scope copy and keeping the plugin version
- **Always ask for confirmation before removing anything**

## Related Skills

- For full inventory: `/jan-audit`
- For auto-fixing: `/jan-fix`
- For lint checks: `/jan-lint`
