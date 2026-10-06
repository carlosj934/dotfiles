#!/usr/bin/env bash

# Move the active herdr tab left/right via the `tab.move` socket method (needs jq and nc).

set -euo pipefail

dir="${1:?usage: move-tab.sh <left|right>}"
herdr="${HERDR_BIN_PATH:-herdr}"
sock="${HERDR_SOCKET_PATH:-$HOME/.config/herdr/herdr.sock}"
tab="${HERDR_ACTIVE_TAB_ID:-}"
ws="${HERDR_ACTIVE_WORKSPACE_ID:-}"

[ -n "$tab" ] && [ -n "$ws" ] || exit 0

read -r pos count < <(
  "$herdr" tab list --workspace "$ws" \
    | jq -r --arg t "$tab" '.result.tabs | "\(map(.tab_id) | index($t)) \(length)"'
)

[ "$pos" != "null" ] || exit 0

# insert_index inserts before that slot in the pre-move list, so moving right needs pos+2.
case "$dir" in
  left)  [ "$pos" -gt 0 ] || exit 0; target=$((pos - 1)) ;;
  right) [ "$pos" -lt $((count - 1)) ] || exit 0; target=$((pos + 2)) ;;
  *) echo "move-tab.sh: unknown direction: $dir" >&2; exit 2 ;;
esac

printf '{"id":"move-tab","method":"tab.move","params":{"tab_id":"%s","insert_index":%d}}\n' \
  "$tab" "$target" | nc -U "$sock" >/dev/null
