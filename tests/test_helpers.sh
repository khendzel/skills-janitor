#!/bin/bash
# Seam 2: per-function tests for the shared frontmatter helpers and the
# extracted TSV reader, so a parsing bug can be localized without bisecting
# whole-CLI output.
#
#   1. Sources scripts/paths.sh and calls extract_description directly against
#      fixture SKILL.md files: inline value, `|` literal block, `>-` chomped
#      fold, `>+2` fold with keep-chomp and indent digit, and CRLF variants.
#   2. Invokes scripts/tsv_reader.py standalone against fixture TSVs,
#      including one with an embedded CR — the silent-record-loss class: the
#      record must survive as ONE intact row.
#
# Tests observe external behavior only (function stdout, helper stdout).
# No framework; must stay green on macOS bash 3.2.

set -u

REPO_DIR=$(cd "$(dirname "$0")/.." && pwd)
TMP=$(mktemp -d -t janitor-seam2.XXXXXX)
trap 'rm -rf "$TMP"' EXIT

PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); echo "  ok: $1"; }
fail() { FAIL=$((FAIL + 1)); echo "  FAIL: $1"; }

# Point HOME at an empty fixture dir so sourcing paths.sh (which scans skill
# roots under $HOME) is hermetic, then load the helpers.
HOME="$TMP/home"
mkdir -p "$HOME"
# shellcheck disable=SC1091  # runtime path; sourcing IS the seam under test
source "$REPO_DIR/scripts/paths.sh"

# check_desc <label> <fixture-file> <expected-description>
check_desc() {
    local label="$1" file="$2" expected="$3"
    local got
    got=$(extract_description "$file")
    if [ "$got" = "$expected" ]; then
        pass "extract_description: $label"
    else
        fail "extract_description: $label — got '$got', want '$expected'"
    fi
}

echo "extract_description: inline and block-scalar header grammar"

cat > "$TMP/inline.md" <<'EOF'
---
name: inline
description: Plain inline value. Use when testing the inline path.
---
# Body
EOF
check_desc "inline value" "$TMP/inline.md" \
    "Plain inline value. Use when testing the inline path."

cat > "$TMP/literal.md" <<'EOF'
---
name: literal
description: |
  Literal block first line.
  Literal block second line.
---
# Body
EOF
check_desc "| literal block" "$TMP/literal.md" \
    "Literal block first line. Literal block second line."

cat > "$TMP/chomp.md" <<'EOF'
---
name: chomp
description: >-
  Folded chomped text. Use when the header carries a strip indicator.
---
# Body
EOF
check_desc ">- chomped fold" "$TMP/chomp.md" \
    "Folded chomped text. Use when the header carries a strip indicator."

cat > "$TMP/keepindent.md" <<'EOF'
---
name: keepindent
description: >+2
  Folded keep text with an explicit indent digit.
  Second folded line.
---
# Body
EOF
check_desc ">+2 keep-chomp with indent digit" "$TMP/keepindent.md" \
    "Folded keep text with an explicit indent digit. Second folded line."

echo "extract_description: CRLF variants"

printf -- '---\r\nname: crlfinline\r\ndescription: CRLF inline value. Use when the file is Windows-authored.\r\n---\r\n\r\n# Body\r\n' \
    > "$TMP/crlf-inline.md"
check_desc "CRLF inline value" "$TMP/crlf-inline.md" \
    "CRLF inline value. Use when the file is Windows-authored."

printf -- '---\r\nname: crlfchomp\r\ndescription: >-\r\n  CRLF folded text.\r\n  Use when block scalars meet CRLF.\r\n---\r\n\r\n# Body\r\n' \
    > "$TMP/crlf-chomp.md"
check_desc "CRLF >- chomped fold" "$TMP/crlf-chomp.md" \
    "CRLF folded text. Use when block scalars meet CRLF."

# --- TSV reader helper ------------------------------------------------------
echo "tsv_reader: standalone invocation against fixture TSVs"

READER="$REPO_DIR/scripts/tsv_reader.py"

# check_tsv <label> <fixture-file> <n_fields> <expected-json>
check_tsv() {
    local label="$1" file="$2" n_fields="$3" expected="$4"
    local got
    got=$(python3 "$READER" "$file" "$n_fields")
    if [ "$got" = "$expected" ]; then
        pass "tsv_reader: $label"
    else
        fail "tsv_reader: $label — got '$got', want '$expected'"
    fi
}

printf 'alpha\tbeta\tgamma\n' > "$TMP/plain.tsv"
check_tsv "plain record" "$TMP/plain.tsv" 3 \
    '[["alpha", "beta", "gamma"]]'

printf 'alpha\t_\tgamma\n' > "$TMP/sentinel.tsv"
check_tsv "sentinel _ decodes to empty" "$TMP/sentinel.tsv" 3 \
    '[["alpha", "", "gamma"]]'

# The silent-record-loss class: with universal newlines the CR inside field 2
# would end the line, splitting one record into two short ones that both fail
# the field-count check. The pinned newline="\n" keeps it ONE intact record.
printf 'x\ty\rz\tw\n' > "$TMP/embedded-cr.tsv"
check_tsv "embedded-CR record survives intact" "$TMP/embedded-cr.tsv" 3 \
    '[["x", "y\rz", "w"]]'

printf 'a\tb\tc\nshort\trow\nd\te\tf\n' > "$TMP/counts.tsv"
check_tsv "wrong-field-count row is skipped, neighbors kept" "$TMP/counts.tsv" 3 \
    '[["a", "b", "c"], ["d", "e", "f"]]'

printf 'a\tb\tc\n\nd\te\tf\n' > "$TMP/blank.tsv"
check_tsv "blank line is skipped" "$TMP/blank.tsv" 3 \
    '[["a", "b", "c"], ["d", "e", "f"]]'

check_tsv "missing file yields empty result" "$TMP/does-not-exist.tsv" 3 '[]'

# --- Summary ----------------------------------------------------------------
echo
echo "seam 2: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
