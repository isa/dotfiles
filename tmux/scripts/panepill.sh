#!/bin/sh
# panepill.sh <window_id> — one connected, segmented pill for a window's panes.
#
# status-format[0] can't build this: #{P:...} walks panes one at a time with no
# notion of position or neighbours, so it can't colour the end caps from the
# first/last pane, nor pick a separator based on whether two adjacent panes share
# a colour. This script sees every pane at once, so it can:
#   - left cap  = first pane's colour, right cap = last pane's colour
#     (an active edge pane thus gets an amber cap)
#   - inactive panes fade gray -> a lighter grey across the run, so the rounded
#     caps between them read (a cap on identical grey is invisible); a boundary
#     touching the active pane gets an amber rounded cap on both sides, so the
#     active block stays one clean shape. No angled separators anywhere.
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
	gray=#a9b1d6 g2=#c0caf5 amber=#e0af68 ink=#1f2335
else
	gray=#8990b3 g2=#a9b1d6 amber=#e0af68 ink=#1f2335
fi

# glyphs passed as -v values (raw UTF-8 bytes; awk -v only touches backslash
# escapes, which these high bytes are not, so they pass through untouched).
"$T" list-panes -t "$win" -F '#{pane_index} #{pane_active}' 2>/dev/null | sort -n | awk \
  -v amber="$amber" -v gray="$gray" -v ink="$ink" -v g2="$g2" \
  -v LC='' -v RC='' '
	BEGIN {
		N = 0
		split("0 1 2 3 4 5 6 7 8 9 a b c d e f", _x, " ")
		for (_i = 0; _i < 16; _i++) HEX[_x[_i+1]] = _i
		gr = byte(gray,2); gg = byte(gray,4); gb = byte(gray,6)
		lr = byte(g2,2);   lg = byte(g2,4);   lb = byte(g2,6)
	}
	# hex byte at pos p of "#rrggbb" -> 0..255 (BSD awk has no strtonum)
	function byte(s,p){ return HEX[tolower(substr(s,p,1))]*16 + HEX[tolower(substr(s,p+1,1))] }
	function lerp(a,b,t){ return a + (b-a)*t }
	function clamp(v){ v = v < 0 ? 0 : (v > 255 ? 255 : v); return int(v + 0.5) }
	{ idx[N]=$1; act[N]=($2==1); N++ }
	END {
		if (N <= 1) exit
		# inactive panes fade gray -> g2 across their run, so the rounded caps
		# between them read (a cap on identical grey is invisible).
		ni = 0; for (i = 0; i < N; i++) if (!act[i]) ni++
		k = 0
		for (i = 0; i < N; i++) {
			if (act[i]) col[i] = amber
			else {
				t = ni > 1 ? k/(ni-1) : 0
				col[i] = sprintf("#%02x%02x%02x", clamp(lerp(gr,lr,t)), clamp(lerp(gg,lg,t)), clamp(lerp(gb,lb,t)))
				k++
			}
		}
		printf("#[fg=%s]#[bg=default]%s", col[0], LC)
		for (i = 0; i < N; i++) {
			if (i > 0) {
				# active owns both caps (amber); the inactive run uses a rounded
				# grey cap (prev shade flowing into cur) at every join.
				if (act[i])        printf("#[fg=%s]#[bg=%s]%s", amber, col[i-1], LC)
				else if (act[i-1]) printf("#[fg=%s]#[bg=%s]%s", amber, col[i], RC)
				else               printf("#[fg=%s]#[bg=%s]%s", col[i-1], col[i], RC)
			}
			printf("#[bg=%s]#[fg=%s] %s ", col[i], ink, idx[i])
		}
		printf("#[fg=%s]#[bg=default]%s#[default]", col[N-1], RC)
	}'
