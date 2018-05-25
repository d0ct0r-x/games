#!/bin/bash

# Declare variables
frameSpeed=0.01
framesPerGameCycle=5
frameCounter=0
rowTotal=18
columnTotal=10
gridCellTotal=$(( rowTotal * columnTotal ))
lastRow=$(( rowTotal - 1 ))
lastColumn=$(( columnTotal - 1 ))
playerRowStart=1
playerColumnStart=4
gridState=()
gridColor=()
emptyCell="  "
gridBg="  "
gridWallEven="╩╦"
gridWallOdd="╦╩"

colorReset="$(tput sgr0)"
colorBgBlack="$(tput setab 0)"
colorBgGrey="$(tput setab 8)"
colorBgLightGrey="$(tput setab 7)"
colorBgWhite="$(tput setab 15)"
colorBgLightRed="$(tput setab 9)"
colorBgLightGreen="$(tput setab 10)"
colorBgLightYellow="$(tput setab 11)"
colorBgLightBlue="$(tput setab 12)"
colorBgLightPink="$(tput setab 13)"
colorBgLightCyan="$(tput setab 14)"

colorBgOrange="$(tput setab 202)"

colorFgBlack="$(tput setaf 0)"
colorFgLightGrey="$(tput setaf 7)"
colorFgGrey="$(tput setaf 8)"

gridBgColor="${colorFgGrey}${colorBgLightGrey}"
gridWallColor="${colorFgLightGrey}${colorBgGrey}"

gridWallEven="${gridWallColor}${gridWallEven}${colorReset}"
gridWallOdd="${gridWallColor}${gridWallOdd}${colorReset}"

allShapeIds=()
allShapeStateIds=()
allShapeRowOffsets=()
allShapeColumnOffsets=()

# 0=O 1=I 2=Z 3=S 4=T 5=L 6=J
allShapeColors=(
	"$colorBgLightCyan"
	"$colorBgLightRed"
	"$colorBgLightGreen"
	"$colorBgLightBlue"
	"$colorBgGrey"
	"$colorBgLightYellow"
	"$colorBgLightPink"
)

# shape state x y
# 0=O 1=I 2=Z 3=S 4=T 5=L 6=J
encodedShapeData='H4sIAF/hB1sAA02QyxHEIAxD71RBA5nxv//SltgS2UuswJPEWLZs3bKkp/Y8ap2z/bwXCuCd1rOv
jEIhdBkthgxDpp3v8yekRXt9PCME8yV80EZgcvQEewKegCeYGrTEtRgII2EkHITv7/8QyZcl6xI1
eZ+WLEz0JGMThTObuLkO1Hs5xfhCfGFrxa0VwottNS2fkhYznczsDSe6fv6pBMHpAQAA'
shapeData=$(base64 -d <<< "$encodedShapeData" | gunzip)

# Declare functions
loadShapeData() {
	n=0

	while read col1 col2 col3 col4
	do
		allShapeIds[n]="$col1"
		allShapeStateIds[n]="$col2"
		allShapeColumnOffsets[n]="$col3"
		allShapeRowOffsets[n]="$col4"
		(( n++ ))
	done <<< "$shapeData"

	(( allShapeTotal = ${allShapeIds[@]: -1} + 1 ))
}

setShape() {
	currentShapeId="$1"

	currentShapeStateIds=()
	currentShapeRowOffsets=()
	currentShapeColumnOffsets=()
	currentShapeColor="${allShapeColors[$currentShapeId]}"
	currentShapeStateTotal=0

	for n in "${!allShapeIds[@]}"
	do
		if (( allShapeIds[n] == currentShapeId ))
		then
			currentShapeStateIds+=("${allShapeStateIds[$n]}")
			currentShapeRowOffsets+=("${allShapeRowOffsets[$n]}")
			currentShapeColumnOffsets+=("${allShapeColumnOffsets[$n]}")
		fi
	done

	(( currentShapeStateTotal = ${currentShapeStateIds[@]: -1} + 1 ))
}

setShapeState() {
	currentShapeStateId="$1"
	currentStateRowOffsets=()
	currentStateColumnOffsets=()

	for n in "${!currentShapeStateIds[@]}"
	do
		if (( currentShapeStateIds[n] == currentShapeStateId ))
		then
			currentStateRowOffsets+=("${currentShapeRowOffsets[$n]}")
			currentStateColumnOffsets+=("${currentShapeColumnOffsets[$n]}")
		fi
	done
}

getShapeState() {
	local nextShapeStateId="$1"
	nextStateRowOffsets=()
	nextStateColumnOffsets=()

	for n in "${!currentShapeStateIds[@]}"
	do
		if (( currentShapeStateIds[n] == nextShapeStateId ))
		then
			nextStateRowOffsets+=("${currentShapeRowOffsets[$n]}")
			nextStateColumnOffsets+=("${currentShapeColumnOffsets[$n]}")
		fi
	done
}

