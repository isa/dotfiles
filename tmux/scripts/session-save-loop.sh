#!/bin/sh
# Auto-save loop. Fires every SESSION_SAVE_INTERVAL seconds (default 900 = 15 min).
# pidfile-guards against stacking: tmux re-runs run-shell on every `prefix r`
# reload, so without a guard each reload would spawn another never-ending loop.
# If a loop is already alive, this invocation exits. Stale pidfile (server died,
# loop orphaned/killed) fails the kill -0 check and lets a fresh loop start.
#
# Before the FIRST save we wait (bounded) for @session-restore-done: auto-restore
# runs at server start and removes the throwaway placeholder session; saving
# before that completes would snapshot the placeholder and make it permanent.
# If auto-restore isn't configured (manual-only mode), the flag never appears and
# we proceed after the timeout.
# ponytail: one shared cache/pid assumes a single tmux server; per-socket pidfile
# if a multi-socket setup ever needs it.
export PATH=/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:/opt/homebrew/bin:$PATH

T=
for c in "$TMUX_BIN" /opt/homebrew/bin/tmux /usr/local/bin/tmux /usr/bin/tmux tmux; do
	command -v "$c" >/dev/null 2>&1 && { T="$c"; break; }
done
[ -z "$T" ] && exit 0

dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
cache="$HOME/.cache/tmux/sessions"
pid="$cache/save-loop.pid"
mkdir -p "$cache"
[ -f "$pid" ] && kill -0 "$(cat "$pid" 2>/dev/null)" 2>/dev/null && exit 0
echo $$ > "$pid"

# Wait (≤30s) for restore to finish its placeholder cleanup before first save.
i=0
while [ "$i" -lt 30 ]; do
	[ -n "$($T show -gv @session-restore-done 2>/dev/null)" ] && break
	i=$((i+1)); sleep 1
done

interval=${SESSION_SAVE_INTERVAL:-900}
while :; do
	"$dir/session-save.sh" || true
	sleep "$interval"
done
