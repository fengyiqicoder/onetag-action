#!/usr/bin/env bash
# Checks a folder after the action ran on it.
# Usage: test/check.sh <folder> <mode> [key]
#   mode: both | llms-only | ask-only
set -euo pipefail
DIR="$1"; MODE="$2"; KEY="${3:-ot_demo000000000000000000000}"
fail() { echo "FAIL: $*"; exit 1; }
pass() { echo "ok:   $*"; }

if [ "$MODE" != "ask-only" ]; then
  [ -s "$DIR/llms.txt" ] || fail "llms.txt missing"
  [ -s "$DIR/llms-full.txt" ] || fail "llms-full.txt missing"
  grep -q '^# Fixture Docs' "$DIR/llms.txt" || fail "llms.txt has no title"
  grep -q 'https://example.com/guide/' "$DIR/llms.txt" || fail "llms.txt has no absolute guide link"
  grep -q 'tags/' "$DIR/llms.txt" && fail "excluded tags page is in llms.txt"
  grep -q 'Step one' "$DIR/llms-full.txt" || fail "llms-full.txt has no guide content"
  grep -q 'Footer text' "$DIR/llms-full.txt" && fail "footer leaked into llms-full.txt"
  grep -q 'ask-docs.js' "$DIR/llms-full.txt" && fail "script tag leaked into llms-full.txt"
  pass "llms.txt and llms-full.txt"
else
  [ -e "$DIR/llms.txt" ] && fail "llms.txt written although llms is false"
  pass "no llms files"
fi

for f in "$DIR/index.html" "$DIR/guide/index.html"; do
  n=$(grep -o '<script[^>]*/ask-docs\.js' "$f" | wc -l | tr -d ' ')
  if [ "$MODE" = "llms-only" ]; then
    [ "$n" = "0" ] || fail "$f has $n script tags, expected 0"
  else
    [ "$n" = "1" ] || fail "$f has $n script tags, expected 1"
    grep -q 'data-ref="onetag-action"' "$f" || fail "$f has no data-ref"
    grep -q "data-key=\"$KEY\"" "$f" || fail "$f has the wrong key"
  fi
done
n=$(grep -c 'ask-docs\.js' "$DIR/tags/index.html" || true)
[ "$n" = "0" ] || fail "excluded tags page got the script tag"
pass "script tags ($MODE)"
