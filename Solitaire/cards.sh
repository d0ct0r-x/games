#!/bin/bash

cards="1;2;3;4;5"

delims="${cards//[^;]}"
total=$(( ${#delims} + 1 ))
firstCard="${cards%%;*}"
lastCard="${cards##*;}"

clear
printf "%s\n" \
"cards = $cards" \
"delims = $delims" \
"total = $total" \
"firstCard = $firstCard" \
"lastCard = $lastCard"

cut -d ';' -f '1-3' --complement <<< "$cards"