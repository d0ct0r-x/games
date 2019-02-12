#!/bin/bash
space=' '
nbsp=$'\u00a0'
colorReset='\033[0m'
underline='\033[4m'
bold='\033[1m'
invert='\033[7m'
dim='\033[2m'

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
cardHeartInverseColor=9
cardSpadeInverseColor=10

defaultTheme=(
	[cardFaceUpColor]="$colorBgWhite"
	[cardHeartColor]="$colorFgRed"
	[cardSpadeColor]="$colorFgBlack"
	[cardFaceDownColor]="${colorFgLightGrey}${colorBgBlue}"
	[cardSpaceColor]="$colorFgLightGrey"
	[cardEdgeColor]="${colorFgBlack}${colorBgWhite}"
	[cardShadowColor]="${colorBgLightGrey}"
	[cursorNormalColor]="${colorFgLightYellow}"
	[cursorSelectColor]="${colorFgLightGreen}"
	[cardHeartInverseColor]="${colorBgLightGrey}"
	[cardSpadeInverseColor]="${colorBgLightGrey}"
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
	[cardHeartInverseColor]="${colorBgLightGrey}"
	[cardSpadeInverseColor]="${invert}"
)

themes=("${defaultTheme[@]}" "${darkTheme[@]}")
theme=("${darkTheme[@]}")
themeId=0
themeParamsTotal="${#defaultTheme[@]}"
themeTotal=$(( ${#themes[@]} / themeParamsTotal ))

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

gameOriginX=5
gameOriginY=2
columnSpacing=3
rowSpacing=3
gameZoneColumns=7
maxPileSize=7

rankTotal="${#rank[@]}"
suitTotal="${#suit[@]}"
cardTotal="$(( rankTotal * suitTotal ))"
cardHeight="${#cardFaceUp[@]}"
cardWidth="${#cardFaceUp[0]}"
gameZoneTotal="${#gameZone[@]}"
gameZoneRows="$(( (gameZoneTotal + gameZoneColumns - 1) / gameZoneColumns ))"
playerStartX="$(( (gameZoneColumns - 1) / 2 ))"
playerStartY="$(( gameZoneRows - 1 ))"
playerStartZone="$(( playerStartX + playerStartY * gameZoneColumns ))"

commandQuit=0
commandMoveLeft=1
commandMoveRight=2
commandMoveUp=3
commandMoveDown=4
commandAction=5
commandCycleColors=6
commandNewGame=7

current=0
previous=1

debugObjects() {
	objectTotal="${#objectOn[@]}"

	for (( n = 0; n < objectTotal; n++ ))
	do
		printf "${objectColor[n]}${objectOn[n]}$colorReset|${objectOff[n]}|\n"
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

	for (( s = 0; s < suitTotal; s++ ))
	do
		for (( r = 0; r < rankTotal; r++ ))
		do
			deck+=("$(( r + s * rankTotal ))")
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
		line="${line//${space}/${nbsp}}"

        (( n > 0 )) && object+="${space}"
		object+="$line"
	done

	objectOn+=("$object")
	objectOff+=("${object//[^${space}]/${nbsp}}")
}

createFaceDownCard() {
	local h w object

	for (( h = 0; h < cardHeight; h++ ))
	do
		(( h > 0 )) && object+="${space}"

		for (( w = 0; w < cardWidth; w++ ))
		do
			object+="$cardFaceDownPattern"
		done
	done

	objectOn+=("$object")
	objectOff+=("${object//[^${space}]/${nbsp}}")
	cardFaceDownId="$(( ${#objectOn[@]} - 1 ))"
}

createCardSpace() {
	local h w object

	for (( h = 0; h < cardHeight; h++ ))
	do
		(( h > 0 )) && object+="${space}"

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
				object+="${nbsp}"
			fi
		done
	done

	objectOn+=("$object")
	objectOff+=("${object//[^${space}]/${nbsp}}")
	cardSpaceId="$(( ${#objectOn[@]} - 1 ))"
}

createCardEdge() {
	local h object

	for (( h = 0; h < cardHeight; h++ ))
	do
		(( h > 0 )) && object+="${space}"
		object+="$cardEdge"
	done

	objectOn+=("$object")
	objectOff+=("${object//[^${space}]/${nbsp}}")
	cardEdgeId="$(( ${#objectOn[@]} - 1 ))"
}

createCardShadow() {
	local h w object

	for (( h = 0; h < cardHeight - 1; h++ ))
	do
		(( h > 0 )) && object+="${space}"

		for (( w = 0; w < cardWidth; w++ ))
		do
			object+="${nbsp}"
		done
	done

	objectOn+=("$object")
	objectOff+=("${object//[^${space}]/${nbsp}}")
	cardShadowId="$(( ${#objectOn[@]} - 1 ))"
}

createCursors() {
	local w zoneCursor selectCursor

	zoneCursor+="$zoneCursorLeft"
	selectCursor+="${rangeCursorLeft}${zoneCursorLeft}"

	for (( w = 0; w < cardWidth; w++ ))
	do
		zoneCursor+="$zoneCursorMiddle"
		selectCursor+="$zoneCursorMiddle"
	done

	zoneCursor+="$zoneCursorRight"
	selectCursor+="${zoneCursorRight}${rangeCursorRight}"

	objectOn+=("$zoneCursor")
	objectOff+=("${zoneCursor//?/${nbsp}}")
	zoneCursorId="$(( ${#objectOn[@]} - 1 ))"

	objectOn+=("$rangeCursorRight")
	objectOff+=("${rangeCursorRight//?/${nbsp}}")
	rangeCursorRightId="$(( ${#objectOn[@]} - 1 ))"

	objectOn+=("$rangeCursorLeft")
	objectOff+=("${rangeCursorLeft//?/${nbsp}}")
	rangeCursorLeftId="$(( ${#objectOn[@]} - 1 ))"

	objectOn+=("$selectCursor")
	objectOff+=("${selectCursor//?/${nbsp}}")
	selectCursorId="$(( ${#objectOn[@]} - 1 ))"
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
	objectColor[rangeCursorRightId]="${theme[cursorNormalColor]}"
	objectColor[rangeCursorLeftId]="${theme[cursorNormalColor]}"
	objectColor[selectCursorId]="${theme[cursorSelectColor]}"
}

setGameZones() {
	local row column n

	for (( row = 0; row < gameZoneRows; row++ ))
	do
		for (( column = 0; column < gameZoneColumns; column++ ))
		do
			gameZoneX+=("$(( gameOriginX + column * (cardWidth + columnSpacing) ))")
			gameZoneY+=("$(( gameOriginY + row * (cardHeight + rowSpacing) ))")

			n=$(( column + row * gameZoneColumns ))

			case "${gameZone[n]}" in
				"$stockPile") stockZone="$n";;
		        "$wastePile") wasteZone="$n";;
		        "$foundationPile") foundationZone+=("$n");;
		        "$tableauPile") tableauZone+=("$n");;
			esac
		done
	done

	foundationZoneTotal="${#foundationZone[@]}"
	tableauZoneTotal="${#tableauZone[@]}"
}

