#!/bin/bash
colorReset='\033[0m'
underline='\033[4m'
play='\033[5m'

colorBgWhite='\033[107m'
colorBgBlack='\033[40m'
colorBgGrey='\033[100m'
colorBgBlue='\033[44m'
colorBgRed='\033[41m'
colorBgLightRed='\033[101m'
colorBgLightGrey='\033[47m'
colorBgDarkGrey='\033[100m'
colorBgGreen='\033[42m'
colorBgLightYellow='\033[103m'
colorBgLightCyan='\033[106m'

colorFgBlack='\033[30m'
colorFgWhite='\033[97m'
colorFgRed='\033[31m'
colorFgCyan='\033[36m'
colorFgLightRed='\033[91m'
colorFgLightGrey='\033[37m'
colorFgDarkGrey='\033[90m'
colorFgGreen='\033[32m'
colorFgLightGreen='\033[92m'
colorFgLightYellow='\033[93m'
colorFgLightPink='\033[95m'
colorFgLightCyan='\033[96m'

cardFaceUpColor="$colorBgWhite"
cardHeartColor="$colorFgRed"
cardSpadeColor="$colorFgBlack"
cardFaceDownColor="${colorFgLightGrey}${colorBgBlue}"
cardSpaceColor="$colorFgLightGrey"
cardEdgeColor="${colorFgBlack}${colorBgWhite}"
cardShadowColor="${colorBgLightGrey}"
cursorColor="${colorFgLightGreen}"

rank=(A 2 3 4 5 6 7 8 9 10 J Q K)
suit=(♥ ♣ ♦ ♠)
cardFaceUp=(
	'1>  ♥'
	'     '
	'♥  <1'
)
cardFaceDownPattern='╳'
cardSpaceTopLeft='╭'
cardSpaceTopRight='╮'
cardSpaceBottomLeft='╰'
cardSpaceBottomRight='╯'
cardSpaceHorizontal='─'
cardSpaceVertical='│'
cardEdge='│'
cursor1=(
	'╔═'
	'║ '
	'╚═'
)

rankTotal="${#rank[@]}"
suitTotal="${#suit[@]}"
cardTotal="$(( rankTotal * suitTotal ))"
cardHeight="${#cardFaceUp[@]}"
cardWidth="${#cardFaceUp[1]}"

debugObjects() {
	objectTotal="${#objectText[@]}"

	for (( n = 0; n <= objectTotal; n++ ))
	do
		printf '%s\n' "${objectText[n]}  ${objectColor[n]}"
	done
}

createObjects() {
	createDeck
	createCardSpace
	createCardEdge
	createCardShadow
	createCursor
}

createDeck() {
	local s r

	deck=({1.."$cardTotal"})
	cardRank=(-1)
	cardSuit=(-1)
	createFaceDownCard

	for (( s = 0; s < suitTotal; s++ ))
	do
		for (( r = 0; r < rankTotal; r++ ))
		do
			cardRank+=("$r")
			cardSuit+=("$s")
			createFaceUpCard
		done
	done
}

createFaceDownCard() {
	local h w object

	for (( h = 0; h < cardHeight; h++ ))
	do
		for (( w = 0; w < cardWidth; w++ ))
		do
			object+="$cardFaceDownPattern"
		done

		object+=';'
	done

	objectText+=("${object%;}")
}

createFaceUpCard() {
	local rankString rpad lpad n line object

	rankString="${rank[r]}"
	(( r == 9 )) && rpad=10 || rpad="$rankString "
	(( r == 9 )) && lpad=10 || lpad=" $rankString"

	for (( n = 0; n < cardHeight; n++ ))
	do
		line="${cardFaceUp[n]}"
		line="${line/1>/$rpad}"
		line="${line/<1/$lpad}"
		line="${line/♥/${suit[s]}}"

		object+="${line};"
	done

	objectText+=("${object%;}")
}

createCardSpace() {
	local h w object

	for (( h = 0; h < cardHeight; h++ ))
	do
		for (( w = 0; w < cardWidth; w++ ))
		do
			if (( h == 0 && w == 0 ))
			then
				object+="$cardSpaceTopLeft"
			elif (( h == 0 && w == cardWidth - 1 ))
			then
				object+="$cardSpaceTopRight"
			elif (( h == cardHeight - 1 && w == 0 ))
			then
				object+="$cardSpaceBottomLeft"
			elif (( h == cardHeight - 1 && w == cardWidth - 1 ))
			then
				object+="$cardSpaceBottomRight"
			elif (( h == 0 || h == cardHeight - 1))
			then
				object+="$cardSpaceHorizontal"
			elif (( w == 0 || w == cardWidth - 1))
			then
				object+="$cardSpaceVertical"
			else
				object+=" "
			fi
		done

		object+=';'
	done

	objectText+=("${object%;}")

	cardSpaceId="$(( ${#objectText[@]} - 1 ))"
}

