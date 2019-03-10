#!/bin/bash

#  Solitaire game in bash
#  Version:  0.0.1
#  Author:   Tom Lloyd (twisted_tomato@hotmail.com)
#  Date:     17/02/2019

#  -- CONTROLS --
#  Use arrow keys to move
#  [SPACE]          - Action (Pick/Place/Deal)
#  [q]              - Quit game
#  [n]              - New game
#  [c]              - Cycle colour theme
#  [a,s,d,f,g,h,j]  - Quick pick/place for piles 1-7
#                     (Put left 3 fingers on [a,s,d], right 3 fingers on [g,h,j], any finger hits [f])
#  [w]              - Quick deal
#                     (Use left middle finger. Press once to go to waste pile, press again to deal)

#  -- FEATURES --
#  * All text based sprites
#  * Default & dark colour themes
#  * Auto unhide, undo & move
#  * Configurable UI (Resize, position)
#  * Tested working on Windows Git Bash & Mac OSX Terminal

#  -- TODO --
#  Better win screen / animation
#  Controls / help
#  Timer / score

# ===========================================================================
#      Declare variables
# ===========================================================================

# -- Config variables (CAN CHANGE) ------------------------------------------
gameOriginX=5
gameOriginY=2
columnSpacing=3
rowSpacing=3
gameZoneColumns=7
tableauPileLimit=7
wastePileLimit=3

# 'cardFaceUp' controls relative size of all card objects
# 1>  is left padded rank & position
# <1  is right padded rank & position
# ♥   is suit & position
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

# -- Global variables (DO NOT CHANGE) ---------------------------------------
space=' '         # Space is used as a list separator for number lists and packed objects
nbsp=$'\302\240'  # Non breaking space is used to erase / draw empty space for objects without breaking lines
rank=(A 2 3 4 5 6 7 8 9 10 J Q K)
suit=(♥ ♣ ♦ ♠)

noPile=0
stockPile=1
wastePile=2
foundationPile=3
tableauPile=4

# 'gameZone' array determines where types of pile are placed in the game
# it is one-dimensional but split into 2d by the 'gameZoneColumns' variable
gameZone=(
	"$stockPile"   "$wastePile"   "$noPile"      "$foundationPile" "$foundationPile" "$foundationPile" "$foundationPile"
	"$tableauPile" "$tableauPile" "$tableauPile" "$tableauPile"    "$tableauPile"    "$tableauPile"    "$tableauPile"
)

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

# Indexes for commands
# More than 10 commands so using 2 digit numbers, controller reads 2 digits
commandQuit=10
commandMoveLeft=11
commandMoveRight=12
commandMoveUp=13
commandMoveDown=14
commandAction=15
commandCycleColors=16
commandNewGame=17
macroSelect1=18
macroSelect2=19
macroSelect3=20
macroSelect4=21
macroSelect5=22
macroSelect6=23
macroSelect7=24
macroDeal=25

# -- Colour variables -------------------------------------------------------
colorReset='\033[0m'
underline='\033[4m'
invert='\033[7m'

colorBgBlue='\033[44m'
colorBgCyan='\033[46m'
colorBgLightGrey='\033[47m'
colorBgDarkGrey='\033[100m'
colorBgWhite='\033[107m'

colorFgBlack='\033[30m'
colorFgRed='\033[31m'
colorFgLightRed='\033[91m'
colorFgLightGrey='\033[37m'
colorFgDarkGrey='\033[90m'
colorFgLightGreen='\033[92m'
colorFgLightYellow='\033[93m'

cardFaceUpColor=0
cardHeartColor=1
cardSpadeColor=2
cardFaceDownColor=3
cardSpaceColor=4
cardEdgeColor=5
cursorNormalColor=6
cursorSelectColor=7
cardHeartHighlightColor=8
cardSpadeHighlightColor=9