shuffleDeck() {
   local i tmp max rand

   max=$(( 32768 / cardTotal * cardTotal ))

   for (( i = cardTotal - 1; i > 0; i-- ))
   do
      while (( (rand = $RANDOM) >= max )); do :; done
      rand=$(( rand % (i + 1) ))
      tmp="${deck[i]}" deck[i]="${deck[rand]}" deck[rand]="$tmp"
   done
}

dealAllCards() {
	local n row column zoneId
	local deckIndex=0

	for (( n = 0; n < gameZoneTotal; n++ ))
	do
		gameZoneCards[n]=
		gameZoneCardsTotal[n]=0
		gameZoneHidden[n]=0
	done

	for (( row = 0; row < maxPileSize; row++ ))
	do
		for (( column = row; column < tableauZoneTotal; column++ ))
		do
			zoneId="${tableauZone[column]}"
			gameZoneCards[zoneId]+="${deck[deckIndex]}"
			(( gameZoneCardsTotal[zoneId]++ ))
			(( column > row )) && gameZoneCards[zoneId]+="${space}"
			gameZoneHidden[zoneId]="$row"
			(( deckIndex++ ))
		done
	done

	while (( deckIndex < cardTotal ))
	do
		gameZoneCards[stockZone]+="${deck[deckIndex]}"
		(( deckIndex < cardTotal - 1 )) && gameZoneCards[stockZone]+="${space}"
		(( deckIndex++ ))
	done
}

