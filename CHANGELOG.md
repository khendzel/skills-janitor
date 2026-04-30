# Changelog

## v2.0.0 (2026-04-30)

### Fixed (correctness)
- **`paths.sh` no longer kills scripts under `set -e`.** `[[ -d "$path" ]] && action` in `add_dir()` returned exit 1 when the condition was false and the `&&` was the function's last command. Every script that sources `paths.sh` failed silently on Claude Code-only installs where `~/.agents/skills/` (Codex) does not exist. Same pattern fixed in `fix.sh` (prune codex dirs) and `scan.sh` (skip-self guard).
- **`usage.sh` finds the history file.** Hardcoded `~/.claude-account-personal/history.jsonl` does not exist on current Claude Code installs. Now checks `~/.claude/history.jsonl` first with legacy fallback; warns gracefully when neither is found.
- **`precheck.sh` fetches SKILL.md for `/tree/` GitHub URLs.** The `/tree/branch/path` handler built the raw URL but never fetched it. Also adds `https://` prefix and `Skill.md` fallback.
- **`scan.sh` parses `metadata.version`.** Previously only matched top-level `version:`, missing the nested `metadata:\n  version:` layout used by all skills in this plugin.
- **Stale cross-references removed.** `janitor-audit` referenced `/janitor-duplicates` and `/janitor-check` (removed in v1.1.0). `janitor-usage` referenced `/janitor-compare` and `/janitor-cleanup` (also removed in v1.1.0).
- **Trap quoting hardened** in `tokencost.sh` and `precheck.sh` -- single-quoted trap bodies prevent word-splitting on paths with spaces.
- **Version bumped** for `janitor-usage`, `janitor-search`, and `janitor-precheck` (were stuck at 1.0.0/1.1.0).

### Added
- **`usage.sh` scans conversation files for dispatched Skill tool_use blocks.** `history.jsonl` only captured user-typed `/slash-commands` but missed programmatic invocations. Now walks `~/.claude/projects/` for `tool_use` blocks with `name=="Skill"`. Adds "Dispatched" column. Plugin skills auto-discovered with scope "plugin".
- **`tokencost.sh` scans plugin skills from installed plugin cache.** Reads `installed_plugins.json` to discover cache paths and measure all plugin SKILL.md token costs. Handles missing dirs, corrupt JSON, old formats.
- **`dashboard.sh` -- visual HTML dashboard with snapshot history.** Self-contained HTML template with cards (context window cost, skill activity, health score), charts (weekly invocations, snapshot history), full skill inventory table, plugin list, and quality issues. Each run appends a timestamped snapshot (max 20). Cross-platform open (macOS/Linux/Windows).
- **Portable `<scripts_dir>` paths in all SKILL.md files.** Replaced hardcoded `~/.claude/skills/skills-janitor/scripts/` with a portable reference that works across plugin cache, marketplace, Codex, and manual clone installs.
- **`janitor-precheck` asks for input.** SKILL.md now instructs Claude to prompt for a URL or path instead of running without arguments.
- **Improved descriptions** for `janitor-audit` and `janitor-usage` with trigger clauses ("Use when...").

### Resolved from v1.2.0 known limitations
- Plugin-namespaced skills are now scanned by `tokencost.sh` (token cost) and discovered by `usage.sh` (dispatched invocations).
- `usage.sh` natural-language matching supplemented with conversation file scanning -- real usage detection improved from 2 to 131 invocations in testing.
- `precheck.sh` URL handling fixed for `/tree/` repo layouts.

## v1.2.0 (2026-04-29)

### Fixed (correctness)
- **`fix.sh --apply` no longer corrupts modern skills.** The repair now recognizes nested `metadata.version` (the canonical layout used by `npx skills add`), not only top-level `version:`. Without this fix, `--apply` would have injected duplicate top-level `version:` lines into every skill that already had `metadata.version`. The repair itself now writes the canonical nested form (`metadata:\n  version: "1.0.0"`) via awk so the appended block doesn't collide with the closing `---` on BSD sed (macOS).
- **`scan.sh` emits valid JSON.** Self-skip of the top-level `skills-janitor` folder previously left a dangling comma (`}\n,\n,\n{`) that broke any JSON consumer. Comma emission moved inside `scan_skill` after the early-return check.
- **`scan.sh` parses `installed_plugins.json` v2 schema.** Claude Code v2 wraps plugins in `{"version": 2, "plugins": {key: [instances]}}`; the previous parser treated it as a flat array and silently produced `"plugins": []` on every modern install. Older flat-array shape kept as a fallback.
- **`detect_dupes.sh` no longer reports symlink shadows as 100% self-duplicates.** Skills resolved to the same `realpath` (e.g. `~/.claude/skills/foo` symlinking to `~/.agents/skills/foo`) are deduped before comparison, eliminating "[100%] foo <-> foo" entries with both scopes labeled `user`.
- **`tokencost.sh` no longer double-counts symlinked skills.** Same realpath dedup; total token cost drops to the actual physical file count.

### Added
- **`detect_dupes.sh` name-collision pass.** Two distinct skill folders with the same name living at different realpaths (the situation that confuses skill triggering) are now flagged in a dedicated section, regardless of description similarity. The previous Jaccard-only check missed exact-name collisions when descriptions diverged.

### Fixed (from prior unreleased)
- **Windows compatibility** - removed dead `/dev/stdin` open in `detect_dupes.sh` that caused `FileNotFoundError` on Windows (Git Bash/MSYS2). The code was a no-op (`pass` body) and the actual data is read via `$TMPFILE` env var.
- **lint: false-positive CRITICAL for support folders** - folders without `SKILL.md` (e.g. `_shared`, `_docs`, `_temp`, plugin subdirs) are now silently skipped instead of emitting a spurious CRITICAL.
- **lint: multiline description parsing** - description values using YAML block scalars (`|`, `>`) are now collected across all indented lines via `awk`, fixing false "description too short" warnings. Long-description threshold raised from 250 → 500 chars to match real-world multi-line descriptions.
- **lint: new check for `disable-model-invocation` skills** - skills that set `disable-model-invocation: true` with a very short description now emit a WARNING, since Claude may not trigger them correctly.

### Known limitations (deferred to v1.3.0)
- Plugin-namespaced skills under `~/.claude/plugins/marketplaces/`, `~/.claude/plugins/cache/`, and `~/.claude/sources/` are still not scanned. Affected skills are invisible to audit/dupes/tokens — tracked separately.
- `usage.sh` natural-language matching is too strict and reports most skills as "never used"; tuning needs design discussion.
- `precheck.sh` URL handling fails on nested-skill repo layouts (e.g. `anthropics/skills`); robust resolver is a separate change.

## v1.1.0 (2026-04-15)

### New
- **Cross-platform support** - works with both Claude Code and OpenAI Codex
- `/janitor-precheck` - check overlap before installing a new skill
- `/janitor-tokens` - show context window token cost per skill

### Changed
- `/janitor-report` now includes lint checks, duplicate detection, and broken skill findings (was separate check/duplicates/cleanup commands)
- `/janitor-fix` gains `--prune` flag for removing broken symlinks and empty dirs
- `/janitor-search` gains `--compare <name>` flag for market comparison

### Removed (merged)
- `/janitor-check` -> use `/janitor-report`
- `/janitor-cleanup` -> use `/janitor-fix --prune`
- `/janitor-duplicates` -> use `/janitor-report`
- `/janitor-compare` -> use `/janitor-search --compare <name>`

## v1.0.0 (2026-03-24)

Initial release with 9 skills: audit, duplicates, check, fix, cleanup, report, usage, search, compare.
