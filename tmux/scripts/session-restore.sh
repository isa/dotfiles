#!/bin/sh
# Rebuild sessions/windows/panes/cwd/layout from the save file written by
# session-save.sh. Structure only — no process/program state.
#
# Layout strategy: each window's panes are created by split-window, then the
# saved window_layout string is applied with select-layout to fix geometry.
# pane-base-index=1 and panes are contiguous, so the Nth pane row maps to
# restored position N — per-pane cwd and active-pane selection line up without
# tracking pane ids (which are regenerated on restore and can't be matched).
#
# CREATE-ONLY restore: a saved session that already exists is left untouched.
# This never renames a live session — an earlier version renamed live sessions
# out of the way to dodge name collisions, and a save captured the mid-rename
# state, scrambling real sessions. Create-only can't corrupt live state.
#
# Placeholder cleanup (auto only): tmux always creates one trivial session on
# server start (the hook renames it to a random word). After restore we kill any
# session that is (a) NOT in the save and (b) trivial (≤1 pane) — i.e. only the
# placeholder. We never kill non-trivial sessions (could be real work), never
# rename anything, and skip entirely if nothing was restored (don't empty the
# server). Attached clients are switched to a restored session first. This runs
# only at server start (auto), never on manual restore.
#
# `auto` arg: from tmux.conf at server start, guarded to run once per server
# lifetime by @session-restored (resets on server exit). @session-restore-done is
# set when finished (incl. cleanup) so the save-loop knows it can safely snapshot.
# Plain invocation (manual key) always restores, with no cleanup.
export PATH=/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:/opt/homebrew/bin:$PATH

T=
for c in "$TMUX_BIN" /opt/homebrew/bin/tmux /usr/local/bin/tmux /usr/bin/tmux tmux; do
	command -v "$c" >/dev/null 2>&1 && { T="$c"; break; }
done
[ -z "$T" ] && exit 0

last="$HOME/.cache/tmux/sessions/last"
auto=0
# t(): tmux wrapper. $T unquoted so selftest's "tmux -L <sock>" splits correctly.
t() { $T "$@"; }

finish_window() {
	[ "$W_WINO" -eq 0 ] && return
	t select-layout -t "$S:$W_WINO" "$W_LAYOUT" 2>/dev/null || true
	[ -n "$W_ACTIVE_PANE" ] && t select-pane -t "$S:$W_WINO.$W_ACTIVE_PANE" 2>/dev/null || true
}
finish_session() {
	finish_window
	[ -n "$S_ACTIVE_WINO" ] && t select-window -t "$S:$S_ACTIVE_WINO" 2>/dev/null || true
}

restore_all() {
	S= W_W= W_WINO=0 W_PANES=0 W_LAYOUT= W_NAME= W_ACTIVE_PANE=
	S_EXISTS=0 S_WINO=0 S_ACTIVE_WINO=

	while IFS='|' read -r s w wname layout wactive pidx cwd pactive; do
		[ -z "$s" ] && continue
		if [ "$s" != "$S" ]; then
			finish_session
			S=$s; S_WINO=0; S_ACTIVE_WINO=; W_WINO=0; W_W=
			if t has-session -t "$s" 2>/dev/null; then S_EXISTS=1; else S_EXISTS=0; fi
		fi
		# Create-only: a session that already exists is skipped entirely.
		[ "$S_EXISTS" = "1" ] && continue
		if [ "$w" != "$W_W" ]; then
			finish_window
			W_W=$w; S_WINO=$((S_WINO+1)); W_WINO=$S_WINO; W_PANES=0; W_LAYOUT=$layout; W_NAME=$wname; W_ACTIVE_PANE=
			[ "$wactive" = "1" ] && S_ACTIVE_WINO=$W_WINO
		fi
		W_PANES=$((W_PANES+1))
		[ "$pactive" = "1" ] && W_ACTIVE_PANE=$W_PANES

		if [ "$W_WINO" -eq 1 ] && [ "$W_PANES" -eq 1 ]; then
			t new-session -d -s "$s" -c "$cwd"           # first pane of the session
		elif [ "$W_PANES" -eq 1 ]; then
			t new-window -t "$s" -c "$cwd"               # first pane of a later window
		else
			t split-window -t "$s" -c "$cwd"             # extra pane in the active window
		fi
		# Apply the saved window name to each freshly created window.
		[ "$W_PANES" = "1" ] && [ -n "$W_NAME" ] && t rename-window -t "$s:$W_WINO" "$W_NAME" 2>/dev/null || true
	done < "$last"
	finish_session
}

