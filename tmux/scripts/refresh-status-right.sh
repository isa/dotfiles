#!/bin/sh
# Sets @other_sessions_pills only — never write raw #[#hex] into status-right (tmux treats # as a comment).

current="${1:-$(tmux display-message -p '#{client_session}' 2>/dev/null)}"
[ -z "$current" ] && current=$(tmux display-message -p '#{session_name}' 2>/dev/null)
[ -z "$current" ] && exit 0

icon=" "
left_sep=""
right_sep=""

result=""
first=1

while IFS= read -r name; do
	[ -z "$name" ] && continue
	[ "$name" = "$current" ] && continue

	[ "$first" -eq 0 ] && result="$result "

	result="${result}#[fg=#{@_ctp_status_bg},reverse]${left_sep}#[none]"
	result="${result}#[fg=#{@thm_crust},bg=#{@thm_overlay_1}]${icon}"
	result="${result}#[fg=#{@thm_fg},bg=#{@thm_surface_0}] ${name}"
	result="${result}#[fg=#{@thm_surface_0}]#[fg=#{@_ctp_status_bg},reverse]${right_sep}#[none]"

	first=0
done <<EOF
$(tmux list-sessions -F '#{session_name}' 2>/dev/null)
EOF

tmux set-option -gq @other_sessions_pills "$result"
