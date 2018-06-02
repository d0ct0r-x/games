#!/bin/bash

# =======================================================
#      Declare variables
# =======================================================

# -- Config variables (CAN CHANGE) ----------------------
secondsPerFrame=0.01
framesPerGameCycle=10
rowTotal=18
columnTotal=10
playerRowStart=1
playerColumnStart=4
gridCell="  "
gridWallEven="╩╦"
gridWallOdd="╦╩"

# -- Global variables (DO NOT CHANGE) -------------------
gridCellTotal=$(( rowTotal * columnTotal ))
lastRow=$(( rowTotal - 1 ))
lastColumn=$(( columnTotal - 1 ))
resetCursor='\033[1;1H'
userSettings=$(stty -g)  # save user terminal state
helpMessage='
Use arrow keys to move
  z = rotate clockwise
  x = rotate anticlockwise
  q = quit
'

# -- Color variables ------------------------------------
colorReset='\033[0m'

colorFgLightGrey16Bit='\033[37m'

colorBgBlack16Bit='\033[40m'
colorBgGrey16Bit='\033[100m'
colorBgLightGrey16Bit='\033[47m'
colorBgWhite16Bit='\033[107m'
colorBgLightRed16Bit='\033[101m'
colorBgLightGreen16Bit='\033[102m'
colorBgLightYellow16Bit='\033[103m'
colorBgLightBlue16Bit='\033[104m'
colorBgLightPink16Bit='\033[105m'
colorBgLightCyan16Bit='\033[106m'

colorFgLightBlue256Bit='\033[38;5;116m'

colorBgLightBlue256Bit='\033[48;5;116m'
colorBgDarkBlue256Bit='\033[48;5;25m'
colorBgYellow256Bit='\033[48;5;221m'
colorBgCyan256Bit='\033[48;5;33m'
colorBgRed256Bit='\033[48;5;203m'
colorBgGreen256Bit='\033[48;5;35m'
colorBgPurple256Bit='\033[48;5;98m'
colorBgOrange256Bit='\033[48;5;209m'

# -- Shape color config  --------------------------------
# 0=O 1=I 2=Z 3=S 4=T 5=L 6=J
allShapeColors256Bit=(
	"$colorBgYellow256Bit"
	"$colorBgCyan256Bit"
	"$colorBgRed256Bit"
	"$colorBgGreen256Bit"
	"$colorBgPurple256Bit"
	"$colorBgOrange256Bit"
	"$colorBgDarkBlue256Bit"
)
gridCellColor256Bit="${colorBgLightBlue256Bit}"
gridWallColor256Bit="${colorFgLightBlue256Bit}${colorBgDarkBlue256Bit}"

# 0=O 1=I 2=Z 3=S 4=T 5=L 6=J
allShapeColors16Bit=(
	"$colorBgLightCyan16Bit"
	"$colorBgLightRed16Bit"
	"$colorBgLightGreen16Bit"
	"$colorBgLightBlue16Bit"
	"$colorBgGrey16Bit"
	"$colorBgLightYellow16Bit"
	"$colorBgLightPink16Bit"
)
gridCellColor16Bit="${colorBgLightGrey16Bit}"
gridWallColor16Bit="${colorFgLightGrey16Bit}${colorBgGrey16Bit}"

if [[ "$TERM" = 'xterm-256color' ]]
then
	allShapeColors=("${allShapeColors256Bit[@]}")
	gridCellColor="$gridCellColor256Bit"
	gridWallColor="$gridWallColor256Bit"
else
	allShapeColors=("${allShapeColors16Bit[@]}")
	gridCellColor="$gridCellColor16Bit"
	gridWallColor="$gridWallColor16Bit"
fi

gridWallEven="${gridWallColor}${gridWallEven}"
gridWallOdd="${gridWallColor}${gridWallOdd}"

# -- Shape state config  --------------------------------
# shape state x y
# 0=O 1=I 2=Z 3=S 4=T 5=L 6=J
encodedShapeData='H4sIAF/hB1sAA02QyxHEIAxD71RBA5nxv//SltgS2UuswJPEWLZs3bKkp/Y8ap2z/bwXCuCd1rOv
jEIhdBkthgxDpp3v8yekRXt9PCME8yV80EZgcvQEewKegCeYGrTEtRgII2EkHITv7/8QyZcl6xI1
eZ+WLEz0JGMThTObuLkO1Hs5xfhCfGFrxa0VwottNS2fkhYznczsDSe6fv6pBMHpAQAA'
shapeData=$(base64 -d <<< "$encodedShapeData" | gunzip)

allShapeIds=()
allShapeStateIds=()
allShapeRowOffsets=()
allShapeColumnOffsets=()

# =======================================================
#      Declare functions
# =======================================================

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

newGame() {
	clear
	input="\0"
	frameCounter=0
	initGrid
	initPlayer
	trap nextFrame ALRM
}

initGrid() {
	gridCellStates=()
	gridCellColors=()

	for (( n = 0; n < gridCellTotal; n++ ))
	do
		gridCellStates+=("0")
		gridCellColors+=("${gridCellColor}${gridCell}")
	done
}