setPlayer() {
	playerRows=([0]="${playerRows[0]}")
	playerColumns=([0]="${playerColumns[0]}")

	for n in "${!currentStateRowOffsets[@]}"
	do
		playerRows+=($(( playerRows[0] + currentStateRowOffsets[n] )))
		playerColumns+=($(( playerColumns[0] + currentStateColumnOffsets[n] )))
	done
}

initGrid() {
	for (( n = 0; n < gridCellTotal; n++ ))
	do
		gridState+=("0")
		gridColor+=("${gridBgColor}${gridBg}${colorReset}")
	done
}

setGridCellOn() {
	local column="$1"
	local row="$2"
	local color="$3"

	(( column < 0 || row < 0 )) && return

	local n=$(( row * columnTotal + column ))

	gridState["$n"]=1
	gridColor["$n"]="${color}${colorFgLightGrey}${emptyCell}${colorReset}"
}

setGridCellOff() {
	local column="$1"
	local row="$2"

	(( column < 0 || row < 0 )) && return

	local n=$(( row * columnTotal + column ))

	gridState["$n"]=0
	gridColor["$n"]="${gridBgColor}${gridBg}${colorReset}"
}

drawGridWall() {
	(( row % 2 == 0 )) && gridString+="$gridWallEven" || gridString+="$gridWallOdd"
}

drawGrid() {
	gridString=

	for (( row = 0; row < rowTotal; row++ ))
	do
		drawGridWall

		for (( column = 0; column < columnTotal; column++ ))
		do
			n=$(( row * columnTotal + column ))
			gridString+="${gridColor[$n]}"
		done

		drawGridWall

		gridString+="\n"
	done

	tput cup 0 0  # reset cursor to top left of screen
	echo -e "$gridString"
}

newGame() {
	input='\0'
	tput clear
	trap nextFrame ALRM
}

quitGame() {
	tput clear
	tput cnorm  # turn on cursor
	exit
}

readInput() {
	case "$input" in
		# A) ;;
        B) movePlayerDown;;
        C) movePlayerRight;;
        D) movePlayerLeft;;

		z) rotatePlayerClockwise;;
		x) rotatePlayerAnticlockwise;;

		0|1|2|3|4|5|6) debugShape;;
	esac
}

debugShape() {
	setShape "$input"
	input='\0'
	setShapeState 0
	setPlayer
}

movePlayerDown() {
	input='\0' && ! isCollisionBelow && incrementPlayerRowsBy 1
}

movePlayerLeft() {
	input='\0' && ! isCollisionLeft && incrementPlayerColumnsBy -1
}

movePlayerRight() {
	input='\0' && ! isCollisionRight && incrementPlayerColumnsBy 1
}

rotatePlayerClockwise() {
	input='\0' && ! isCollisionAfterRotateClockwise && applyRotation
}

rotatePlayerAnticlockwise() {
	input='\0' && ! isCollisionAfterRotateAnticlockwise && applyRotation
}

incrementPlayerRowsBy() {
	local increment="$1"

	for n in "${!playerRows[@]}"
	do
		(( playerRows[n] += increment ))
	done
}

incrementPlayerColumnsBy() {
	local increment="$1"

	for n in "${!playerColumns[@]}"
	do
		(( playerColumns[n] += increment ))
	done
}

isCollisionBelow() {
	for i in "${!playerRows[@]}"
	do
		(( playerRows[i] == lastRow )) && return 0

		n=$(( (playerRows[i] + 1) * columnTotal + playerColumns[i] ))
		(( gridState[n] == 1 )) && return 0
	done

	return 1
}

isCollisionLeft() {
	for i in "${!playerRows[@]}"
	do
		(( playerColumns[i] == 0 )) && return 0

		n=$(( playerRows[i] * columnTotal + (playerColumns[i] - 1) ))
		(( gridState[n] == 1 )) && return 0
	done

	return 1
}

isCollisionRight() {
	for i in "${!playerRows[@]}"
	do
		(( playerColumns[i] == lastColumn )) && return 0

		n=$(( playerRows[i] * columnTotal + (playerColumns[i] + 1) ))
		(( gridState[n] == 1 )) && return 0
	done

	return 1
}

isCollisionAfterRotateClockwise() {
	calculateRotationBy 1
	getShapeState "$nextShapeStateId"
	getNextPlayer

	for i in "${!nextPlayerRows[@]}"
	do
		(( nextPlayerRows[i] == rowTotal )) && return 0
		(( nextPlayerColumns[i] == -1 )) && return 0
		(( nextPlayerColumns[i] == columnTotal )) && return 0

		n=$(( nextPlayerRows[i] * columnTotal + nextPlayerColumns[i] ))
		(( gridState[n] == 1 )) && return 0
	done

	return 1
}

