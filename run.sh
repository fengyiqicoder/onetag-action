#!/usr/bin/env bash
# Runs inside the composite action. Inputs arrive as INPUT_* env variables (see action.yml).
set -euo pipefail

PKG="static-llms-txt@0.1.0"
HERE="${GITHUB_ACTION_PATH:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
export npm_config_registry="https://registry.npmjs.org"
export npm_config_update_notifier=false
export npm_config_fund=false

DIR="${INPUT_PATH:-}"
if [ -z "$DIR" ]; then
  echo "::error title=OneTag AI::The path input is required (the folder with the built site)."
  exit 1
fi
if [ ! -d "$DIR" ]; then
  echo "::error title=OneTag AI::Folder not found: $DIR. Run this step after the site build."
  exit 1
fi

on() { case "$(echo "${1:-}" | tr '[:upper:]' '[:lower:]')" in false|0|no|off) return 1 ;; *) return 0 ;; esac; }

# Exclude globs: one per line or comma separated.
EXCLUDE_ARGS=()
while IFS= read -r glob; do
  glob="$(echo "$glob" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
  [ -n "$glob" ] && EXCLUDE_ARGS+=(--exclude "$glob")
done < <(printf '%s\n' "${INPUT_EXCLUDE:-}" | tr ',' '\n')

if on "${INPUT_LLMS:-true}"; then
  ARGS=("$DIR")
  [ -n "${INPUT_SITE:-}" ] && ARGS+=(--site "$INPUT_SITE")
  npx --yes "$PKG" "${ARGS[@]}" ${EXCLUDE_ARGS[@]+"${EXCLUDE_ARGS[@]}"}
fi

if on "${INPUT_ASK_AI:-true}"; then
  # The CLI's --ask-ai has no flags for ref, label, position, color or lang,
  # so this calls the same package's inject() API.
  npx --yes --package "$PKG" -- node "$HERE/inject.cjs"
fi

if ! on "${INPUT_LLMS:-true}" && ! on "${INPUT_ASK_AI:-true}"; then
  echo "::notice title=OneTag AI::Both llms and ask-ai are false, so nothing was changed."
fi