drawAllGameZones() {
	local n

	for (( n = 0; n < gameZoneTotal; n++ ))
	do
		drawGameZone true "$n"
	done
}

drawGameZone() {
	local isVisible="$1"
	local n="$2"

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

	drawFaceDownCard "$isVisible" "${gameZoneX[n]}" "${gameZoneY[n]}"
}

drawWastePile() {
	local x="${gameZoneX[n]}"
	local y="${gameZoneY[n]}"
	local i pile
	[[ "${gameZoneCards[n]}" = "" ]] && return

	pile=(${gameZoneCards[n]})
	local total="${#pile[@]}"

	for (( i = 0; i < total; i++ ))
	do
		(( i > 0 )) && drawCardEdge "$isVisible" "$(( x - 1))" "$y"
		drawCard "$isVisible" "$x" "$y" "${pile[i]}"

		(( x += 3 ))
	done
}

drawFoundationPile() {
	local x="${gameZoneX[n]}"
	local y="${gameZoneY[n]}"
	[[ "${gameZoneCards[n]}" = "" ]] && drawCardSpace "$isVisible" "$x" "$y" && return

	drawCard "$isVisible" "$x" "$y" "${gameZoneCards[n]##*${space}}"
}

drawTableauPile() {
	local x="${gameZoneX[n]}"
	local y="${gameZoneY[n]}"
	local i pile objectId color
	[[ "${gameZoneCards[n]}" = "" ]] && return

	pile=(${gameZoneCards[n]})
	local total="${#pile[@]}"

	for (( i = 0; i < total; i++ ))
	do
		(( i < gameZoneHidden[n] )) && objectId="$cardFaceDownId" || objectId="${pile[i]}"
		color="${objectColor[objectId]}"
		(( i < total - 1 )) && color+="$underline"
		drawObject "$isVisible" "$x" "$y" "$objectId" "$color"
		(( y++ ))
	done
}

drawPlayerCards() {
	local x="${gameZoneX[playerZone]}"
	local y="${gameZoneY[playerZone]}"
	local offset="${gameZoneCardsTotal[playerZone]}"
	local i pile objectId color

	pile=($playerCards)
	local total="${#pile[@]}"
	(( gameZone[playerZone] == tableauPile )) && (( y += offset ))

	# (( offset > 0 )) && drawCardShadow "$1" "$x" "$y"
	# local zoneTopCard="${gameZoneCards[playerZone]##*;}"
	# (( offset > 0 )) && drawObject "$1" "$x" "$(( y - 1 ))" "$zoneTopCard" "${objectColor[zoneTopCard]}${invert}"
	drawCardHighlight "$1"

	for (( i = 0; i < total; i++ ))
	do
		objectId="${pile[i]}"
		color="${objectColor[objectId]}"
		(( i < total - 1 )) && color+="$underline"
		drawObject "$1" "$(( x + 1 ))" "$(( y + 1 ))" "$objectId" "$color"
		(( y++ ))
	done
}

drawCardHighlight() {
	local x="${gameZoneX[playerZone]}"
	local y="${gameZoneY[playerZone]}"
	local offset="${gameZoneCardsTotal[playerZone]}"
	local zoneTopCard="${gameZoneCards[playerZone]##*${space}}"
	local highlightColor="${objectColor[zoneTopCard]}"

	(( gameZone[playerZone] == tableauPile )) && (( y += offset - 1 ))

	(( cardSuit[zoneTopCard] % 2 == 0 )) && \
	highlightColor+="${theme[cardHeartInverseColor]}" || \
	highlightColor+="${theme[cardSpadeInverseColor]}"

	(( offset > 0 )) && \
	(( gameZoneCardsTotal[playerZone] > gameZoneHidden[playerZone] )) && \
	drawObject "$1" "$x" "$(( y ))" "$zoneTopCard" "$highlightColor"
}

drawCard() {
	drawObject "$1" "$2" "$3" "$4"
}

drawFaceDownCard() {
	drawObject "$1" "$2" "$3" "$cardFaceDownId"
}

