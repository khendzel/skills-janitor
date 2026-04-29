#!/bin/bash
# Skills Janitor - Scan & Inventory
# Discovers all skills across all scopes and outputs a JSON inventory

set -euo pipefail

command -v python3 &>/dev/null || { echo "ERROR: python3 required" >&2; exit 1; }

# --- Load platform paths ---
source "$(dirname "$0")/paths.sh"

# Claude-specific paths
USER_SKILLS="$CLAUDE_USER_SKILLS"
USER_COMMANDS="$HOME/.claude/commands"
PLUGINS_DIR="$HOME/.claude/plugins"
SOURCES_DIR="$HOME/.claude/sources"
ACCOUNT_PLUGINS_PERSONAL="$HOME/.claude-account-personal/plugins"
ACCOUNT_PLUGINS_COMPANY="$HOME/.claude-account-company/plugins"

# Project scope
PROJECT_SKILLS="$CLAUDE_PROJECT_SKILLS"
PROJECT_COMMANDS="./.claude/commands"

# Codex paths
CODEX_USER="$CODEX_USER_SKILLS"
CODEX_PROJECT="$CODEX_PROJECT_SKILLS"

FIRST_SKILL=true

scan_skill() {
    local path="$1"
    local scope="$2"
    local skill_name
    skill_name=$(basename "$path")

    # Skip self (plugin data dir, not a real skill)
    [[ "$skill_name" == "skills-janitor" ]] && return

    local skill_file=""
    if [[ -f "$path/SKILL.md" ]]; then
        skill_file="$path/SKILL.md"
    elif [[ -f "$path/Skill.md" ]]; then
        skill_file="$path/Skill.md"
    fi

    local is_symlink="false"
    local symlink_target=""
    if [[ -L "$path" ]]; then
        is_symlink="true"
        symlink_target=$(readlink "$path" 2>/dev/null || echo "broken")
        # Check if target exists
        if [[ ! -e "$path" ]]; then
            symlink_target="BROKEN:$symlink_target"
        fi
    fi

    local name_field=""
    local description=""
    local version=""
    local has_frontmatter="false"
    local has_body="false"
    local line_count=0

    if [[ -n "$skill_file" && -f "$skill_file" ]]; then
        line_count=$(wc -l < "$skill_file" | tr -d ' ')

        # Parse frontmatter
        if head -1 "$skill_file" | grep -q '^---'; then
            has_frontmatter="true"
            # Extract fields from frontmatter
            local frontmatter
            frontmatter=$(awk 'NR==1 && /^---$/{next} /^---$/{exit} {print}' "$skill_file")
            name_field=$(echo "$frontmatter" | grep -E '^name:' | sed 's/^name:[[:space:]]*//' | tr -d '"' | head -1 || true)
            description=$(echo "$frontmatter" | grep -E '^description:' | sed 's/^description:[[:space:]]*//' | tr -d '"' | head -1 || true)
            version=$(echo "$frontmatter" | grep -E '^version:' | sed 's/^version:[[:space:]]*//' | tr -d '"' | head -1 || true)
        fi

        # Check if there's content after frontmatter
        local body_start
        body_start=$(awk '/^---$/{c++; if(c==2){print NR; exit}}' "$skill_file" 2>/dev/null || echo "0")
        if [[ "$body_start" -gt 0 ]]; then
            local remaining
            remaining=$(tail -n +"$((body_start + 1))" "$skill_file" | grep -c '[^ ]' 2>/dev/null || echo "0")
            if [[ "$remaining" -gt 0 ]]; then
                has_body="true"
            fi
        fi
    fi

    # Count extra files in skill directory
    local extra_files=0
    if [[ -d "$path" ]]; then
        extra_files=$(find "$path" -type f ! -name "SKILL.md" ! -name "Skill.md" ! -name ".DS_Store" 2>/dev/null | wc -l | tr -d ' ')
    fi

    # Escape values for safe JSON output
    local json_folder json_symlink json_name json_desc json_version
    json_folder=$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$skill_name" 2>/dev/null || echo '""')
    json_symlink=$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$symlink_target" 2>/dev/null || echo '""')
    json_name=$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$name_field" 2>/dev/null || echo '""')
    json_desc=$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$description" 2>/dev/null || echo '""')
    json_version=$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$version" 2>/dev/null || echo '""')

    # Emit comma separator only after the first object — comma must follow a real
    # object, not an early-returned skip, otherwise the JSON ends up with double commas.
    if [[ "$FIRST_SKILL" == "true" ]]; then
        FIRST_SKILL=false
    else
        echo ","
    fi

    # Output as JSON object
    cat <<ENDJSON
  {
    "folder": $json_folder,
    "scope": "$scope",
    "path": "$path",
    "is_symlink": $is_symlink,
    "symlink_target": $json_symlink,
    "has_skill_file": $([ -n "$skill_file" ] && echo "true" || echo "false"),
    "name": $json_name,
    "description": $json_desc,
    "version": $json_version,
    "has_frontmatter": $has_frontmatter,
    "has_body": $has_body,
    "line_count": $line_count,
    "extra_files": $extra_files
  }
ENDJSON
}

