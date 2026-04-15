#!/bin/bash
# Skills Janitor - Context Window Token Cost
# Shows how many tokens each skill's system prompt consumes

set -euo pipefail

command -v python3 &>/dev/null || { echo "ERROR: python3 required" >&2; exit 1; }

# --- Defaults ---
JSON_OUTPUT=false
BUDGET=200000
WEEKS=4
DATA_DIR="$(cd "$(dirname "$0")/.." && pwd)/data"
USER_SKILLS="$HOME/.claude/skills"
PROJECT_SKILLS="./.claude/skills"

# --- Parse args ---
while [[ $# -gt 0 ]]; do
    case "$1" in
        --json) JSON_OUTPUT=true; shift ;;
        --budget) BUDGET="$2"; shift 2 ;;
        --weeks) WEEKS="$2"; shift 2 ;;
        -h|--help)
            echo "Usage: tokencost.sh [--budget N] [--weeks N] [--json]"
            echo ""
            echo "Show context window token cost per skill."
            echo "  --budget N   Context window size (default: 200000)"
            echo "  --weeks N    Usage lookback period (default: 4)"
            echo "  --json       Output as JSON"
            exit 0
            ;;
        -*) echo "Unknown option: $1" >&2; exit 1 ;;
        *) shift ;;
    esac
done

# --- Collect skill data ---
export TMPFILE=$(mktemp)
trap "rm -f $TMPFILE" EXIT

scan_skills() {
    local dir="$1"
    local scope="$2"
    [[ -d "$dir" ]] || return

    for skill_dir in "$dir"/*/; do
        [[ -d "$skill_dir" ]] || continue
        local name
        name=$(basename "$skill_dir")
        [[ "$name" == "skills-janitor" ]] && continue

        local skill_file=""
        [[ -f "$skill_dir/SKILL.md" ]] && skill_file="$skill_dir/SKILL.md"
        [[ -f "$skill_dir/Skill.md" ]] && skill_file="$skill_dir/Skill.md"
        [[ -z "$skill_file" ]] && continue
        [[ ! -e "$skill_file" ]] && continue

        local word_count
        word_count=$(wc -w < "$skill_file" | tr -d ' ')

        local desc
        desc=$(awk 'NR==1 && /^---$/{started=1; next} started && /^---$/{exit} started && /^description:/{sub(/^description:[[:space:]]*/,""); gsub(/"/,""); print}' "$skill_file")

        printf '%s\t%s\t%s\t%s\n' "$scope" "$name" "$word_count" "$desc" >> "$TMPFILE"
    done
}

scan_skills "$USER_SKILLS" "user"

USER_REAL=$(cd "$USER_SKILLS" 2>/dev/null && pwd -P || echo "")
PROJECT_REAL=$(cd "$PROJECT_SKILLS" 2>/dev/null && pwd -P || echo "")
if [[ -d "$PROJECT_SKILLS" && "$USER_REAL" != "$PROJECT_REAL" ]]; then
    scan_skills "$PROJECT_SKILLS" "project"
fi

# --- Export for Python ---
export JSON_OUTPUT BUDGET WEEKS DATA_DIR

python3 << 'PYEOF'
import json
import os
import sys

JSON_OUTPUT = os.environ.get("JSON_OUTPUT", "false") == "true"
BUDGET = int(os.environ.get("BUDGET", "200000"))
WEEKS = int(os.environ.get("WEEKS", "4"))
TMPFILE = os.environ.get("TMPFILE", "")
DATA_DIR = os.environ.get("DATA_DIR", "")

# Token approximation: ~1.3 tokens per word for English markdown
TOKEN_RATIO = 1.3

# --- Load skill data ---
skills = []
if TMPFILE and os.path.isfile(TMPFILE):
    with open(TMPFILE) as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            parts = line.split("\t", 3)
            if len(parts) < 4:
                continue
            scope, name, word_count, desc = parts
            tokens = int(round(int(word_count) * TOKEN_RATIO))
            skills.append({
                "name": name,
                "scope": scope,
                "words": int(word_count),
                "tokens": tokens,
                "description": desc[:80],
            })

