#!/bin/sh

adjectives="amber bold calm dark eager fast grand happy icy jade keen lazy mild neat open pale quick red sage teal ultra vivid warm zen"
nouns="apex bear cave delta echo falcon grove harbor iris jet kestrel lake maple nest oak pine quill ridge storm tulip ukule vega wolf yarn zephyr"

pick() {
	words=$1
	offset=${2:-0}
	set -- $words
	count=$#
	seed=$(($(date +%s) + $$ + offset))
	idx=$((seed % count + 1))
	eval echo \${$idx}
}

words="$adjectives $nouns"
printf '%s\n' "$(pick "$words" 0)" | /usr/bin/tr '[:lower:]' '[:upper:]'