isCollisionAfterRotateAnticlockwise() {
	calculateRotationBy -1
	getShapeState "$nextShapeStateId"
	getNextPlayer

	for i in "${!nextPlayerRows[@]}"
	do
		(( nextPlayerRows[i] == rowTotal )) && return 0
		(( nextPlayerColumns[i] == -1 )) && return 0
		(( nextPlayerColumns[i] == columnTotal )) && return 0

		n=$(( nextPlayerRows[i] * columnTotal + nextPlayerColumns[i] ))
		(( gridState[n] == 1 )) && return 0
	done

	return 1
}

calculateRotationBy() {
	local direction="$1"

	(( nextShapeStateId = (currentShapeStateId + direction) % currentShapeStateTotal ))
	(( nextShapeStateId < 0 )) && (( nextShapeStateId += currentShapeStateTotal ))
}

getNextPlayer() {
	nextPlayerRows=()
	nextPlayerColumns=()

	for n in "${!nextStateRowOffsets[@]}"
	do
		nextPlayerRows+=($(( playerRows[0] + nextStateRowOffsets[n] )))
		nextPlayerColumns+=($(( playerColumns[0] + nextStateColumnOffsets[n] )))
	done
}

applyRotation() {
	currentShapeStateId="$nextShapeStateId"
	setShapeState "$currentShapeStateId"
	setPlayer
}

checkForNextGameCycle() {
	if (( frameCounter == 0 ))
	then
		if isCollisionBelow
		then
			addPlayerToGrid
			checkForCompleteRows
			initPlayer
		else
			incrementPlayerRowsBy 1
		fi
	fi
}

checkForCompleteRows() {
	minPlayerRow="${playerRows[0]}"
	maxPlayerRow="$minPlayerRow"

	for row in "${playerRows[@]}"
	do
	    (( row < minPlayerRow )) && minPlayerRow="$row"
	    (( row > maxPlayerRow )) && maxPlayerRow="$row"
	done

	searchRow="$maxPlayerRow"
	completeRowCounter=0
	limit=0

	while :
	do
		completeColumnCounter=0

		for (( column = 0; column < columnTotal; column++ ))
		do
			n=$(( searchRow * columnTotal + column ))
			(( completeColumnCounter += gridState[n] ))
		done

		if (( completeColumnCounter == 0 ||
			  searchRow < 0 ||
			  (searchRow < minPlayerRow && completeRowCounter == 0) ))
		then
			break
		elif (( completeColumnCounter == columnTotal ))
		then
			(( completeRowCounter++ ))
			clearRow "$searchRow"
			(( searchRow-- ))
		elif (( completeRowCounter > 0 ))
		then
			moveRowDownByDistance "$completeRowCounter"
			clearRow "$searchRow"
			(( searchRow-- ))
		else
			(( searchRow-- ))
		fi
	done
}

clearRow() {
	local row="$1"

	for (( column = 0; column < columnTotal; column++ ))
	do
		setGridCellOff "$column" "$row"
	done
}

moveRowDownByDistance() {
	local distance="$1"

	for (( column = 0; column < columnTotal; column++ ))
	do
		sourceRowIndex=$(( searchRow * columnTotal + column ))
		targetRowIndex=$(( (searchRow + distance) * columnTotal + column ))

		gridState[targetRowIndex]="${gridState[sourceRowIndex]}"
		gridColor[targetRowIndex]="${gridColor[sourceRowIndex]}"
	done
}

addPlayerToGrid() {
	for n in "${!playerRows[@]}"
	do
		setGridCellOn "${playerColumns[$n]}" "${playerRows[$n]}" "$currentShapeColor"
	done
}

removePlayerFromGrid() {
	for n in "${!playerRows[@]}"
	do
		setGridCellOff "${playerColumns[$n]}" "${playerRows[$n]}"
	done
}

debugPlayer() {
	for n in "${!playerRows[@]}"
	do
		echo "(${playerColumns[n]}, ${playerRows[n]})"
	done
}

initPlayer() {
	playerRows[0]="$playerRowStart"
	playerColumns[0]="$playerColumnStart"

	setShape "$(( RANDOM % allShapeTotal ))"
	setShapeState 0
	setPlayer
}

nextFrame() {
	# [ "$gameOver" == true ] && gameOver
	
	addPlayerToGrid

	drawGrid

	removePlayerFromGrid

	checkForNextGameCycle

	readInput

	(( frameCounter == framesPerGameCycle )) && frameCounter=0 || (( frameCounter++ ))

    ( sleep $frameSpeed; kill -ALRM $$ )&
}

loadShapeData

initGrid
initPlayer

# Main game loop
tput civis  # turn off cursor
trap quitGame ERR EXIT
newGame
nextFrame

# Input loop
while :
do
    read -rsn 1 input
done