# Sort by tokens descending
skills.sort(key=lambda x: -x["tokens"])

# --- Cross-reference with usage data ---
usage_data = {}
usage_file = os.path.join(DATA_DIR, "usage-history.json") if DATA_DIR else ""
if usage_file and os.path.isfile(usage_file):
    try:
        with open(usage_file) as f:
            ud = json.load(f)
            usage_data = ud.get("skills", {})
    except (json.JSONDecodeError, IOError):
        pass

for s in skills:
    u = usage_data.get(s["name"], {})
    s["used"] = u.get("total", 0) > 0
    s["usage_count"] = u.get("total", 0)
    s["last_used"] = u.get("last_used", "never")

# --- Compute totals ---
total_tokens = sum(s["tokens"] for s in skills)
total_used_tokens = sum(s["tokens"] for s in skills if s["used"])
total_unused_tokens = sum(s["tokens"] for s in skills if not s["used"])
budget_pct = (total_tokens / BUDGET * 100) if BUDGET > 0 else 0
waste_pct = (total_unused_tokens / BUDGET * 100) if BUDGET > 0 else 0

used_count = sum(1 for s in skills if s["used"])
unused_count = len(skills) - used_count

# --- Output ---
if JSON_OUTPUT:
    output = {
        "budget": BUDGET,
        "total_tokens": total_tokens,
        "total_used_tokens": total_used_tokens,
        "total_unused_tokens": total_unused_tokens,
        "budget_pct": round(budget_pct, 1),
        "waste_pct": round(waste_pct, 1),
        "skill_count": len(skills),
        "used_count": used_count,
        "unused_count": unused_count,
        "skills": skills,
    }
    print(json.dumps(output, indent=2))
else:
    print("=== Skills Janitor - Context Window Cost ===")
    print(f"Budget: {BUDGET:,} tokens")
    print()

    if not skills:
        print("No skills found.")
        sys.exit(0)

    # Table
    print(f"  {'Skill':<35} {'Tokens':>7} {'Budget':>7} {'Used?':>6} {'Last Used':<10}")
    print(f"  {'─'*35} {'─'*7} {'─'*7} {'─'*6} {'─'*10}")

    for s in skills:
        pct = s["tokens"] / BUDGET * 100 if BUDGET > 0 else 0
        used_marker = "yes" if s["used"] else "NO"
        lu = s["last_used"] if s["last_used"] != "never" else "never"
        print(f"  {s['name']:<35} {s['tokens']:>7,} {pct:>6.1f}% {used_marker:>6} {lu:<10}")

    print()
    print("─" * 78)
    print(f"  {'TOTAL':<35} {total_tokens:>7,} {budget_pct:>6.1f}%")
    print()

    # Summary
    print("--- Summary ---")
    print(f"  Skills loaded: {len(skills)} ({used_count} active, {unused_count} unused)")
    print(f"  Total token cost: {total_tokens:,} ({budget_pct:.1f}% of {BUDGET:,} budget)")
    print(f"  Active skill cost: {total_used_tokens:,}")
    print(f"  Unused skill cost: {total_unused_tokens:,} ({waste_pct:.1f}% of budget wasted)")
    print()

    if total_unused_tokens > 0:
        # Top unused token wasters
        unused_skills = [s for s in skills if not s["used"]]
        if unused_skills:
            print("--- Top Unused Token Wasters ---")
            for s in unused_skills[:5]:
                pct = s["tokens"] / BUDGET * 100 if BUDGET > 0 else 0
                print(f"  {s['tokens']:>7,} tokens ({pct:.1f}%)  {s['name']}")
            if len(unused_skills) > 5:
                rest_tokens = sum(s["tokens"] for s in unused_skills[5:])
                print(f"  {rest_tokens:>7,} tokens         ... and {len(unused_skills) - 5} more")
            print()
            print(f"  Removing unused skills would free {total_unused_tokens:,} tokens ({waste_pct:.1f}% of budget)")

PYEOF