defaultTheme=(
	[cardFaceUpColor]="${colorBgWhite}"
	[cardHeartColor]="${colorFgRed}"
	[cardSpadeColor]="${colorFgBlack}"
	[cardFaceDownColor]="${colorFgLightGrey}${colorBgBlue}"
	[cardSpaceColor]="${colorFgLightGrey}"
	[cardEdgeColor]="${colorFgBlack}${colorBgWhite}"
	[cursorNormalColor]="${colorFgLightYellow}"
	[cursorSelectColor]="${colorFgLightGreen}"
	[cardHeartHighlightColor]="${colorBgLightGrey}"
	[cardSpadeHighlightColor]="${colorBgLightGrey}"
)

darkTheme=(
	[cardFaceUpColor]="${colorBgDarkGrey}"
	[cardHeartColor]="${colorFgLightRed}"
	[cardSpadeColor]="${colorFgLightGrey}"
	[cardFaceDownColor]="${colorFgDarkGrey}${colorBgCyan}"
	[cardSpaceColor]="${colorFgLightGrey}"
	[cardEdgeColor]="${colorFgLightGrey}${colorBgDarkGrey}"
	[cursorNormalColor]="${colorFgLightYellow}"
	[cursorSelectColor]="${colorFgLightGreen}"
	[cardHeartHighlightColor]="${colorBgLightGrey}"
	[cardSpadeHighlightColor]="${invert}"
)

