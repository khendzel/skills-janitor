#!/bin/bash
# Skills Janitor - Duplicate Detection
# Finds skills with overlapping descriptions and trigger keywords

set -euo pipefail

command -v python3 &>/dev/null || { echo "ERROR: python3 required" >&2; exit 1; }

# --- Load platform paths ---
source "$(dirname "$0")/paths.sh"

# Collect all skill descriptions into a temp file
export TMPFILE=$(mktemp)
trap "rm -f $TMPFILE" EXIT

extract_skills() {
    local dir="$1"
    local scope="$2"
    [[ -d "$dir" ]] || return

    for skill_dir in "$dir"/*/; do
        [[ -d "$skill_dir" ]] || continue
        local name
        name=$(basename "$skill_dir")

        # Skip self
        [[ "$name" == "skills-janitor" ]] && continue

        local skill_file=""
        [[ -f "$skill_dir/SKILL.md" ]] && skill_file="$skill_dir/SKILL.md"
        [[ -f "$skill_dir/Skill.md" ]] && skill_file="$skill_dir/Skill.md"
        [[ -z "$skill_file" ]] && continue
        [[ ! -e "$skill_file" ]] && continue  # broken symlink

        # Extract description
        local desc
        desc=$(awk 'NR==1 && /^---$/{started=1; next} started && /^---$/{exit} started && /^description:/{sub(/^description:[[:space:]]*/,""); gsub(/"/,""); print}' "$skill_file" | tr '[:upper:]' '[:lower:]')

        printf '%s\t%s\t%s\n' "$scope" "$name" "$desc" >> "$TMPFILE"
    done
}

# Scan all platforms (Claude Code + Codex)
_dupes_scan() { extract_skills "$1" "$2"; }
for_each_skill_dir _dupes_scan

echo "=== Skills Janitor - Duplicate Detection ==="
echo ""
echo "Total skills scanned: $(wc -l < "$TMPFILE" | tr -d ' ')"
echo ""

# Extract trigger keywords from descriptions
# Look for patterns like "when the user mentions X, Y, Z" or trigger words
echo "--- Keyword Overlap Analysis ---"
echo ""

python3 << 'PYEOF'
import re
import sys
from collections import defaultdict

skills = []
with open(sys.argv[1] if len(sys.argv) > 1 else "/dev/stdin") as f:
    pass

# Read from the temp file
import os
tmpfile = os.environ.get("TMPFILE", "")
if not tmpfile:
    # Fallback: read from the file passed as argument
    tmpfile = sys.argv[1] if len(sys.argv) > 1 else ""

with open(tmpfile) as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        parts = line.split("\t", 2)
        if len(parts) < 3:
            continue
        scope, name, desc = parts
        skills.append({"scope": scope, "name": name, "desc": desc})

if not skills:
    print("No skills found to analyze.")
    sys.exit(0)

# Extract trigger keywords from descriptions
def extract_keywords(desc):
    """Extract meaningful trigger keywords from a description."""
    # Remove common filler words
    stop_words = {"use", "when", "the", "user", "wants", "to", "or", "and", "a", "an",
                  "this", "skill", "also", "that", "for", "with", "in", "on", "of",
                  "is", "are", "it", "be", "as", "at", "by", "from", "their", "they",
                  "has", "have", "do", "does", "can", "will", "about", "not", "but",
                  "if", "its", "into", "your", "you", "how", "what", "which", "any",
                  "all", "each", "every", "both", "more", "most", "other", "some",
                  "such", "than", "too", "very", "just", "only", "own", "same",
                  "mentions", "says", "asks", "help", "create", "make", "build",
                  "improve", "optimize", "review", "write", "generate", "set", "up"}

    # Get words
    words = re.findall(r'[a-z]+', desc.lower())
    keywords = set(w for w in words if w not in stop_words and len(w) > 2)
    return keywords

# Compare all pairs
overlaps = []
for i in range(len(skills)):
    kw_i = extract_keywords(skills[i]["desc"])
    for j in range(i + 1, len(skills)):
        kw_j = extract_keywords(skills[j]["desc"])
        common = kw_i & kw_j
        if not kw_i or not kw_j:
            continue
        # Jaccard similarity
        union = kw_i | kw_j
        similarity = len(common) / len(union) if union else 0

        if similarity > 0.3:  # Threshold for flagging
            overlaps.append({
                "skill_a": skills[i]["name"],
                "skill_b": skills[j]["name"],
                "similarity": round(similarity * 100),
                "common_keywords": sorted(common)[:10],
                "scope_a": skills[i]["scope"],
                "scope_b": skills[j]["scope"],
            })

# Sort by similarity descending
overlaps.sort(key=lambda x: x["similarity"], reverse=True)

if not overlaps:
    print("No significant overlaps detected.")
else:
    print(f"Found {len(overlaps)} potential overlap(s):\n")
    for o in overlaps:
        print(f"  [{o['similarity']}%] {o['skill_a']} <-> {o['skill_b']}")
        print(f"       Scopes: {o['scope_a']}, {o['scope_b']}")
        print(f"       Shared keywords: {', '.join(o['common_keywords'][:8])}")
        print()

PYEOF
