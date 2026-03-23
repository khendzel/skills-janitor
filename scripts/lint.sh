#!/bin/bash
# Skills Janitor - Lint Check
# Validates skills against best practices

set -euo pipefail

USER_SKILLS="$HOME/.claude/skills"
PROJECT_SKILLS="./.claude/skills"

ISSUES=0
WARNINGS=0
INFO=0

print_issue() {
    local severity="$1"
    local skill="$2"
    local message="$3"

    case "$severity" in
        critical) echo "  [CRITICAL] $skill: $message"; ((ISSUES++)) || true ;;
        warning)  echo "  [WARNING]  $skill: $message"; ((WARNINGS++)) || true ;;
        info)     echo "  [INFO]     $skill: $message"; ((INFO++)) || true ;;
    esac
}

lint_skill() {
    local path="$1"
    local scope="$2"
    local name
    name=$(basename "$path")

    # Skip self
    [[ "$name" == "skills-janitor" ]] && return

    # Check if symlink is broken
    if [[ -L "$path" && ! -e "$path" ]]; then
        print_issue "critical" "$name" "Broken symlink -> $(readlink "$path" 2>/dev/null || echo 'unknown')"
        return
    fi

    # Find skill file
    local skill_file=""
    [[ -f "$path/SKILL.md" ]] && skill_file="$path/SKILL.md"
    [[ -f "$path/Skill.md" ]] && skill_file="$path/Skill.md"

    if [[ -z "$skill_file" ]]; then
        print_issue "critical" "$name" "No SKILL.md file found"
        return
    fi

    # Check frontmatter exists
    if ! head -1 "$skill_file" | grep -q '^---'; then
        print_issue "critical" "$name" "Missing frontmatter (no opening ---)"
        return
    fi

    # Check closing frontmatter
    local fm_close
    fm_close=$(awk 'NR>1 && /^---$/{print NR; exit}' "$skill_file")
    if [[ -z "$fm_close" ]]; then
        print_issue "critical" "$name" "Missing closing --- in frontmatter"
        return
    fi

    # Extract frontmatter
    local frontmatter
    frontmatter=$(sed -n "2,$((fm_close - 1))p" "$skill_file")

    # Check name field
    local name_field
    name_field=$(echo "$frontmatter" | grep -E '^name:' | sed 's/^name:\s*//' | tr -d '"' | tr -d "'" | xargs 2>/dev/null || echo "")
    if [[ -z "$name_field" ]]; then
        print_issue "warning" "$name" "Missing 'name' field in frontmatter"
    elif [[ "$(echo "$name_field" | tr '[:upper:]' '[:lower:]')" != "$(echo "$name" | tr '[:upper:]' '[:lower:]')" && "$(echo "$name_field" | tr ' ' '-' | tr '[:upper:]' '[:lower:]')" != "$(echo "$name" | tr '[:upper:]' '[:lower:]')" ]]; then
        print_issue "info" "$name" "Folder name '$name' doesn't match skill name '$name_field'"
    fi

    # Check description field
    local desc
    desc=$(echo "$frontmatter" | grep -E '^description:' | sed 's/^description:\s*//' | tr -d '"' | tr -d "'" | xargs 2>/dev/null || echo "")
    if [[ -z "$desc" ]]; then
        print_issue "critical" "$name" "Missing 'description' field - Claude can't trigger this skill"
    else
        local desc_len=${#desc}
        if [[ $desc_len -lt 30 ]]; then
            print_issue "warning" "$name" "Description too short ($desc_len chars) - should be 50-200 for good triggering"
        elif [[ $desc_len -gt 250 ]]; then
            print_issue "info" "$name" "Description is long ($desc_len chars) - consider trimming to < 200"
        fi

        # Check if description has trigger words
        if ! echo "$desc" | grep -qi -E '(when|trigger|use for|invoke|mention|says|asks|also use|use this|relevant|appropriate|helps with|designed for)'; then
            print_issue "warning" "$name" "Description doesn't explain when to trigger - add 'Use when...' or 'Also use when...'"
        fi
    fi

    # Check body content
    local body_lines
    body_lines=$(tail -n +"$((fm_close + 1))" "$skill_file" | grep -c '[^ ]' 2>/dev/null || echo "0")
    if [[ "$body_lines" -lt 3 ]]; then
        print_issue "warning" "$name" "Very little body content ($body_lines non-empty lines)"
    fi

    # Check for gotchas section
    if ! grep -qi 'gotcha' "$skill_file" 2>/dev/null; then
        print_issue "info" "$name" "No Gotchas section - consider adding common pitfalls"
    fi

    # Check total size
    local total_lines
    total_lines=$(wc -l < "$skill_file" | tr -d ' ')
    if [[ "$total_lines" -gt 500 ]]; then
        print_issue "info" "$name" "Skill file is large ($total_lines lines) - consider using progressive disclosure with reference files"
    fi
}

echo "=== Skills Janitor - Lint Report ==="
echo ""

echo "--- User Skills ($USER_SKILLS) ---"
if [[ -d "$USER_SKILLS" ]]; then
    for skill_dir in "$USER_SKILLS"/*/; do
        [[ -d "$skill_dir" ]] || continue
        lint_skill "${skill_dir%/}" "user"
    done
fi

# Only scan project skills if they're different from user skills
USER_REAL=$(cd "$USER_SKILLS" 2>/dev/null && pwd -P)
PROJECT_REAL=$(cd "$PROJECT_SKILLS" 2>/dev/null && pwd -P)
if [[ -d "$PROJECT_SKILLS" && "$USER_REAL" != "$PROJECT_REAL" ]]; then
    echo ""
    echo "--- Project Skills ($PROJECT_SKILLS) ---"
    for skill_dir in "$PROJECT_SKILLS"/*/; do
        [[ -d "$skill_dir" ]] || continue
        lint_skill "${skill_dir%/}" "project"
    done
fi

echo ""
echo "=== Summary ==="
echo "  Critical: $ISSUES"
echo "  Warnings: $WARNINGS"
echo "  Info:     $INFO"
echo "  Total:    $((ISSUES + WARNINGS + INFO))"