drawCardSpace() {
	drawObject "$1" "$2" "$3" "$cardSpaceId"
}

drawCardEdge() {
	drawObject "$1" "$2" "$3" "$cardEdgeId"
}

drawCardShadow() {
	drawObject "$1" "$2" "$3" "$cardShadowId"
}

drawCursor() {
	if $playerSelect
	then
		drawSelectCursor "$1" "$2"
		drawPlayerCards "$1"
	else
		drawZoneCursor "$1" "$2"
		(( gameZone["$2"] == tableauPile )) && drawRangeCursor "$1" "$2"
	fi
}

drawZoneCursor() {
	local x="${gameZoneX[$2]}"
	local y="${gameZoneY[$2]}"
	local offset="${gameZoneCardsTotal[$2]}"

	(( gameZone["$2"] == tableauPile )) && (( offset > 0 )) && (( y += offset - 1 ))
	drawObject "$1" "$(( x - 1 ))" "$(( y + cardHeight + 1 ))" "$zoneCursorId"
}

drawRangeCursor() {
	local x="${gameZoneX[$2]}"
	local y="${gameZoneY[$2]}"
	local offset="${gameZoneCardsTotal[$2]}"

	(( offset > 0 )) && (( y += offset - 1 - playerPileIndex ))
	drawObject "$1" "$(( x - 2 ))" "$y" "$rangeCursorRightId"
	drawObject "$1" "$(( x + cardWidth + 1 ))" "$y" "$rangeCursorLeftId"
}

drawSelectCursor() {
	local x="${gameZoneX[$2]}"
	local y="${gameZoneY[$2]}"
	local offset="$(( gameZoneCardsTotal[$2] + playerCardsTotal ))"

	(( gameZone["$2"] == tableauPile )) && (( offset > 0 )) && (( y += offset - 1 ))
	drawObject "$1" "$(( x - 1 ))" "$(( y + cardHeight + 1 ))" "$selectCursorId"
}

drawObject() {
	local isVisible="$1"
	local x="$2"
	local y="$3"
	local objectId="$4"
	local colorOverride="$5"
	local object color lines line n

	if $isVisible
	then
		object="${objectOn[objectId]}"
		[ -n "$colorOverride" ] && color="$colorOverride" || color="${objectColor[objectId]}"
	else
		object="${objectOff[objectId]}"
	fi

	lines=($object)
	local linesTotal="${#lines[@]}"

	for (( n = 0; n < linesTotal; n++ ))
	do
		line="${color}${lines[n]}${colorReset}"
		draw "$x" "$y" "$line"
		(( y++ ))
	done
}

draw() {
    buffer+="\033[${2};${1}H${3}"
}

movePlayerLeft() {
	(( playerX = (playerX - 1 + gameZoneColumns) % gameZoneColumns ))
	movePlayerToZone $(( playerX + playerY * gameZoneColumns ))
}

movePlayerRight() {
	(( playerX = (playerX + 1 + gameZoneColumns) % gameZoneColumns ))
	movePlayerToZone $(( playerX + playerY * gameZoneColumns ))
}

movePlayerUp() {
	if (( gameZone[playerZone] == tableauPile )) && \
	   (( playerPileIndex < gameZoneCardsTotal[playerZone] - gameZoneHidden[playerZone] - 1 )) && \
	   ! $playerSelect
	then
		drawRangeCursor false "$playerZone"
		(( playerPileIndex++ ))
		drawRangeCursor true "$playerZone"
	else
		(( playerY = (playerY - 1 + gameZoneRows) % gameZoneRows ))
		movePlayerToZone $(( playerX + playerY * gameZoneColumns ))
	fi
}

movePlayerDown() {
	if (( gameZone[playerZone] == tableauPile )) && \
	   (( playerPileIndex > 0 ))
	then
		drawRangeCursor false "$playerZone"
		(( playerPileIndex-- ))
		drawRangeCursor true "$playerZone"
	else
		(( playerY = (playerY + 1 + gameZoneRows) % gameZoneRows ))
		movePlayerToZone $(( playerX + playerY * gameZoneColumns ))
	fi
}

movePlayerToZone() {
	drawCursor false "$playerZone"

	if $playerSelect
	then
		drawGameZone false "$playerZone"
		drawGameZone true "$playerZone"
	fi

	playerZone="$1"
	playerPileIndex=0

	drawCursor true "$playerZone"
}

