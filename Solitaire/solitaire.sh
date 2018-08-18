#!/bin/bash
colorReset='\033[0m'
underline='\033[4m'

colorBgBlack='\033[40m'
colorBgRed='\033[41m'
colorBgGreen='\033[42m'
colorBgYellow='\033[43m'
colorBgBlue='\033[44m'
colorBgPink='\033[45m'
colorBgCyan='\033[46m'
colorBgLightGrey='\033[47m'
colorBgDarkGrey='\033[100m'
colorBgLightRed='\033[101m'
colorBgLightYellow='\033[103m'
colorBgLightBlue='\033[104m'
colorBgLightCyan='\033[106m'
colorBgWhite='\033[107m'

colorFgBlack='\033[30m'
colorFgWhite='\033[97m'
colorFgRed='\033[31m'
colorFgYellow='\033[33m'
colorFgCyan='\033[36m'
colorFgLightRed='\033[91m'
colorFgLightGrey='\033[37m'
colorFgDarkGrey='\033[90m'
colorFgGreen='\033[32m'
colorFgLightGreen='\033[92m'
colorFgLightYellow='\033[93m'
colorFgLightPink='\033[95m'
colorFgLightCyan='\033[96m'

cardFaceUpColor=0
cardHeartColor=1
cardSpadeColor=2
cardFaceDownColor=3
cardSpaceColor=4
cardEdgeColor=5
cardShadowColor=6
cursorNormalColor=7
cursorSelectColor=8

defaultTheme=(
	[cardFaceUpColor]="$colorBgWhite"
	[cardHeartColor]="$colorFgRed"
	[cardSpadeColor]="$colorFgBlack"
	[cardFaceDownColor]="${colorFgWhite}${colorBgBlue}"
	[cardSpaceColor]="$colorFgWhite"
	[cardEdgeColor]="${colorFgBlack}${colorBgWhite}"
	[cardShadowColor]="${colorBgLightGrey}"
	[cursorNormalColor]="${colorFgLightYellow}"
	[cursorSelectColor]="${colorFgLightGreen}"
)

darkTheme=(
	[cardFaceUpColor]="$colorBgDarkGrey"
	[cardHeartColor]="$colorFgLightRed"
	[cardSpadeColor]="$colorFgLightGrey"
	[cardFaceDownColor]="${colorFgDarkGrey}${colorBgCyan}"
	[cardSpaceColor]="$colorFgLightGrey"
	[cardEdgeColor]="${colorFgLightGrey}${colorBgDarkGrey}"
	[cardShadowColor]="${colorBgLightGrey}"
	[cursorNormalColor]="${colorFgLightYellow}"
	[cursorSelectColor]="${colorFgLightGreen}"
)

theme=("${darkTheme[@]}")

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
zoneCursorLeft='┗'
zoneCursorRight='┛'
zoneCursorMiddle='━'
rangeCursorLeft='◀'
rangeCursorRight='▶'

noPile=0
stockPile=1
wastePile=2
foundationPile=3
tableauPile=4

gameZone=(
	"$stockPile"   "$wastePile"   "$noPile"      "$foundationPile" "$foundationPile" "$foundationPile" "$foundationPile"
	"$tableauPile" "$tableauPile" "$tableauPile" "$tableauPile"    "$tableauPile"    "$tableauPile"    "$tableauPile"
)

gameOriginX=3
gameOriginY=2
columnSpacing=3
rowSpacing=3
gameZoneColumns=7

rankTotal="${#rank[@]}"
suitTotal="${#suit[@]}"
cardTotal="$(( rankTotal * suitTotal ))"
cardHeight="${#cardFaceUp[@]}"
cardWidth="${#cardFaceUp[0]}"
gameZoneTotal="${#gameZone[@]}"
gameZoneRows="$(( (gameZoneTotal + gameZoneColumns - 1) / gameZoneColumns ))"

debugObjects() {
	objectTotal="${#objectText[@]}"

	for (( n = 0; n <= objectTotal; n++ ))
	do
		printf '%s\n' "${objectText[n]}  ${objectColor[n]}"
	done
}

createObjects() {
	createDeck
	createFaceDownCard
	createCardSpace
	createCardEdge
	createCardShadow
	createCursors
}

