#!/bin/bash
# Skills Janitor - Dashboard Generator
# Collects all janitor data, injects a snapshot into the HTML dashboard, and opens it.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DATA_DIR="$(cd "$SCRIPT_DIR/.." && pwd)/data"
DASHBOARD="$DATA_DIR/janitor-dashboard.html"

TEMPLATE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)/templates"

command -v python3 &>/dev/null || { echo "ERROR: python3 required" >&2; exit 1; }

mkdir -p "$DATA_DIR"

# Copy template on first run
if [[ ! -f "$DASHBOARD" ]]; then
    if [[ -f "$TEMPLATE_DIR/janitor-dashboard.html" ]]; then
        cp "$TEMPLATE_DIR/janitor-dashboard.html" "$DASHBOARD"
    else
        echo "ERROR: Dashboard template not found" >&2
        echo "  Searched: $TEMPLATE_DIR/janitor-dashboard.html" >&2
        exit 1
    fi
fi

# Temp files for passing data to Python (avoids shell interpolation issues)
TMPDIR_DASH=$(mktemp -d)
trap "rm -rf $TMPDIR_DASH" EXIT

echo "Collecting janitor data..."

"$SCRIPT_DIR/scan.sh" > "$TMPDIR_DASH/scan.json" 2>/dev/null || echo '{}' > "$TMPDIR_DASH/scan.json"
"$SCRIPT_DIR/tokencost.sh" --json > "$TMPDIR_DASH/tokens.json" 2>/dev/null || echo '{}' > "$TMPDIR_DASH/tokens.json"
"$SCRIPT_DIR/usage.sh" --weeks 52 --json > "$TMPDIR_DASH/usage.json" 2>/dev/null || echo '{}' > "$TMPDIR_DASH/usage.json"

# Parse lint into structured JSON
"$SCRIPT_DIR/lint.sh" > "$TMPDIR_DASH/lint.txt" 2>/dev/null || true
python3 -c '
import sys, json, re

with open(sys.argv[1]) as f:
    lines = f.read().strip().split("\n")

issues = []
summary = {"critical": 0, "warnings": 0, "info": 0}

for line in lines:
    line = line.strip()
    m = re.match(r"\[(CRITICAL|WARNING|INFO)\]\s+(\S+):\s+(.*)", line)
    if m:
        sev = m.group(1).lower()
        skill = m.group(2).rstrip(":")
        msg = m.group(3)
        issues.append({"severity": sev, "skill": skill, "message": msg})
    m2 = re.match(r"Critical:\s*(\d+)", line)
    if m2: summary["critical"] = int(m2.group(1))
    m3 = re.match(r"Warnings:\s*(\d+)", line)
    if m3: summary["warnings"] = int(m3.group(1))
    m4 = re.match(r"Info:\s*(\d+)", line)
    if m4: summary["info"] = int(m4.group(1))

summary["issues"] = issues
with open(sys.argv[2], "w") as f:
    json.dump(summary, f)
' "$TMPDIR_DASH/lint.txt" "$TMPDIR_DASH/lint.json" 2>/dev/null \
    || echo '{"critical":0,"warnings":0,"info":0,"issues":[]}' > "$TMPDIR_DASH/lint.json"

echo "Building dashboard..."

# Build snapshot and inject into HTML -- all in one Python call, no shell interpolation
python3 -c '
import json, sys, os
from datetime import datetime, timezone

tmpdir = sys.argv[1]
dashboard_path = sys.argv[2]
max_snapshots = 20

# Load collected data
with open(os.path.join(tmpdir, "scan.json")) as f:
    scan = json.load(f)
with open(os.path.join(tmpdir, "tokens.json")) as f:
    tokens = json.load(f)
with open(os.path.join(tmpdir, "usage.json")) as f:
    usage = json.load(f)
with open(os.path.join(tmpdir, "lint.json")) as f:
    lint = json.load(f)

snapshot = {
    "timestamp": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "scan": scan,
    "tokens": tokens,
    "usage": usage,
    "lint": lint
}

# Read dashboard HTML
with open(dashboard_path) as f:
    html = f.read()

# Find the snapshot data block
marker_start = "<script type=\"application/json\" id=\"snapshotData\">"
marker_end = "</script>"

start_idx = html.find(marker_start)
if start_idx == -1:
    print("ERROR: snapshot marker not found in dashboard", file=sys.stderr)
    sys.exit(1)

# Find the closing </script> after the marker
json_start = start_idx + len(marker_start)
end_idx = html.find(marker_end, json_start)
if end_idx == -1:
    print("ERROR: closing script tag not found", file=sys.stderr)
    sys.exit(1)

# Parse existing snapshots
existing_json = html[json_start:end_idx].strip()
try:
    existing = json.loads(existing_json) if existing_json else []
except (json.JSONDecodeError, ValueError):
    existing = []

# Append and prune
existing.append(snapshot)
if len(existing) > max_snapshots:
    existing = existing[-max_snapshots:]

# Rebuild HTML using string concatenation (no regex, no backreference issues)
new_json = json.dumps(existing, indent=2, ensure_ascii=False)
new_html = html[:start_idx] + marker_start + new_json + html[end_idx:]

with open(dashboard_path, "w") as f:
    f.write(new_html)

print(f"Snapshot added ({len(existing)} total)")
' "$TMPDIR_DASH" "$DASHBOARD"

echo "Opening dashboard..."

# Cross-platform open
if command -v open &>/dev/null; then
    open "$DASHBOARD"
elif command -v xdg-open &>/dev/null; then
    xdg-open "$DASHBOARD"
elif command -v start &>/dev/null; then
    start "$DASHBOARD"
else
    echo "Dashboard saved to: $DASHBOARD"
    echo "Open it manually in your browser."
fi
