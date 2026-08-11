#!/bin/bash
# Seam 1: whole-CLI regression tests under a fixture $HOME.
#
# Permanent, assertive version of the reproduction script from PR #7. Each
# fixture pins one parser failure mode that once produced phantom findings or
# silent data loss:
#   apos  - description with a single apostrophe (odd count — an even count
#           balances shell quoting and masks the old xargs bug)
#   chomp - chomped block scalar (`description: >-`) once read as the literal
#           two-character string ">-"
#   crlf  - fully CRLF file: once missing from the scan inventory entirely,
#           reported as broken frontmatter, and corrupted by `fix --apply`
#
# Tests observe external behavior only: lint stdout, scan JSON, and file bytes
# after `fix --apply`. No framework; must stay green on macOS bash 3.2.

set -u

REPO_DIR=$(cd "$(dirname "$0")/.." && pwd)
TMP=$(mktemp -d -t janitor-seam1.XXXXXX)
trap 'rm -rf "$TMP"' EXIT

PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); echo "  ok: $1"; }
fail() { FAIL=$((FAIL + 1)); echo "  FAIL: $1"; }

# --- Fixture home -----------------------------------------------------------
# Bodies carry real content (Steps + Gotchas) so a healthy skill lints to zero
# findings and any parser artifact shows up as a nonzero count.
FIXTURE_HOME="$TMP/home"
mkdir -p "$FIXTURE_HOME/.claude/skills/apos" \
         "$FIXTURE_HOME/.claude/skills/chomp" \
         "$FIXTURE_HOME/.claude/skills/crlf"

APOS_DESC="Formats the user's code to match the documented standards. Use when the user asks to format a file."
CHOMP_DESC="Converts spreadsheets between formats. Use when the user mentions xlsx or csv."
CRLF_DESC="Handles Windows-authored files. Use when a file has CRLF endings."

cat > "$FIXTURE_HOME/.claude/skills/apos/SKILL.md" <<EOF
---
name: apos
description: $APOS_DESC
---
# Apos

Formats source files according to the project's documented style rules.

## Steps

1. Read the target file.
2. Apply the formatter.
3. Report what changed.

## Gotchas

- Only run on files inside the repository.
EOF

cat > "$FIXTURE_HOME/.claude/skills/chomp/SKILL.md" <<EOF
---
name: chomp
description: >-
  $CHOMP_DESC
---
# Chomp

Converts spreadsheet files between common interchange formats.

## Steps

1. Detect the source format.
2. Convert with the standard tool.
3. Verify row counts match.

## Gotchas

- Large files may need streaming conversion.
EOF

# Built with printf so every line ending is a literal CRLF.
printf -- '---\r\nname: crlf\r\ndescription: %s\r\n---\r\n\r\n# Crlf\r\n\r\nHandles files that were authored on Windows and carry CRLF line endings.\r\n\r\n## Steps\r\n\r\n1. Detect the line-ending style.\r\n2. Process the file without corrupting it.\r\n3. Preserve the original endings on write.\r\n\r\n## Gotchas\r\n\r\n- Never assume LF endings when editing in place.\r\n' \
    "$CRLF_DESC" > "$FIXTURE_HOME/.claude/skills/crlf/SKILL.md"

# Neutral cwd so the project scope (./.claude) can't pick anything up from the
# directory the test happens to be launched from.
WORKDIR="$TMP/work"
mkdir -p "$WORKDIR"
cd "$WORKDIR" || exit 1

# --- Lint: zero findings on all three fixtures ------------------------------
echo "lint: zero findings on the fixture collection"
LINT_OUT=$(HOME="$FIXTURE_HOME" bash "$REPO_DIR/scripts/lint.sh" 2>&1)
LINT_STATUS=$?
if [ "$LINT_STATUS" -ne 0 ]; then
    fail "lint.sh exited $LINT_STATUS"
    printf '%s\n' "$LINT_OUT" | sed 's/^/    | /'