executePlayerAction() {
	case "${gameZone[playerZone]}" in
		# "$stockPile") dealToWastePile;;
        "$wastePile") togglePlayerSelect;;
        "$foundationPile") togglePlayerSelect;;
        "$tableauPile") togglePlayerSelect;;
	esac
}

togglePlayerSelect() {
	if $playerSelect
	then
		validatePlaceCards && placeCardsDown
	else
		(( gameZoneCardsTotal[playerZone] > 0 )) && pickCardsUp
	fi
}

pickCardsUp() {
	local cards

	drawGameZone false "$playerZone"
	drawCursor false "$playerZone"

	cards=(${gameZoneCards[playerZone]})
	cardsTotal="${#cards[@]}"

	playerCardsTotal=$(( playerPileIndex + 1 ))
	playerCards="${cards[*]: -playerCardsTotal}"
	gameZoneCards[playerZone]="${cards[*]::cardsTotal - playerCardsTotal}"
	(( gameZoneCardsTotal[playerZone] -= playerCardsTotal ))
	lastPickupZone="$playerZone"

	playerSelect=true

	drawGameZone true "$playerZone"
	drawCursor true "$playerZone"
}

validatePlaceCards() {
	(( playerZone == lastPickupZone )) && return

	local playerBottomCard="${playerCards%%${space}*}"
	local zoneTopCard="${gameZoneCards[playerZone]##*${space}}"

	if (( gameZone[playerZone] == tableauPile ))
	then
		(( gameZoneCardsTotal[playerZone] == 0 )) && \
		[[ "${rank[${cardRank[$playerBottomCard]}]}" = K ]] && return
		
		(( gameZoneCardsTotal[playerZone] > 0 )) && \
		(( cardRank[zoneTopCard] == cardRank[playerBottomCard] + 1 )) && \
		(( (cardSuit[zoneTopCard] + cardSuit[playerBottomCard]) % 2 == 1 )) && return

	elif (( gameZone[playerZone] == foundationPile ))
	then
		(( gameZoneCardsTotal[playerZone] == 0 )) && \
		[[ "${rank[${cardRank[$playerBottomCard]}]}" = A ]] && return

		(( gameZoneCardsTotal[playerZone] > 0 )) && \
		(( cardRank[playerBottomCard] == cardRank[zoneTopCard] + 1 )) && \
		(( cardSuit[zoneTopCard] == cardSuit[playerBottomCard] )) && return
	else
		return 1
	fi
}

placeCardsDown() {
	drawGameZone false "$playerZone"
	drawCursor false "$playerZone"

	(( gameZoneCardsTotal[playerZone] > 0 )) && gameZoneCards[playerZone]+="${space}"
	gameZoneCards[playerZone]+="$playerCards"
	(( gameZoneCardsTotal[playerZone] += playerCardsTotal ))
	playerCardsTotal=0
	playerCards=

	if (( playerZone != lastPickupZone )) && \
	   (( gameZoneHidden[lastPickupZone] > 0 )) && \
	   (( gameZoneHidden[lastPickupZone] == gameZoneCardsTotal[lastPickupZone] ))
	then
		(( gameZoneHidden[lastPickupZone]-- ))
		drawGameZone true "$lastPickupZone"
	fi

	playerSelect=false

	drawGameZone true "$playerZone"
	drawCursor true "$playerZone"
}

cycleColorTheme() {
	(( themeId = (themeId + 1) % themeTotal ))
	theme=("${themes[@]:(themeId * themeParamsTotal):(themeParamsTotal)}")
	setColors
	drawAllGameZones
	drawCursor true "$playerZone"
}

newGame() {
	initPlayer
	shuffleDeck
	dealAllCards
	tput clear
	drawAllGameZones
	drawCursor true "$playerZone"
}

initPlayer() {
	playerZone="$playerStartZone"
	playerX="$playerStartX"
	playerY="$playerStartY"
	playerPileIndex=0
	playerSelect=false
	playerCards=
	playerCardsTotal=0
	lastPickupZone=
}

quitGame() {
	gameOn=false
    kill -SIGUSR1 $$
}