# Remove the throwaway startup session. Kills ONLY trivial (≤1 pane) sessions
# whose name isn't in the save, and only if at least one saved session was
# restored (never empty the server). No renaming; non-trivial sessions are
# always spared (they may be real work). Clients are moved off first.
cleanup_placeholder() {
	[ "$auto" = 1 ] || return
	[ -f "$last" ] || return
	saved_list="${last}.saved.$$"
	awk -F'|' '!seen[$1]++{print $1}' "$last" > "$saved_list" 2>/dev/null
	# first restored (saved) session to land any attached client on
	first=$(t list-sessions -F '#{session_name}' 2>/dev/null | while IFS= read -r s; do
		grep -qxF "$s" "$saved_list" && { echo "$s"; break; }
	done)
	[ -n "$first" ] || { rm -f "$saved_list"; return; }
	t list-sessions -F '#{session_name}' 2>/dev/null | while IFS= read -r s; do
		grep -qxF "$s" "$saved_list" && continue          # in the save — keep
		panes=$(t list-panes -s -t "$s" -F '#' 2>/dev/null | wc -l | tr -d ' ')
		[ "${panes:-0}" -le 1 ] || continue               # non-trivial — keep
		t list-clients -F '#{client_name}|#{session_name}' 2>/dev/null | while IFS='|' read -r cn sn rest; do
			[ "$sn" = "$s" ] && t switch-client -c "$cn" -t "$first" 2>/dev/null
		done
		t kill-session -t "$s" 2>/dev/null
	done
	rm -f "$saved_list"
}