# This will set the colour theme (press [c] to change in game)
# To add a theme:
#   1. Add more colour variables if missing (google 'bash color')
#   2. Define new theme array above (use same structure)
#   3. Add new theme to 'themes' array below (use same variable syntax)
themes=("${defaultTheme[@]}" "${darkTheme[@]}")
theme=("${defaultTheme[@]}")
themeId=0
themeParamsTotal="${#defaultTheme[@]}"
themeTotal=$(( ${#themes[@]} / themeParamsTotal ))

# ===========================================================================
#      Declare functions
# ===========================================================================

createObjects() {
	createDeck
	createFaceDownCard
	createCardSpace
	createCardEdge
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
# Objects on multiple lines are packed into a space delimited string
# All objects have an 'objectOff' copy to erase objects using non breaking space

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

	completedCardsTotal=0
	gameZoneCards=()
	gameZoneCardsTotal=()
	gameZoneHidden=()

	for (( row = 0; row < tableauPileLimit; row++ ))
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
		(( gameZoneCardsTotal[stockZone]++ ))
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
	[[ "${gameZoneCards[n]}" = "" ]] && drawCardSpace "$isVisible" "$x" "$y" && return

	drawFaceDownCard "$isVisible" "${gameZoneX[n]}" "${gameZoneY[n]}"
}

drawWastePile() {
	local x="${gameZoneX[n]}"
	local y="${gameZoneY[n]}"
	local i pile
	(( wastePileIndex == 0 )) && return

	pile=(${gameZoneCards[n]})
	local total="${#pile[@]}"

	for (( i = 0; i < wastePileIndex; i++ ))
	do
		(( i > 0 )) && drawCardEdge "$isVisible" "$(( x - 1))" "$y"
		drawCard "$isVisible" "$x" "$y" "${pile[total - wastePileIndex + i]}"

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
	local offset i pile objectId color

	pile=($playerCards)
	local total="${#pile[@]}"

	if (( gameZone[playerZone] == tableauPile ))
	then
		offset="${gameZoneCardsTotal[playerZone]}"
		(( y += offset ))

	elif (( gameZone[playerZone] == wastePile ))
	then
		offset="$wastePileIndex"
		(( offset > 0 )) && (( x += offset * 3 ))
	fi

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

	if (( gameZone[playerZone] == tableauPile ))
	then
		(( y += offset - 1 ))

	elif (( gameZone[playerZone] == wastePile ))
	then
		offset="$wastePileIndex"
		(( x += (offset - 1) * 3 ))
	fi

	(( cardSuit[zoneTopCard] % 2 == 0 )) && \
	highlightColor+="${theme[cardHeartHighlightColor]}" || \
	highlightColor+="${theme[cardSpadeHighlightColor]}"

	(( offset > 0 )) && \
	(( gameZone[playerZone] != stockPile )) && \
	(( gameZoneCardsTotal[playerZone] > gameZoneHidden[playerZone] )) && \
	drawObject "$1" "$x" "$y" "$zoneTopCard" "$highlightColor"
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

drawCursor() {
	(( gameZone["$2"] == noPile )) && return

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
	local offset

	if (( gameZone["$2"] == tableauPile ))
	then
		offset="${gameZoneCardsTotal[$2]}"
		(( offset > 0 )) && (( y += offset - 1 ))

	elif (( gameZone["$2"] == wastePile ))
	then
		offset="$wastePileIndex"
		(( offset > 0 )) && (( x += (offset - 1) * 3 ))
	fi

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
	local offset

	if (( gameZone["$2"] == tableauPile ))
	then
		offset="$(( gameZoneCardsTotal[$2] + playerCardsTotal ))"
		(( offset > 0 )) && (( y += offset - 1 ))

	elif (( gameZone["$2"] == wastePile ))
	then
		offset="$wastePileIndex"
		(( offset > 0 )) && (( x += offset * 3 ))
	fi

	drawObject "$1" "$(( x - 1 ))" "$(( y + cardHeight + 1 ))" "$selectCursorId"
}

drawObject() {
# Unpacks and draws object lines from space delimited string
# 'isVisible' is 'true' to draw object and 'false' to erase object
# Takes a 'colorOverride' argument to draw underlines and highlights on cards for visual effect

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
# Adds object updates to the main buffer using ansi escape code
# Prints once per controller cycle and then flushed
# Draws something anywhere on the screen at X Y position
    buffer+="\033[${2};${1}H${3}"
}

movePlayerLeft() {
	movePlayerXY -1 0
}

movePlayerRight() {
	movePlayerXY 1 0
}

movePlayerUp() {
	movePlayerXY 0 -1
}

movePlayerDown() {
	movePlayerXY 0 1
}

movePlayerXY() {
	local dx="$1"
	local dy="$2"

	(( dy != 0 )) && checkMoveRangeCursor && return
	
	local x="$(( playerZone % gameZoneColumns ))"
	local y="$(( playerZone / gameZoneColumns ))"
	x="$(( (x + dx + gameZoneColumns) % gameZoneColumns ))"
	y="$(( (y + dy + gameZoneRows) % gameZoneRows ))"
	local targetZone="$(( x + y * gameZoneColumns ))"

	checkMoveToTarget
}

checkMoveRangeCursor() {
	if ! $playerSelect && (( gameZone[playerZone] == tableauPile ))
	then
		if (( dy < 0 )) && (( playerPileIndex < gameZoneCardsTotal[playerZone] - gameZoneHidden[playerZone] - 1 ))
	    then
			moveRangeCursorBy 1 && return 0

		elif (( dy > 0 )) && (( playerPileIndex > 0 ))
		then
			moveRangeCursorBy -1 && return 0
		fi
	fi

	return 1
}

moveRangeCursorBy() {
	local increment="$1"

	drawRangeCursor false "$playerZone"
	(( playerPileIndex += increment ))
	drawRangeCursor true "$playerZone"
}

checkMoveToTarget() {
	(( gameZone[targetZone] != tableauPile )) && \
	(( playerCardsTotal > 1 )) && return

	movePlayerToZone "$targetZone"

	(( gameZone[targetZone] == noPile )) && movePlayerXY "$dx" "$dy"
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
		"$stockPile") dealToWastePile;;
        "$wastePile") togglePlayerSelect;;
        "$foundationPile") togglePlayerSelect;;
        "$tableauPile") togglePlayerSelect;;
	esac
}

dealToWastePile() {
	$playerSelect && macroAutoUndo && return

	local cards=(${gameZoneCards[stockZone]})
	local stockTotal="${#cards[@]}"
	local wasteTotal="${gameZoneCardsTotal[wasteZone]}"
	local takeTotal
	
	drawGameZone false "$stockZone"
	drawGameZone false "$wasteZone"
	drawCursor false "$playerZone"

	if (( stockTotal > 0 ))
    then
        takeTotal=$(( stockTotal < wastePileLimit ? stockTotal : wastePileLimit ))
        (( wasteTotal > 0 )) && gameZoneCards[wasteZone]+="${space}"
        gameZoneCards[wasteZone]+="${cards[*]::takeTotal}"
        gameZoneCards[stockZone]="${cards[*]:takeTotal}"
        (( gameZoneCardsTotal[wasteZone] += takeTotal ))
        (( gameZoneCardsTotal[stockZone] -= takeTotal ))
        wastePileIndex="$takeTotal"
    else
        gameZoneCards[stockZone]="${gameZoneCards[wasteZone]}"
        gameZoneCards[wasteZone]=
        gameZoneCardsTotal[stockZone]="$wasteTotal"
        gameZoneCardsTotal[wasteZone]=0
        wastePileIndex=0
    fi

	drawGameZone true "$stockZone"
	drawGameZone true "$wasteZone"
	drawCursor true "$playerZone"
}