echo "{"
echo '  "scan_date": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'",'
echo '  "skills": ['

# Scan user-level skills
if [[ -d "$USER_SKILLS" ]]; then
    for skill_dir in "$USER_SKILLS"/*/; do
        [[ -d "$skill_dir" ]] || continue
        scan_skill "${skill_dir%/}" "user"
    done
fi

# Scan project-level skills
if [[ -d "$PROJECT_SKILLS" ]]; then
    for skill_dir in "$PROJECT_SKILLS"/*/; do
        [[ -d "$skill_dir" ]] || continue
        scan_skill "${skill_dir%/}" "project"
    done
fi

# Scan Codex user-level skills
if [[ -d "$CODEX_USER" ]]; then
    for skill_dir in "$CODEX_USER"/*/; do
        [[ -d "$skill_dir" ]] || continue
        scan_skill "${skill_dir%/}" "codex-user"
    done
fi

# Scan Codex project-level skills
if [[ -d "$CODEX_PROJECT" ]]; then
    CODEX_P_REAL=$(cd "$CODEX_PROJECT" 2>/dev/null && pwd -P || echo "")
    CODEX_U_REAL=$(cd "$CODEX_USER" 2>/dev/null && pwd -P || echo "")
    if [[ "$CODEX_P_REAL" != "$CODEX_U_REAL" ]]; then
        for skill_dir in "$CODEX_PROJECT"/*/; do
            [[ -d "$skill_dir" ]] || continue
            scan_skill "${skill_dir%/}" "codex-project"
        done
    fi
fi

echo ""
echo "  ],"

# Scan for plugin info
echo '  "plugins": ['
first=true
if [[ -f "$HOME/.claude/plugins/installed_plugins.json" ]]; then
    # Parse installed_plugins.json. Claude Code v2 emits
    #   {"version": 2, "plugins": {"<name>@<source>": [{instance}, ...]}}
    # Older Claude Code versions may emit a flat array — keep that path
    # as a fallback so older installs still produce output.
    cat "$HOME/.claude/plugins/installed_plugins.json" | python3 -c '
import json, sys
try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(0)

records = []
if isinstance(data, dict) and isinstance(data.get("plugins"), dict):
    for key, instances in data["plugins"].items():
        if "@" in key:
            name, source = key.rsplit("@", 1)
        else:
            name, source = key, ""
        if not isinstance(instances, list):
            continue
        for inst in instances:
            if not isinstance(inst, dict):
                continue
            records.append({
                "name": name,
                "source": source,
                "version": inst.get("version", ""),
                "scope": inst.get("scope", ""),
            })
elif isinstance(data, list):
    for p in data:
        if not isinstance(p, dict):
            continue
        records.append({
            "name": p.get("name", ""),
            "version": p.get("version", ""),
            "source": p.get("source", ""),
        })

first = True
for r in records:
    if not first:
        print(",")
    first = False
    print(json.dumps(r, indent=4))
' 2>/dev/null || echo ""
fi
echo "  ],"

# Scan for commands
echo '  "commands": ['
first=true
if [[ -d "$USER_COMMANDS" ]]; then
    for cmd_file in "$USER_COMMANDS"/*.md; do
        [[ -f "$cmd_file" ]] || continue
        cmd_name=$(basename "$cmd_file" .md)
        if [[ "$first" == "true" ]]; then
            first=false
        else
            echo ","
        fi
        echo "    {\"name\": \"$cmd_name\", \"scope\": \"user\", \"path\": \"$cmd_file\"}"
    done
fi
if [[ -d "$PROJECT_COMMANDS" ]]; then
    for cmd_file in "$PROJECT_COMMANDS"/*.md; do
        [[ -f "$cmd_file" ]] || continue
        cmd_name=$(basename "$cmd_file" .md)
        if [[ "$first" == "true" ]]; then
            first=false
        else
            echo ","
        fi
        echo "    {\"name\": \"$cmd_name\", \"scope\": \"project\", \"path\": \"$cmd_file\"}"
    done
fi
echo "  ],"

# Count broken symlinks
broken_count=0
if [[ -d "$USER_SKILLS" ]]; then
    broken_count=$(find "$USER_SKILLS" -maxdepth 1 -type l ! -exec test -e {} \; -print 2>/dev/null | wc -l | tr -d ' ')
fi
echo "  \"broken_symlinks\": $broken_count"

echo "}"
