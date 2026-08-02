# Skills Janitor

> Tinder for your Claude Code skills. Swipe through your collection and delete what's wasting context, in seconds.

Works with **Claude Code** and **OpenAI Codex**. 6 commands, zero dependencies.

![/janitor-swipe — swipe keep / delete / skip through every installed skill](janitor-swipe-demo.gif)

> **New in v1.7: MCP servers join the triage.** Every configured MCP server is inventoried and cross-referenced against real usage from your session transcripts. Connected-but-never-called servers rank high in the swipe deck — their tool schemas load into context on every request for nothing. Swiping one left removes it from its config file, with a timestamped `.bak`. [Jump to MCP triage →](#mcp-server-triage-v17)

Scans every place a skill lives: user, project, codex, and every skill installed via `/plugin install` — plus your subagents and MCP servers. Surfaces duplicates, broken symlinks, unused skills, and connected-but-never-called MCP servers cluttering your context. Usage counts come from real session transcripts, including skills Claude auto-triggered.

## Commands

| Command | What it does |
|---|---|
| `/janitor-report` | Health check: inventory, duplicates, broken skills. `--brief` for inventory only. |
| `/janitor-fix` | Auto-fix issues. `--prune` removes broken symlinks and empty dirs. |
| `/janitor-value` | Honest token costs (always-loaded descriptions vs on-demand bodies) + usage, skills and subagents. |
| `/janitor-security` | Heuristic scan for prompt injection, hidden instructions, and dangerous script patterns. (v1.6+) |
| `/janitor-discover` | Search GitHub for skills, or check a URL before installing — now including a pre-install security scan. |
| `/janitor-swipe` | Interactive TUI — swipe keep/delete/skip through skills AND MCP servers, sorted most-likely-waste first. (v1.4+) |

Each has its own slash command. Or use natural language: *"check my skills"*, *"which skills are wasting context?"*, *"find an n8n skill"*.

## Install

```
/plugin marketplace add khendzel/skills-janitor
/plugin install skills-janitor
```

Or via [skills.sh](https://skills.sh):

```bash
npx skills add khendzel/skills-janitor
```

Or clone directly:

```bash
git clone https://github.com/khendzel/skills-janitor ~/.claude/skills/skills-janitor
```

## Security scan (v1.6)

A skill is text your agent trusts. Public research found prompt injection in roughly a third of tested community skills — so the janitor now scans for the known bad shapes: instruction-override phrases, "don't tell the user" directives, instructions hidden in HTML comments or zero-width unicode, smuggled base64 payloads, and scripts that pipe the network into a shell or read credential stores.

```
/janitor-security          # audit everything installed
/janitor-discover <url>    # overlap + security check BEFORE installing
```

Verdicts are honest heuristics (PASS / REVIEW / RISK): a RISK means "read this before trusting it", not "malware". Calibrated for low noise — on a real 178-skill machine it flags 2, both genuinely worth reading.

## Swipe through your skills (v1.4)

Tinder-style triage for your skill collection. The deck is sorted heaviest-and-least-used first, so most users hit `← delete` through the top 5–10 cards and quit before reviewing everything.

```
!bash ~/.claude/skills/skills-janitor/scripts/swipe.sh
```

(The `!` prefix runs in your terminal, not the Claude Code Bash tool — the TUI needs a real interactive stdin.)

Controls: `←` delete, `→` keep, `↓` skip, `u` undo, `i` inspect full description, `q` quit.

Plugin skills are flagged for review (you can't `rm` individual plugin skills — they belong to a plugin). User-scope skills stage for actual deletion, applied on `y` confirmation at the end.

Since v1.7 the deck also includes your MCP servers — see [MCP server triage](#mcp-server-triage-v17).

## MCP server triage (v1.7)

Skills aren't the only thing renting space in your context. Every connected MCP server loads
its tool schemas on every request, whether you call it or not.

The janitor inventories every configured server — user `~/.claude.json`, per-project entries,
project `.mcp.json`, and plugin-bundled — then cross-references real usage from your session
transcripts (`mcp__server__tool` records):

```
=== Skills Janitor - MCP Servers ===
Usage window: last 8 weeks of session transcripts

  Server                       Scope         Calls  Tools Last Used   Origin
  ──────────────────────────── ──────────── ────── ────── ─────────── ────────────
  design-tool                  mcp-user          0      0 never       ~/.claude.json
  deploy-tool                  mcp-plugin        0      0 never       plugin:deploy
  cms                          mcp-project      41      4 2026-07-02  ~/.claude.json

--- Unused in 8 weeks (2) ---
  design-tool (mcp-user) — configured in ~/.claude.json
  deploy-tool (mcp-plugin) — configured in plugin:deploy
```

No invented token numbers — MCP schemas live server-side, so the janitor reports only what it
can prove: where the server is configured, how many distinct tools you actually called, how
often, and when last. Servers seen in transcripts but no longer configured are listed
separately.

Unused servers rank high in the swipe deck. Swiping one left removes the entry from its config
file with a timestamped `.bak` backup. Plugin-bundled servers are flagged for plugin review
instead.

## Duplicate detection

The duplicate detector flags cross-scope overlaps, including plugins that re-implement a skill
you already had standalone:

```
=== Skills Janitor - Duplicate Detection ===

--- Description Overlap (Jaccard > 30%) ---

  [98%] marketing-seo-audit <-> marketing-skills:seo-audit
        Scopes: user / plugin

  [100%] marketing-content-strategy <-> marketing-skills:content-strategy
        Scopes: user / plugin
```

Overlap is scored on descriptions (Jaccard), so it catches re-implementations that share no
filename and live in different scopes.

## Upgrading from v1.2

The five v1.2 aliases were removed in v1.5. Renames:

| v1.2 | now |
|---|---|
| `/janitor-audit` | `/janitor-report --brief` |
| `/janitor-usage` | `/janitor-value` |
| `/janitor-tokens` | `/janitor-value` |
| `/janitor-search` | `/janitor-discover` |
| `/janitor-precheck` | `/janitor-discover <url>` |

Full release notes: [CHANGELOG.md](CHANGELOG.md).

## Requirements

Bash, Python 3, `curl`. No pip installs, no node modules.

## Contributing

PRs welcome. Each command is self-contained in `skills/janitor-*/SKILL.md` plus a sibling script in `scripts/`.

## License

MIT
