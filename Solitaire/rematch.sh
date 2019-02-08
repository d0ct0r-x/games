#!/bin/bash

current=0
previous=1

cycle() {
	playerHistory=("$1" ${playerHistory[0]})
	printf "'%s'" "${playerHistory[@]}"
	echo
}

cycle A
cycle B
cycle C
