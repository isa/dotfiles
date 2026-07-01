#!/bin/sh
# Name the window containing pane $1 after the lowercased basename of its path.
# Driven by tmux hooks (set-hook pane-focus-in). We avoid #{...} inside #(...),
# which is unreliable in this tmux build, by passing only the pane id and
# querying the path via tmux ourselves.
pane="$1"
[ -z "$pane" ] && exit 0

# Locate the tmux binary — run-shell may spawn us with a minimal PATH.
T=
for c in "$TMUX_BIN" /opt/homebrew/bin/tmux /usr/local/bin/tmux /usr/bin/tmux tmux; do
	command -v "$c" >/dev/null 2>&1 && { T="$c"; break; }
done
[ -z "$T" ] && exit 0

path=$("$T" display-message -p -t "$pane" '#{pane_current_path}' 2>/dev/null)
[ -z "$path" ] && exit 0

name=$(/usr/bin/basename "$path" | /usr/bin/tr '[:upper:]' '[:lower:]')
"$T" rename-window -t "$pane" "$name" 2>/dev/null
exit 0