initPlayer() {
	playerRows[0]="$playerRowStart"
	playerColumns[0]="$playerColumnStart"

	setShape "$(( RANDOM % allShapeTotal ))"
	setShapeState 0
	setPlayer
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

setPlayer() {
	playerRows=([0]="${playerRows[0]}")
	playerColumns=([0]="${playerColumns[0]}")

	for n in "${!currentStateRowOffsets[@]}"
	do
		playerRows+=($(( playerRows[0] + currentStateRowOffsets[n] )))
		playerColumns+=($(( playerColumns[0] + currentStateColumnOffsets[n] )))
	done
}

# Main frame loop
nextFrame() {
	addPlayerToGrid

	drawGrid

	removePlayerFromGrid

	checkForNextGameCycle

	readInput

	incrementFrameClock

    scheduleNextFrame
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

setGridCellOn() {
	local column="$1"
	local row="$2"
	local color="$3"

	(( column < 0 || row < 0 )) && return

	local n=$(( row * columnTotal + column ))

	gridCellStates["$n"]=1
	gridCellColors["$n"]="${color}${gridCell}"
}

setGridCellOff() {
	local column="$1"
	local row="$2"

	(( column < 0 || row < 0 )) && return

	local n=$(( row * columnTotal + column ))

	gridCellStates["$n"]=0
	gridCellColors["$n"]="${gridCellColor}${gridCell}"
}

drawGrid() {
	gridString="$resetCursor"

	for (( row = 0; row < rowTotal; row++ ))
	do
		drawGridWall

		for (( column = 0; column < columnTotal; column++ ))
		do
			n=$(( row * columnTotal + column ))
			gridString+="${gridCellColors[$n]}"
		done

		drawGridWall

		gridString+="${colorReset}\n"
	done

	gridString+="$helpMessage"

	builtin printf "$gridString"
}

drawGridWall() {
	(( row % 2 == 0 )) && gridString+="$gridWallEven" || gridString+="$gridWallOdd"
}

checkForNextGameCycle() {
	if (( frameCounter == 0 ))
	then
		if isCollisionBelow
		then
			(( playerRows[0] == playerRowStart )) && gameOver
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

	while :
	do
		completeColumnCounter=0

		for (( column = 0; column < columnTotal; column++ ))
		do
			n=$(( searchRow * columnTotal + column ))
			(( completeColumnCounter += gridCellStates[n] ))
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

		gridCellStates[targetRowIndex]="${gridCellStates[sourceRowIndex]}"
		gridCellColors[targetRowIndex]="${gridCellColors[sourceRowIndex]}"
	done
}

readInput() {
	case "$input" in
		q) quitGame;;

        B) movePlayerDown;;
        C) movePlayerRight;;
        D) movePlayerLeft;;

		z) rotatePlayerClockwise;;
		x) rotatePlayerAnticlockwise;;
	esac
}

movePlayerDown() {
	input="\0" && ! isCollisionBelow && incrementPlayerRowsBy 1
}

movePlayerLeft() {
	input="\0" && ! isCollisionLeft && incrementPlayerColumnsBy -1
}

movePlayerRight() {
	input="\0" && ! isCollisionRight && incrementPlayerColumnsBy 1
}

rotatePlayerClockwise() {
	input="\0" && ! isCollisionAfterRotateClockwise && applyRotation
}

rotatePlayerAnticlockwise() {
	input="\0" && ! isCollisionAfterRotateAnticlockwise && applyRotation
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
		(( gridCellStates[n] == 1 )) && return 0
	done

	return 1
}

isCollisionLeft() {
	for i in "${!playerRows[@]}"
	do
		(( playerColumns[i] == 0 )) && return 0

		n=$(( playerRows[i] * columnTotal + (playerColumns[i] - 1) ))
		(( gridCellStates[n] == 1 )) && return 0
	done

	return 1
}

isCollisionRight() {
	for i in "${!playerRows[@]}"
	do
		(( playerColumns[i] == lastColumn )) && return 0

		n=$(( playerRows[i] * columnTotal + (playerColumns[i] + 1) ))
		(( gridCellStates[n] == 1 )) && return 0
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
		(( gridCellStates[n] == 1 )) && return 0
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
		(( gridCellStates[n] == 1 )) && return 0
	done

	return 1
}

calculateRotationBy() {
	local direction="$1"

	(( nextShapeStateId = (currentShapeStateId + direction) % currentShapeStateTotal ))
	(( nextShapeStateId < 0 )) && (( nextShapeStateId += currentShapeStateTotal ))
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

incrementFrameClock() {
	(( frameCounter = (frameCounter + 1) % framesPerGameCycle ))
}

scheduleNextFrame() {
	( sleep $secondsPerFrame; kill -ALRM $$ )&
}

gameOver() {
	trap : ALRM
	read -rsn1 -p 'GAME OVER!'
	quitGame
}

quitGame() {
	clear
	tput cnorm            # turn on cursor
	stty "$userSettings"  # restore user terminal state
	exit
}

# =======================================================
#      SCRIPT START
# =======================================================

loadShapeData
tput civis              # turn off cursor
trap quitGame ERR EXIT

# Main game loop
newGame
nextFrame

# Input loop
while :
do
    read -rsn 1 input
done

# =======================================================
#      SCRIPT END
# =======================================================