createCardEdge() {
	local h object

	for (( h = 0; h < cardHeight; h++ ))
	do
		object+="${cardEdge};"
	done

	objectText+=("${object%;}")

	cardEdgeId="$(( ${#objectText[@]} - 1 ))"
}

createCardShadow() {
	local h w object

	for (( h = 0; h < cardHeight; h++ ))
	do
		for (( w = 0; w < cardWidth; w++ ))
		do
			object+=" "
		done

		object+=';'
	done

	objectText+=("${object%;}")

	cardShadowId="$(( ${#objectText[@]} - 1 ))"
}

createCursor() {
	local n object

	for (( n = 0; n < cardHeight; n++ ))
	do
		object+="${cursor1[n]};"
	done

	objectText+=("${object%;}")

	cursorId="$(( ${#objectText[@]} - 1 ))"
}

setColors() {
	local n

	objectColor[0]="$cardFaceDownColor"

	for (( n = 1; n <= cardTotal; n++ ))
	do
		objectColor[n]="$cardFaceUpColor"
		(( cardSuit[n] % 2 == 0 )) && objectColor[n]+="$cardHeartColor" || objectColor[n]+="$cardSpadeColor"
	done

	objectColor[cardSpaceId]="$cardSpaceColor"
	objectColor[cardEdgeId]="$cardEdgeColor"
	objectColor[cursorId]="$cursorColor"
	objectColor[cardShadowId]="$cardShadowColor"
}

draw() {
    buffer+="\033[${2};${1}H${3}"
}

drawObject() {
	local x="$1"
	local y="$2"
	local color="$3"
	local lines n

	IFS=';' lines=($4)
	local linesTotal="${#lines[@]}"

	for (( n = 0; n < linesTotal; n++ ))
	do
		draw "$x" "$y" "${color}${lines[n]}${colorReset}"
		(( y++ ))
	done
}

drawCard() {
	local color="${objectColor[$3]}"

	[[ "$4" = 'h' ]] && color+="$underline"

	drawObject "$1" "$2" "$color" "${objectText[$3]}"

	if [[ "$4" = 'v' ]]
	then
	    drawCardEdge "$(( $1 + 2 ))" "$2"
	fi
}

drawCardSpace() {
	drawObject "$1" "$2" "${objectColor[cardSpaceId]}" "${objectText[cardSpaceId]}"
}

drawCardEdge() {
	drawObject "$1" "$2" "${objectColor[cardEdgeId]}" "${objectText[cardEdgeId]}"
}

drawCardShadow() {
	drawObject "$1" "$2" "${objectColor[cardShadowId]}" "${objectText[cardShadowId]}"
}

clear

createObjects
setColors

draw 1 1 "$colorFullBgGreen"
printf "$buffer"
buffer=

drawCard 3 2 0
drawCard 10 2 45 v && drawCard 13 2 23 v && drawCard 16 2 18
# drawCard 17 2 0
drawCard 24 2 1
drawCardSpace 31 2
drawCard 38 2 27
drawCard 46 2 40

drawCard 3 6 22
drawCard 10 6 0 && drawCard 10 7 1
drawCard 17 6 0 && drawCard 17 7 6 && drawCard 17 8 16 && drawCard 17 9 36
drawCard 24 6 0 h && drawCard 24 7 0
drawCard 31 6 0
drawCard 38 6 0

drawCard 38 7 13
drawCard 38 8 12
drawCard 38 9 11
drawCard 38 10 10
drawCard 38 11 9
drawCard 38 12 8
drawCard 38 13 7
drawCard 38 14 6
drawCard 38 15 5
drawCard 38 16 4
drawCard 38 17 3
drawCard 38 18 2

drawCard 46 6 0 h
drawCard 46 7 0 h
drawCard 46 8 0 h
drawCard 46 9 0 h
drawCard 46 10 0 h
drawCard 46 11 0 h

drawCard 46 12 13 h
drawCard 46 13 12 h
drawCard 46 14 11 h
drawCard 46 15 23 h
drawCard 46 16 9 h
drawCard 46 17 8 h
drawCard 46 18 7 h
drawCard 46 19 6 h