togglePlayerSelect() {
	if $playerSelect
	then
		validatePlaceDownCards && placeDownCards
	else
		validatePickUpCards && pickUpCards
	fi
}

validatePlaceDownCards() {
	(( playerZone == lastPickupZone )) && return 0

	local playerBottomCard="${playerCards%%${space}*}"
	local zoneTopCard="${gameZoneCards[playerZone]##*${space}}"

	if (( gameZone[playerZone] == tableauPile ))
	then
		checkPlaceDownTableauPile "$playerBottomCard" "$playerZone" && return 0

	elif (( gameZone[playerZone] == foundationPile ))
	then
		checkPlaceDownFoundationPile "$playerBottomCard" "$playerZone" && return 0
	fi

	macroAutoUndo
	return 1
}

checkPlaceDownTableauPile() {
	local sourceCard="$1"
	local targetZone="$2"

	if (( gameZoneCardsTotal[targetZone] == 0 ))
	then
		[[ "${rank[${cardRank[$sourceCard]}]}" = K ]]
	else
		local targetCard="${gameZoneCards[targetZone]##*${space}}"

		(( cardRank[zoneTopCard] == cardRank[playerBottomCard] + 1 )) && \
		(( (cardSuit[zoneTopCard] + cardSuit[playerBottomCard]) % 2 == 1 )) && return
	fi	
}

checkPlaceDownFoundationPile() {
	local sourceCard="$1"
	local targetZone="$2"

	if (( gameZoneCardsTotal[targetZone] == 0 ))
	then
		[[ "${rank[${cardRank[$sourceCard]}]}" = A ]]
	else
		local targetCard="${gameZoneCards[targetZone]##*${space}}"

		(( cardRank[sourceCard] == cardRank[targetCard] + 1 )) && \
		(( cardSuit[sourceCard] == cardSuit[targetCard] ))
	fi
}

macroAutoUndo() {
	local savedZone="$playerZone"
	movePlayerToZone "$lastPickupZone"
	placeDownCards
	movePlayerToZone "$savedZone"
	return 0
}

