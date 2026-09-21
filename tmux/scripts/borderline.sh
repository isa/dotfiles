#!/bin/sh
# borderline.sh <window_id> — emit a full-width transparent status line with a
# box-drawing │ at every vertical pane-border column, so pane borders appear to
# continue up through the status gap row toward the top of the window.
#
# tmux draws pane borders only inside the pane region — it can't extend them
# into the status area (separate rendering, no option for it). This mimics the
# extension for status-format[1] (the gap row directly above the panes): same
# column as the real border below, same colour, so the eye reads one line.
#
# A column c is a vertical border iff some pane's right edge is c-1 and another
# pane's left edge is c+1 (the 1-col border sits between them). We draw every
# such column; a border that does not reach the top of the pane area would
# leave a floating stub in the gap, but ordinary splits reach the top, so we
# keep it simple rather than filter by pane_top. Horizontal borders are ignored
# (only verticals matter for reaching the top).
win="${1:-}"

# Locate tmux (minimal PATH from #(), same dance as the other scripts).
T=
for c in "$TMUX_BIN" /opt/homebrew/bin/tmux /usr/local/bin/tmux /usr/bin/tmux tmux; do
	command -v "$c" >/dev/null 2>&1 && { T="$c"; break; }
done
[ -z "$T" ] && exit 0

W=$("$T" display -t "$win" -p '#{window_width}' 2>/dev/null)
[ -z "$W" ] && exit 0

BAR=$(printf '\342\224\202')   # U+2502 box-drawing light vertical (pane-border-lines single)
COL=#3b4261                    # matches pane-border-style

"$T" list-panes -t "$win" -F '#{pane_left} #{pane_right}' 2>/dev/null | awk -v W="$W" -v BAR="$BAR" -v COL="$COL" '
	{ L[$1]=1; R[$2]=1 }
	END {
		if (W < 1) exit
		out = ""
		for (c = 0; c < W; c++)
			out = out ((R[c-1] && L[c+1]) ? BAR : " ")
		printf "#[fg=%s,bg=default]%s", COL, out
	}'