fi
for want in "Critical: 0" "Warnings: 0" "Info:     0"; do
    if printf '%s\n' "$LINT_OUT" | grep -qF "$want"; then
        pass "lint summary has '$want'"
    else
        fail "lint summary missing '$want'"
        printf '%s\n' "$LINT_OUT" | sed 's/^/    | /'
    fi
done

# --- Scan: all three skills present with intact descriptions ----------------
echo "scan: inventory contains all three fixtures with intact descriptions"
SCAN_JSON="$TMP/scan.json"
if HOME="$FIXTURE_HOME" bash "$REPO_DIR/scripts/scan.sh" > "$SCAN_JSON" 2>"$TMP/scan.err"; then
    pass "scan.sh exited 0"
else
    fail "scan.sh exited nonzero"
    sed 's/^/    | /' "$TMP/scan.err"
fi
SCAN_CHECK=$(python3 - "$SCAN_JSON" "$APOS_DESC" "$CHOMP_DESC" "$CRLF_DESC" <<'PYEOF'
import json, sys
data = json.load(open(sys.argv[1]))
want = {"apos": sys.argv[2], "chomp": sys.argv[3], "crlf": sys.argv[4]}
got = {s["folder"]: s["description"] for s in data["skills"]}
for folder, desc in sorted(want.items()):
    if folder not in got:
        print("MISSING %s" % folder)
    elif got[folder].strip() != desc:
        print("WRONG %s: %r" % (folder, got[folder]))
    else:
        print("OK %s" % folder)
PYEOF
)
for skill in apos chomp crlf; do
    if printf '%s\n' "$SCAN_CHECK" | grep -qx "OK $skill"; then
        pass "scan has $skill with intact description"
    else
        fail "scan check for $skill: $(printf '%s\n' "$SCAN_CHECK" | grep " $skill" || echo 'no result')"
    fi
done

# --- Fix --apply: CRLF file byte-identical except the metadata addition -----
echo "fix --apply: CRLF fixture untouched except the intended metadata addition"
FIX_HOME="$TMP/fixhome"
mkdir -p "$FIX_HOME/.claude/skills/crlf"
CRLF_ORIG="$FIXTURE_HOME/.claude/skills/crlf/SKILL.md"
CRLF_FIXED="$FIX_HOME/.claude/skills/crlf/SKILL.md"
cp "$CRLF_ORIG" "$CRLF_FIXED"
FIX_OUT=$(HOME="$FIX_HOME" bash "$REPO_DIR/scripts/fix.sh" --apply 2>&1)
FIX_STATUS=$?
if [ "$FIX_STATUS" -eq 0 ]; then
    pass "fix.sh --apply exited 0"
else
    fail "fix.sh --apply exited $FIX_STATUS"
    printf '%s\n' "$FIX_OUT" | sed 's/^/    | /'
fi
# The corrupting path once prepended a second "---" and replaced the real
# description with a placeholder template; both must stay dead.
if printf '%s\n' "$FIX_OUT" | grep -q 'Added missing frontmatter delimiters\|Added missing closing ---\|Added template description'; then
    fail "fix.sh fired a delimiter/description fix on a valid CRLF file"
    printf '%s\n' "$FIX_OUT" | sed 's/^/    | /'
else
    pass "fix.sh applied no delimiter or description fix"
fi
# Byte-level check: removing exactly the intended metadata lines must restore
# the original file, byte for byte (CRs included).
sed -e '/^metadata:$/d' -e '/^  version: "1.0.0"$/d' "$CRLF_FIXED" > "$TMP/crlf-minus-metadata"
if cmp -s "$TMP/crlf-minus-metadata" "$CRLF_ORIG"; then
    pass "file is byte-identical apart from the metadata addition"
else
    fail "file differs beyond the metadata addition"
    diff <(cat -v "$CRLF_ORIG") <(cat -v "$CRLF_FIXED") | sed 's/^/    | /'
fi
if grep -q '^metadata:$' "$CRLF_FIXED" && grep -q '^  version: "1.0.0"$' "$CRLF_FIXED"; then
    pass "intended metadata.version addition is present"
else
    fail "expected metadata.version addition not found"
fi

# --- Summary ----------------------------------------------------------------
echo
echo "seam 1: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
