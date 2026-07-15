#!/bin/sh
# Snapshot every pane so sessions can be rebuilt after a server restart.
# One row per pane, pipe-delimited (no field contains '|'):
#   session|window_idx|window_name|window_layout|window_active|pane_idx|cwd|pane_active
# ponytail: structure+cwd+layout only — no process/program state (that's
# resurrect's expensive 10%). Atomic write via tmp+mv. Output is cache, not
# config: regenerable, deliberately not part of the dotfiles copy.
# PATH set because run-shell may spawn us with a minimal environment.
export PATH=/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:/opt/homebrew/bin:$PATH

T=
for c in "$TMUX_BIN" /opt/homebrew/bin/tmux /usr/local/bin/tmux /usr/bin/tmux tmux; do
	command -v "$c" >/dev/null 2>&1 && { T="$c"; break; }
done
[ -z "$T" ] && exit 0

cache="$HOME/.cache/tmux/sessions"
mkdir -p "$cache"
# $T unquoted: a bare binary path has no spaces, and selftest sets T="tmux -L sock".
$T list-panes -a -F \
	'#{session_name}|#{window_index}|#{window_name}|#{window_layout}|#{window_active}|#{pane_index}|#{pane_current_path}|#{pane_active}' \
	> "$cache/last.tmp"
mv "$cache/last.tmp" "$cache/last"
exit 0