drawCard 46 20 5 h
drawCard 46 21 4 h
drawCard 46 22 3 h
drawCard 46 23 2

draw 15 10 "${colorFgLightGrey}┏${colorReset}"
draw 15 12 "${colorFgLightGrey}┗${colorReset}"
draw 23 10 "${colorFgLightGrey}┓${colorReset}"
draw 23 12 "${colorFgLightGrey}┛${colorReset}"

draw 44 23 "${colorFgLightYellow}▶${colorReset}"
draw 52 23 "${colorFgLightYellow}◀${colorReset}"
draw 45 27 "${colorFgLightYellow}┗━━━━━┛${colorReset}"
drawCard 17 10 5

# divider="${colorFgBlack}${colorBgWhite}│${colorReset}"
# drawXY 12 2 "$divider" && drawXY 12 3 "$divider" && drawXY 12 4 "$divider"
# drawXY 15 2 "$divider" && drawXY 15 3 "$divider" && drawXY 15 4 "$divider"

# numCards="${cardFaceDownFgColor}${cardFaceDownBgColor}┌─3─┐${colorReset}"
# drawXY 17 6 "$numCards"
# drawXY 31 6 "$numCards"


drawCard 7 15 43
drawCard 7 16 36
# draw 47 28  "${colorFgLightYellow}╭╮${colorReset}"
# draw 47 29  "${colorFgLightYellow}│├┬┬╮${colorReset}"
# draw 46 30 "${colorFgLightYellow}╭┤   │${colorReset}"
# draw 46 31 "${colorFgLightYellow}╰╮  ╭╯${colorReset}"

printf "$buffer\n"
read -rsn 1
buffer=

drawCard 17 9 36
draw 17 12 " "
draw 17 11 "${colorBgLightGrey}${colorFgRed}♦${colorReset}"
draw 17 10 "${colorBgLightGrey} ${colorReset}"
draw 18 10 "${colorBgLightGrey} ${colorReset}"
draw 19 10 "${colorBgLightGrey} ${colorReset}"
draw 20 10 "${colorBgLightGrey} ${colorReset}"
draw 21 10 "${colorBgLightGrey} ${colorReset}"
drawCard 18 11 5

draw 14 10 "  "
draw 14 12 "  "
draw 23 10 "  "
draw 23 12 "  "

draw 17 11 "${colorFgLightGreen}${colorBgLightGrey}┏${colorReset}"
draw 17 13 "${colorFgLightGreen}┗${colorReset}"
draw 23 11 "${colorFgLightGreen}┓${colorReset}"
draw 23 13 "${colorFgLightGreen}┛${colorReset}"

drawCard 46 22 3
draw 43 23 "  "
draw 52 23 "  "
draw 46 23 "${colorBgLightGrey} ${colorReset}"
draw 47 23 "${colorBgLightGrey} ${colorReset}"
draw 48 23 "${colorBgLightGrey} ${colorReset}"
draw 49 23 "${colorBgLightGrey} ${colorReset}"
draw 50 23 "${colorBgLightGrey} ${colorReset}"
draw 46 25 " "
drawCard 47 24 2

draw 44 23 "  "
draw 51 23 "  "
draw 45 27 "       "
draw 45 27 "${colorFgLightGreen}◀┗━━━━━┛▶${colorReset}"

draw 7 16 "${colorBgLightGrey} ${colorReset}"
draw 8 16 "${colorBgLightGrey} ${colorReset}"
draw 9 16 "${colorBgLightGrey} ${colorReset}"
draw 10 16 "${colorBgLightGrey} ${colorReset}"
draw 11 16 "${colorBgLightGrey} ${colorReset}"
draw 7 17 "${colorBgLightGrey} ${colorReset}"
draw 7 18 " "
drawCard 8 17 36

draw 47 28 "         "
draw 47 29 "         "
draw 46 30 "         "
draw 46 31 "         "
# draw 47 29 "${colorFgLightGreen}╭─┬┬┬╮${colorReset}"
# draw 47 30 "${colorFgLightGreen}├┤   │${colorReset}"
# draw 47 31 "${colorFgLightGreen}╰╮  ╭╯${colorReset}"

printf "$buffer\n"
read -rsn 1

clear

#                _
#   / \          \\___     
#   \O/   / \    _\\\\\    ╭╮     
#    |    \O/    \\        │├┬┬╮  ╭─┬┬┬╮
#   / \    |      \_____  ╭┤   │  ├┤   │
#   | |   < >             ╰╮  ╭╯  ╰╮  ╭╯
#                          
# left arrow ▶
# right arrow ◀
# up arrow ▲