reader() {
	# trap exit SIGUSR1
	local input= output=

	while IFS= read -sn 1 input
	do
		case "$input" in
			q) output="$commandQuit" && break;;

	        A) output="$commandMoveUp";;
	        B) output="$commandMoveDown";;
	        C) output="$commandMoveRight";;
	        D) output="$commandMoveLeft";;
	        ' ') output="$commandAction";;
	        s) output="$commandAction";;
	        c) output="$commandCycleColors";;
	        n) output="$commandNewGame";;
		esac

		[ -n "$output" ] && builtin printf "$output"
		output=
	done
}

debug() {
	local playerBottomCard="${playerCards%%${space}*}"
	draw 80 10 "playerBottomCard = $playerBottomCard"

	local playerBottomCardRankKey="${cardRank[$playerBottomCard]}"
	draw 80 11 "playerBottomCardRankKey = $playerBottomCardRankKey"

	local playerBottomCardRankValue="${rank[$playerBottomCardRankKey]}"
	draw 80 12 "playerBottomCardRankValue = $playerBottomCardRankValue"
}

controller() {
	trap '' SIGUSR1
	local input commands

	commands[commandQuit]=quitGame
	commands[commandMoveLeft]=movePlayerLeft
	commands[commandMoveRight]=movePlayerRight
	commands[commandMoveUp]=movePlayerUp
	commands[commandMoveDown]=movePlayerDown
	commands[commandAction]=executePlayerAction
	commands[commandCycleColors]=cycleColorTheme
	commands[commandNewGame]=newGame

	while $gameOn
	do
		# debug
        builtin printf "$buffer"
        buffer=
        read -sn 1 input
        ${commands[$input]}
    done
}

clear
trap '' SIGUSR1
userSettings=$(stty -g)  # save user terminal state
tput civis               # turn off cursor
gameOn=true

createObjects
setColors #&& debugObjects && exit
setGameZones

# drawObject true 5 5 0
# drawObject true 12 5 0 "$invert"
# printf "$buffer\n"

newGame

reader | controller

clear
tput cnorm            # turn on cursor
stty "$userSettings"  # restore user terminal state

exit
# sleep 0.5

# movePlayerDown
# printf "$buffer\n\n"
# sleep 0.5

# movePlayerRight
# printf "$buffer\n\n"
# sleep 0.5

# movePlayerDown
# printf "$buffer\n\n"
# sleep 0.5

# movePlayerRight
# printf "$buffer\n\n"
# sleep 0.5

# movePlayerLeft
# printf "$buffer\n\n"
# sleep 0.5

# movePlayerUp
# printf "$buffer\n\n"
# sleep 0.5

# movePlayerLeft
# printf "$buffer\n\n"
# sleep 0.5

# movePlayerUp
# printf "$buffer\n\n"
# sleep 0.5

# -- Store object delete in table - objectOn objectOff
# -- player current / previous as movement history array?
# -- 


# for (( n = 0; n < tableauZoneTotal; n++ ))
# do
# 	zoneId="${tableauZone[n]}"
# 	printf "${gameZoneCards[zoneId]}\n"
# done

# sleep 1
# mode=ERASE drawZoneCursor "$playerStartZone"
# mode=ERASE drawRangeCursor "$playerStartZone"
# drawZoneCursor "$(( playerStartZone - 1 ))"
# drawRangeCursor "$(( playerStartZone - 1 ))"
# printf "$buffer\n\n"

# sleep 1

exit

# gameZoneCards[0]='0'
# gameZoneCards[1]='1;2;3'

# gameZoneCards[3]='0'
# gameZoneCards[4]='0;51'
# gameZoneCards[5]=''
# gameZoneCards[6]='51'

# gameZoneCards[7]='14;15' && gameZoneHidden[7]=1
# gameZoneCards[8]='0'
# gameZoneCards[9]='0' && gameZoneHidden[9]=1
# gameZoneCards[10]='51;50;49'
# gameZoneCards[11]='51;50;49' && gameZoneHidden[11]=1
# gameZoneCards[12]='51;50;49' && gameZoneHidden[12]=2
# gameZoneCards[13]='51;50;49;0;4' && gameZoneHidden[13]=3

# drawSelectCursor 8
# drawAllGameZones



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