placeDownCards() {
	drawGameZone false "$playerZone"
	drawCursor false "$playerZone"

	(( gameZoneCardsTotal[playerZone] > 0 )) && gameZoneCards[playerZone]+="${space}"
	gameZoneCards[playerZone]+="$playerCards"
	(( gameZoneCardsTotal[playerZone] += playerCardsTotal ))
	playerCardsTotal=0
	playerCards=
	(( gameZone[playerZone] == wastePile )) && (( wastePileIndex++ ))
	(( gameZone[playerZone] == foundationPile )) && (( completedCardsTotal++ ))

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

validatePickUpCards() {
	(( gameZoneCardsTotal[playerZone] == 0 )) && return 1

	(( gameZone[playerZone] == wastePile )) && \
	(( wastePileIndex == 0 )) && return 1

	if (( playerPileIndex == 0)) && \
	   (( gameZone[playerZone] != foundationPile ))
	then
		checkAutoMove && return 1
	fi

	return 0
}

checkAutoMove() {
	local playerBottomCard="${gameZoneCards[playerZone]##*${space}}"
	local n targetZone

	for (( n = 0; n < foundationZoneTotal; n++ ))
	do
		targetZone="${foundationZone[n]}"
		checkPlaceDownFoundationPile "$playerBottomCard" "$targetZone" && \
		macroAutoMove && return 0
	done

	return 1
}

macroAutoMove() {
	pickUpCards
	movePlayerToZone "$targetZone"
	placeDownCards
	movePlayerToZone "$lastPickupZone"
	return 0
}

pickUpCards() {
	local cards cardsTotal

	drawGameZone false "$playerZone"
	drawCursor false "$playerZone"

	cards=(${gameZoneCards[playerZone]})
	cardsTotal="${#cards[@]}"

	playerCardsTotal=$(( playerPileIndex + 1 ))
	playerCards="${cards[*]: -playerCardsTotal}"
	gameZoneCards[playerZone]="${cards[*]::cardsTotal - playerCardsTotal}"
	(( gameZoneCardsTotal[playerZone] -= playerCardsTotal ))
	lastPickupZone="$playerZone"
	(( gameZone[playerZone] == wastePile )) && (( wastePileIndex-- ))
	(( gameZone[playerZone] == foundationPile )) && (( completedCardsTotal-- ))

	playerSelect=true

	drawGameZone true "$playerZone"
	drawCursor true "$playerZone"
}

macroQuickSelect() {
	local targetZone="$1"

	movePlayerToZone "$targetZone"

	if ! $playerSelect
	then
		validatePickUpCards || return
		local maxVisible="$(( gameZoneCardsTotal[playerZone] - gameZoneHidden[playerZone] - 1 ))"
		moveRangeCursorBy "$maxVisible"
		pickUpCards
	else
		togglePlayerSelect
	fi
}

macroQuickDeal() {
	if $playerSelect
	then
		if (( gameZone[playerZone] == wastePile ))
		then
			togglePlayerSelect
			dealToWastePile
			togglePlayerSelect
		fi
	else
		(( wastePileIndex == 0 )) && dealToWastePile
		movePlayerToZone "$wasteZone"
		togglePlayerSelect
	fi
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
	playerPileIndex=0
	playerSelect=false
	playerCards=
	playerCardsTotal=0
	lastPickupZone=
	wastePileIndex=0
}

winGame() {
	drawCursor false "$playerZone"
	draw 18 8 "You win! Press any key to quit."
    builtin printf "$buffer"
    buffer=
    quitGame
}

quitGame() {
	gameOn=false
    kill -SIGUSR1 $$
}

reader() {
# Reads user input and maps keyboard to commands

	trap exit SIGUSR1
	local input output

	while IFS= read -sn 1 input
	do
		case "$input" in
			q) output="$commandQuit";;

	        A) output="$commandMoveUp";;
	        B) output="$commandMoveDown";;
	        C) output="$commandMoveRight";;
	        D) output="$commandMoveLeft";;
	        ' ') output="$commandAction";;
	        c) output="$commandCycleColors";;
	        n) output="$commandNewGame";;

	        a) output="$macroSelect1";;
	        s) output="$macroSelect2";;
	        d) output="$macroSelect3";;
	        f) output="$macroSelect4";;
	        g) output="$macroSelect5";;
	        h) output="$macroSelect6";;
	        j) output="$macroSelect7";;
	        w) output="$macroDeal";;
		esac

		[ -n "$output" ] && builtin printf "$output"
		(( output == commandQuit )) && break
		output=
	done
}

controller() {
# Takes input from reader and executes commands
# Redraws display after each command

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

	commands[macroSelect1]='macroQuickSelect 7'
	commands[macroSelect2]='macroQuickSelect 8'
	commands[macroSelect3]='macroQuickSelect 9'
	commands[macroSelect4]='macroQuickSelect 10'
	commands[macroSelect5]='macroQuickSelect 11'
	commands[macroSelect6]='macroQuickSelect 12'
	commands[macroSelect7]='macroQuickSelect 13'
	commands[macroDeal]='macroQuickDeal'

	while $gameOn
	do
        builtin printf "$buffer"
        buffer=
        read -sn 2 input
        ${commands[$input]}
        (( completedCardsTotal == cardTotal )) && winGame
    done
}

# ===========================================================================
#      Main script
# ===========================================================================

tput clear
trap '' SIGUSR1
userSettings=$(stty -g)  # save user terminal state
tput civis               # turn off cursor
gameOn=true

createObjects
setColors
setGameZones
newGame
reader | controller  # pipe reader output into controller input and run both in parallel

tput clear
tput cnorm            # turn on cursor
stty "$userSettings"  # restore user terminal state