# --- selftest: save 'alpha', restart, restore on a server that also has a
# trivial placeholder AND a non-trivial session not in the save. Assert the
# placeholder is removed, alpha is restored, and the non-trivial session survives.
# Run: scripts/session-restore.sh --selftest
if [ "${1:-}" = "--selftest" ]; then
	command -v tmux >/dev/null 2>&1 || { echo "FAIL: tmux not in PATH"; exit 1; }
	sock="persist-selftest"; save="/tmp/$sock.save"
	trap 'tmux -L "$sock" kill-server 2>/dev/null; rm -f "$save"' EXIT
	# Start the test server with -f /dev/null so the user's real tmux.conf (and its
	# hooks: lowername, save-loop, auto-restore) do NOT load on it, then set the
	# same options the conf does so indices line up with the restore assumptions.
	# init_opts: start an ISOLATED server (-f /dev/null → no user conf/hooks) and
	# set the options the conf does, so indices line up with restore's assumptions.
	# _opt is left alive (killing the only session destroys the server, after which
	# the next new-session would start a conf-loaded server); the caller kills it
	# once a real session exists.
	init_opts() {
		tmux -L "$sock" -f /dev/null new-session -d -s _opt -c /tmp 2>/dev/null
		tmux -L "$sock" set -g base-index 1
		tmux -L "$sock" set -g default-shell /bin/sh
		tmux -L "$sock" setw -g pane-base-index 1
		tmux -L "$sock" setw -g automatic-rename off
		tmux -L "$sock" setw -g allow-rename off
	}
	tmux -L "$sock" kill-server 2>/dev/null || true
	init_opts
	# alpha: w1 has 2 panes (/tmp), w2 has 1 pane (/usr) — the "real" session
	tmux -L "$sock" new-session -d -s alpha -c /tmp
	tmux -L "$sock" kill-session -t _opt 2>/dev/null
	tmux -L "$sock" split-window -t alpha -c /tmp
	tmux -L "$sock" resize-pane -t alpha:1.1 -y 5      # clearly asymmetric (default is ~50/50), so a broken select-layout would fail the assertion
	tmux -L "$sock" new-window -t alpha -c /usr
	tmux -L "$sock" rename-window -t alpha:1 winA
	tmux -L "$sock" rename-window -t alpha:2 winB
	exp_w=$(tmux -L "$sock" list-windows -t alpha -F '#{window_index}' | wc -l | tr -d ' ')
	exp_p=$(tmux -L "$sock" list-panes -s -t alpha -F '#{pane_index}' | wc -l | tr -d ' ')
	# capture window 1's pane geometry (size+position) to assert it round-trips
	exp_geom=$(tmux -L "$sock" list-panes -t alpha:1 -F '#{pane_width}x#{pane_height}+#{pane_left}+#{pane_top}' | tr '\n' ',')
	tmux -L "$sock" list-panes -a -F '#{session_name}|#{window_index}|#{window_name}|#{window_layout}|#{window_active}|#{pane_index}|#{pane_current_path}|#{pane_active}' > "$save"
	tmux -L "$sock" kill-server
	# fresh server: a trivial placeholder + a non-trivial session NOT in the save
	init_opts
	tmux -L "$sock" new-session -d -s placeholder -c "$HOME"
	tmux -L "$sock" kill-session -t _opt 2>/dev/null
	tmux -L "$sock" new-session -d -s realwork -c "$HOME"
	tmux -L "$sock" split-window -t realwork -c "$HOME"   # 2 panes → non-trivial
	T="tmux -L $sock"; last="$save"; auto=1
	t set -g @session-restored 1
	restore_all
	cleanup_placeholder
	t set -g @session-restore-done 1
	got_w=$(tmux -L "$sock" list-windows -t alpha -F '#{window_index}' 2>/dev/null | wc -l | tr -d ' ')
	got_p=$(tmux -L "$sock" list-panes -s -t alpha -F '#{pane_index}'  2>/dev/null | wc -l | tr -d ' ')
	got_geom=$(tmux -L "$sock" list-panes -t alpha:1 -F '#{pane_width}x#{pane_height}+#{pane_left}+#{pane_top}' 2>/dev/null | tr '\n' ',')
	has_usr=$(tmux -L "$sock" list-panes -s -t alpha -F '#{pane_current_path}' 2>/dev/null | grep -c '^/usr$')
	name1=$(tmux -L "$sock" display -p -t alpha:1 '#{window_name}' 2>/dev/null)
	name2=$(tmux -L "$sock" display -p -t alpha:2 '#{window_name}' 2>/dev/null)
	ph_gone=$(tmux -L "$sock" has-session -t placeholder 2>/dev/null && echo 0 || echo 1)
	rw_kept=$(tmux -L "$sock" has-session -t realwork 2>/dev/null && echo 1 || echo 0)
	rw_panes=$(tmux -L "$sock" list-panes -s -t realwork -F '#' 2>/dev/null | wc -l | tr -d ' ')
	tmux -L "$sock" kill-server 2>/dev/null || true
	rm -f "$save"
	if [ "$got_w" = "$exp_w" ] && [ "$got_p" = "$exp_p" ] && [ "$has_usr" = "1" ] \
		&& [ "$name1" = "winA" ] && [ "$name2" = "winB" ] \
		&& [ "$exp_geom" = "$got_geom" ] \
		&& [ "$ph_gone" = "1" ] && [ "$rw_kept" = "1" ] && [ "$rw_panes" = "2" ]; then
		echo "PASS: alpha $got_w/$got_p restored, names [$name1/$name2], layout [$got_geom], placeholder removed, realwork spared"
		exit 0
	fi
	echo "FAIL: alpha exp $exp_w/$exp_p got $got_w/$got_p /usr=$has_usr names=$name1/$name2 geom exp=[$exp_geom] got=[$got_geom] ph_gone=$ph_gone rw=$rw_kept($rw_panes)"
	exit 1
fi

# --- main ---
[ "${1:-}" = "auto" ] && auto=1
if [ "$auto" = 1 ]; then
	[ -n "$(t show -gv @session-restored 2>/dev/null)" ] && exit 0
	t set -g @session-restored 1
fi
if [ -f "$last" ]; then
	restore_all
	cleanup_placeholder
fi
[ "$auto" = 1 ] && t set -g @session-restore-done 1
exit 0
