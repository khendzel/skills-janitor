#!/bin/bash
# Skills Janitor - Platform Path Detection
# Detects Claude Code and OpenAI Codex skill directories
# Source this file: source "$(dirname "$0")/paths.sh"

# --- Claude Code paths ---
CLAUDE_USER_SKILLS="$HOME/.claude/skills"
CLAUDE_PROJECT_SKILLS="./.claude/skills"

# --- OpenAI Codex paths ---
CODEX_USER_SKILLS="$HOME/.agents/skills"
CODEX_PROJECT_SKILLS="./.agents/skills"

# --- Aggregate all valid skill directories ---
# Each entry is "scope:platform:path"
ALL_SKILL_DIRS=()

add_dir() {
    local path="$1" scope="$2" platform="$3"
    if [[ -d "$path" ]]; then
        ALL_SKILL_DIRS+=("$scope:$platform:$path")
    fi
}

add_dir "$CLAUDE_USER_SKILLS" "user" "claude"
add_dir "$CODEX_USER_SKILLS" "user" "codex"

# Deduplicate project dirs (avoid scanning same real path twice)
_add_project_dir() {
    local path="$1" platform="$2"
    if [[ ! -d "$path" ]]; then
        return 0
    fi
    local real_path
    real_path=$(cd "$path" 2>/dev/null && pwd -P || echo "")
    local dominated=false
    for existing in "${ALL_SKILL_DIRS[@]}"; do
        local existing_path="${existing#*:*:}"
        local existing_real
        existing_real=$(cd "$existing_path" 2>/dev/null && pwd -P || echo "")
        if [[ "$real_path" == "$existing_real" ]]; then
            dominated=true
            break
        fi
    done
    if [[ "$dominated" == "false" ]]; then
        ALL_SKILL_DIRS+=("project:$platform:$path")
    fi
}

_add_project_dir "$CLAUDE_PROJECT_SKILLS" "claude"
_add_project_dir "$CODEX_PROJECT_SKILLS" "codex"

# --- Detect which platforms are present ---
HAS_CLAUDE=false
HAS_CODEX=false
for entry in "${ALL_SKILL_DIRS[@]}"; do
    if [[ "$entry" == *":claude:"* ]]; then
        HAS_CLAUDE=true
    elif [[ "$entry" == *":codex:"* ]]; then
        HAS_CODEX=true
    fi
done

# --- Helper: iterate all skill directories ---
# Usage: for_each_skill_dir <callback_function>
# Callback receives: dir scope platform
for_each_skill_dir() {
    local callback="$1"
    for entry in "${ALL_SKILL_DIRS[@]}"; do
        local scope="${entry%%:*}"
        local rest="${entry#*:}"
        local platform="${rest%%:*}"
        local path="${rest#*:}"
        "$callback" "$path" "$scope" "$platform"
    done
}

# --- Platform display ---
platform_label() {
    if [[ "$HAS_CLAUDE" == "true" && "$HAS_CODEX" == "true" ]]; then
        echo "Claude Code + Codex"
    elif [[ "$HAS_CODEX" == "true" ]]; then
        echo "Codex"
    else
        echo "Claude Code"
    fi
}
