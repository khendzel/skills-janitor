# Changelog

## v1.3.0 (2026-05-22)

### Plugin skills are now visible

The single biggest correctness fix in this project's history. Through v1.2, Janitor could only see skills under `~/.claude/skills/` (and the Codex equivalent) — plugin-namespaced skills installed via `/plugin install` (e.g. `marketing-skills:image`, `figma:figma-use`, `vercel:nextjs`) were completely invisible to every command.

v1.3 walks the active install path of every entry in `~/.claude/plugins/installed_plugins.json` (and `~/.claude/sources/<source>/skills/` for source-loaded skills), dedups by realpath to avoid double-counting plugins installed at both user and project scope, and uses the active version only (not every cached version under `~/.claude/plugins/cache/`).

Real impact on a typical machine: scanned skill count jumped from 35 → 157, token cost reporting went from "9% of budget" to "123% of budget" (i.e. the user was over their context budget without knowing it).

Affects every command:
- **`scan.sh`** — emits `namespace` and `qualified_name` fields; plugin skills appear as `<plugin>:<skill>`.
- **`detect_dupes.sh`** — surfaces cross-scope user-vs-plugin overlaps (the situation where you installed the `marketing-skills` plugin AND have a redundant user-scope `marketing-seo-audit` copy).
- **`tokencost.sh`** — plugin skills now counted toward total context cost.
- **`usage.sh`** — matches `/marketing-skills:image` style invocations against namespaced skills.

### Commands consolidated 7 → 4

- **`/janitor-report`** (default = full check, `--brief` = inventory only) replaces both `/janitor-audit` and the v1.2 `/janitor-report`.
- **`/janitor-value`** replaces `/janitor-usage` + `/janitor-tokens` — combined view sorted by waste (heavy + unused first), which is the actually-useful question.
- **`/janitor-discover`** replaces `/janitor-search` + `/janitor-precheck` — dispatches by arg shape (keyword → search, URL/path → precheck).
- **`/janitor-fix`** unchanged.

The four removed commands keep working as deprecated aliases for one release; they print a one-line rename notice and delegate to the new equivalent. Aliases will be removed in v1.4.

### Also fixed
- **`scan.sh` no longer double-counts user skills as project skills when run from `$HOME`.** Realpath dedup matches the existing logic for Codex.
- **Plugin-scope label simplified to `"plugin"`** (was previously planned as `"plugin-marketplace"/"plugin-cache"`). Plugin install scope is a property of the plugin, not the skill.
- **`for_each_skill_dir` in `paths.sh` now iterates plugin and source dirs too**, with namespace passed as a 4th callback arg. All consumers (detect_dupes, tokencost, usage, precheck) pick up plugin coverage automatically.

### Migration

| v1.2 command | v1.3 equivalent |
|---|---|
| `/janitor-audit` | `/janitor-report --brief` |
| `/janitor-usage` | `/janitor-value` |
| `/janitor-tokens` | `/janitor-value` |
| `/janitor-search <kw>` | `/janitor-discover <kw>` |
| `/janitor-precheck <url>` | `/janitor-discover <url>` |

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
