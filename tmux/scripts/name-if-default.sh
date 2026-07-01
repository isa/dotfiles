#!/bin/sh

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
random_name() { "$script_dir/random-name.sh"; }

case "$1" in
session)
	target="${2:-}"
	if [ -n "$target" ]; then
		name=$(tmux display-message -p -t "$target" '#{session_name}')
	else
		name=$(tmux display-message -p '#{session_name}')
	fi
	case "$name" in
	'' | *[!0-9]*) exit 0 ;;
	esac
	if [ -n "$target" ]; then
		tmux rename-session -t "$target" "$(random_name)"
	else
		tmux rename-session "$(random_name)"
	fi
	;;
window)
	name=$(tmux display-message -p '#W')
	case "$name" in
	'' | [0-9] | [0-9][0-9] | zsh | bash | fish | sh | login | ssh | node | python | python3 | ruby | irb | nvim | vim | htop | man)
		tmux rename-window "$(random_name)"
		;;
	esac
	;;
esac
