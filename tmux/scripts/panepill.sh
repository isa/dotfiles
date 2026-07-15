#!/bin/sh
# panepill.sh <window_id> — one connected, segmented pill for a window's panes.
#
# status-format[0] can't build this: #{P:...} walks panes one at a time with no
# notion of position or neighbours, so it can't colour the end caps from the
# first/last pane, nor pick a separator based on whether two adjacent panes share
# a colour. This script sees every pane at once, so it can:
#   - left cap  = first pane's colour, right cap = last pane's colour
#     (an active edge pane thus gets an amber cap)
#   - solid powerline slant at a colour change (smooth gray<->amber),
#     thin slant between same-colour passive blocks (no ASCII "|")
# Panes are sorted by index, so first/last stay correct even when closing a pane
# leaves index gaps (tmux doesn't renumber panes). Output is #[]-styled text,
# re-parsed by tmux for styles. Lone-pane windows are gated out by the caller
# (#{!=:#{window_panes},1}) and double-guarded here.
#
# Palette is theme-aware: an explicit @panepill-theme (light|dark|auto) wins,
# otherwise we follow the macOS appearance (ghostty tracks it on this machine),
# since tmux can't itself read the terminal's background colour. Light uses a
# lighter gray block + dark ink for contrast on a light bg; if the auto pick is
# ever wrong, `tmux set -g @panepill-theme dark` (or light) forces it.
win="${1:-}"

# Locate tmux — #() may hand us a minimal PATH (same dance as lowername.sh).
T=
for c in "$TMUX_BIN" /opt/homebrew/bin/tmux /usr/local/bin/tmux /usr/bin/tmux tmux; do
	command -v "$c" >/dev/null 2>&1 && { T="$c"; break; }
done
[ -z "$T" ] && exit 0

theme=$("$T" show-options -g -v @panepill-theme 2>/dev/null)
if [ -z "$theme" ] || [ "$theme" = auto ]; then
	if [ "$(defaults read -g AppleInterfaceStyle 2>/dev/null)" = "Dark" ]; then
		theme=dark
	else
		theme=light
	fi
fi
if [ "$theme" = light ]; then
	gray=#8990b3 amber=#e0af68 ink=#1f2335 div=#5b6388
else
	gray=#565f89 amber=#e0af68 ink=#1f2335 div=#3b4261
fi

# glyphs passed as -v values (raw UTF-8 bytes; awk -v only touches backslash
# escapes, which these high bytes are not, so they pass through untouched).
"$T" list-panes -t "$win" -F '#{pane_index} #{pane_active}' 2>/dev/null | sort -n | awk \
  -v amber="$amber" -v gray="$gray" -v ink="$ink" -v div="$div" \
  -v LC='' -v RC='' -v SLD='' -v THN='' '
	BEGIN { N=0 }
	{ idx[N]=$1; act[N]=($2==1); N++ }
	END {
		if (N <= 1) exit
		printf("#[fg=%s]#[bg=default]%s", act[0] ? amber : gray, LC)
		for (i = 0; i < N; i++) {
			c = act[i] ? amber : gray
			if (i > 0) {
				pv = act[i-1] ? amber : gray
				if (c == pv) printf("#[fg=%s]#[bg=%s]%s", div, pv, THN)
				else        printf("#[fg=%s]#[bg=%s]%s", pv, c, SLD)
			}
			printf("#[bg=%s]#[fg=%s] %s ", c, ink, idx[i])
		}
		printf("#[fg=%s]#[bg=default]%s#[default]", act[N-1] ? amber : gray, RC)
	}'
