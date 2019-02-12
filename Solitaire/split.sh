#!/bin/bash
nbsp=$'\u00a0'
source="1${nbsp}2 3"

test1() {
	local source="$1"
	local delim="$2"
	array=()

	source=${source}${delim}

	while [ -n "$source" ]
	do
		array+=("${source%%${delim}*}")
		source="${source#*${delim}}"
	done
}

test2() {
	array=($source)
}

# time {
# 	for n in {1..100}
# 	do
# 		test1 "$source" ' '
# 	done
# }

# time {
# 	for n in {1..100}
# 	do
# 		test2
# 	done
# }

test2
printf '%s\n' "${array[@]}"