createDeck() {
	local s r

	deck=({0.."$cardTotal"})

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
	cardFaceDownId="$(( ${#objectText[@]} - 1 ))"
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

createCursors() {
	local w zoneCursor rangeCursor selectCursor

	zoneCursor+="$zoneCursorLeft"
	rangeCursor+="$rangeCursorRight "
	selectCursor+="${rangeCursorLeft}${zoneCursorLeft}"

	for (( w = 0; w < cardWidth; w++ ))
	do
		zoneCursor+="$zoneCursorMiddle"
		rangeCursor+=" "
		selectCursor+="$zoneCursorMiddle"
	done

	zoneCursor+="$zoneCursorRight"
	rangeCursor+=" $rangeCursorLeft"
	selectCursor+="${zoneCursorRight}${rangeCursorRight}"

	objectText+=("$zoneCursor")
	zoneCursorId="$(( ${#objectText[@]} - 1 ))"

	objectText+=("$rangeCursor")
	rangeCursorId="$(( ${#objectText[@]} - 1 ))"

	objectText+=("$selectCursor")
	selectCursorId="$(( ${#objectText[@]} - 1 ))"
}

setColors() {
	local n
	local faceUpColor="${theme[cardFaceUpColor]}"
	local heartColor="${theme[cardHeartColor]}"
	local spadeColor="${theme[cardSpadeColor]}"

	for (( n = 0; n < cardTotal; n++ ))
	do
		objectColor[n]="$faceUpColor"
		(( cardSuit[n] % 2 == 0 )) && objectColor[n]+="$heartColor" || objectColor[n]+="$spadeColor"
	done

	objectColor[cardFaceDownId]="${theme[cardFaceDownColor]}"
	objectColor[cardSpaceId]="${theme[cardSpaceColor]}"
	objectColor[cardEdgeId]="${theme[cardEdgeColor]}"
	objectColor[cardShadowId]="${theme[cardShadowColor]}"
	objectColor[zoneCursorId]="${theme[cursorNormalColor]}"
	objectColor[rangeCursorId]="${theme[cursorNormalColor]}"
	objectColor[selectCursorId]="${theme[cursorSelectColor]}"
}

setGameZones() {
	local row column

	for (( row = 0; row < gameZoneRows; row++ ))
	do
		for (( column = 0; column < gameZoneColumns; column++ ))
		do
			gameZoneX+=("$(( gameOriginX + column * (cardWidth + columnSpacing) ))")
			gameZoneY+=("$(( gameOriginY + row * (cardHeight + rowSpacing) ))")
		done
	done
}

drawAllGameZones() {
	local n

	for (( n = 0; n < gameZoneTotal; n++ ))
	do
		drawGameZone "$n"
	done
}

drawGameZone() {
	local n="$1"

	case "${gameZone[n]}" in
		"$stockPile") drawStockPile;;
        "$wastePile") drawWastePile;;
        "$foundationPile") drawFoundationPile;;
        "$tableauPile") drawTableauPile;;
	esac
}

drawStockPile() {
	local x="${gameZoneX[n]}"
	local y="${gameZoneY[n]}"
	[[ "${gameZoneCards[n]}" = "" ]] && drawCardSpace "$x" "$y" && return

	drawFaceDownCard "${gameZoneX[n]}" "${gameZoneY[n]}"
}

drawWastePile() {
	local x="${gameZoneX[n]}"
	local y="${gameZoneY[n]}"
	local i pile
	[[ "${gameZoneCards[n]}" = "" ]] && return

	IFS=';' pile=(${gameZoneCards[n]})
	local total="${#pile[@]}"

	for (( i = 0; i < total; i++ ))
	do
		(( i > 0 )) && drawCardEdge "$(( x - 1))" "$y"
		drawCard "$x" "$y" "${pile[i]}"

		(( x += 3 ))
	done
}

drawFoundationPile() {
	local x="${gameZoneX[n]}"
	local y="${gameZoneY[n]}"
	[[ "${gameZoneCards[n]}" = "" ]] && drawCardSpace "$x" "$y" && return

	drawCard "$x" "$y" "${gameZoneCards[n]##*;}"
}

drawTableauPile() {
	local x="${gameZoneX[n]}"
	local y="${gameZoneY[n]}"
	local i pile objectId color
	[[ "${gameZoneCards[n]}" = "" ]] && return

	IFS=';' pile=(${gameZoneCards[n]})
	local total="${#pile[@]}"

	for (( i = 0; i < total; i++ ))
	do
		(( i < gameZoneHidden[n] )) && objectId="$cardFaceDownId" || objectId="${pile[i]}"
		color="${objectColor[objectId]}"
		(( i < total - 1 )) && color+="$underline"
		drawObject "$x" "$y" "$color" "${objectText[objectId]}"

		(( y++ ))
	done
}

drawZoneCursor() {
	local x="${gameZoneX[$1]}"
	local y="${gameZoneY[$1]}"

	drawObject "$(( x - 1 ))" "$(( y + cardHeight + 1 ))" "${objectColor[zoneCursorId]}" "${objectText[zoneCursorId]}"
}

drawRangeCursor() {
	local x="${gameZoneX[$1]}"
	local y="${gameZoneY[$1]}"

	drawObject "$(( x - 2 ))" "$y" "${objectColor[rangeCursorId]}" "${objectText[rangeCursorId]}"
}

drawSelectCursor() {
	local x="${gameZoneX[$1]}"
	local y="${gameZoneY[$1]}"

	drawObject "$(( x - 1 ))" "$(( y + cardHeight + 1 ))" "${objectColor[selectCursorId]}" "${objectText[selectCursorId]}"
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

drawFaceDownCard() {
	drawObject "$1" "$2" "${objectColor[cardFaceDownId]}" "${objectText[cardFaceDownId]}"
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

createObjects #&& debugObjects && exit
setColors
setGameZones

gameZoneCards[0]='0'
gameZoneCards[1]='1;2;3'

gameZoneCards[3]='0'
gameZoneCards[4]='0;51'
gameZoneCards[5]=''
gameZoneCards[6]='51'

gameZoneCards[7]='14;15' && gameZoneHidden[7]=1
gameZoneCards[8]='0'
gameZoneCards[9]='0' && gameZoneHidden[9]=1
gameZoneCards[10]='51;50;49'
gameZoneCards[11]='51;50;49' && gameZoneHidden[11]=1
gameZoneCards[12]='51;50;49' && gameZoneHidden[12]=2
gameZoneCards[13]='51;50;49;0;4' && gameZoneHidden[13]=3

drawZoneCursor 8 && drawRangeCursor 8
drawSelectCursor 8
drawAllGameZones

printf "$buffer\n\n"
exit

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
