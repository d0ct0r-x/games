#!/bin/bash

# Declare variables
frameSpeed=0.01
framesPerGameCycle=1
frameCounter=0
rowTotal=18
columnTotal=10
lastRow=$(( rowTotal - 1 ))
lastColumn=$(( columnTotal - 1 ))
gridState=()
gridColor=()
emptyCell="  "

colorReset='\033[0m'
colorBgRed='\033[0;41m'
colorBgGreen='\033[0;42m'
colorBgYellow='\033[0;43m'
colorBgBlue='\033[0;44m'
colorBgCyan='\033[0;46m'

# Declare functions
initGrid() {
	for (( n = 0; n < rowTotal * columnTotal; n++ ))
	do
		gridState["$n"]=0
		gridColor["$n"]="$emptyCell"
	done
}

setGridCellOn() {
	local row="$1"
	local column="$2"
	local color="$3"
	local n=$(( row * columnTotal + column ))

	gridState["$n"]=1
	gridColor["$n"]="${color}${emptyCell}${colorReset}"
}

setGridCellOff() {
	local row="$1"
	local column="$2"
	local n=$(( row * columnTotal + column ))

	gridState["$n"]=0
	gridColor["$n"]="${emptyCell}"
}

drawGrid() {
	gridString=

	for (( row = 0; row < rowTotal; row++ ))
	do
		gridString+="║"

		for (( column = 0; column < columnTotal; column++ ))
		do
			n=$(( row * columnTotal + column ))
			gridString+="${gridColor[$n]}"
		done

		gridString+="║\n"
	done

	gridString+="╚"

	for (( column = 0; column < columnTotal; column++ ))
	do
		gridString+="══"
	done

	gridString+="╝"

	tput cup 0 0  # reset cursor to top left of screen
	# clear
	echo -e "$gridString"
}

newGame() {
	input='\0'
	# clearFixedGrid
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
		A) ;;
        B) input='\0' && (( playerRow < lastRow )) && ! isCellBelow && (( playerRow++ ));;           # down
        C) input='\0' && (( playerColumn < lastColumn )) && ! isCellRight && (( playerColumn++ ));;  # right
        D) input='\0' && (( playerColumn > 0 )) && ! isCellLeft && (( playerColumn-- ));;             # left
	esac
}

playerRow=0
playerColumn=4
playerColor="$colorBgRed"
initGrid

isCellBelow() {
	local n=$(( (playerRow + 1) * columnTotal + playerColumn ))
	(( gridState[n] == 1 )) && return 0 || return 1
}

isCellLeft() {
	local n=$(( playerRow * columnTotal + (playerColumn - 1) ))
	(( gridState[n] == 1 )) && return 0 || return 1
}

isCellRight() {
	local n=$(( playerRow * columnTotal + (playerColumn + 1) ))
	(( gridState[n] == 1 )) && return 0 || return 1
}

checkForNextGameCycle() {
	if (( frameCounter == 0 ))
	then
		if isCellBelow
		then
			setGridCellOn "$playerRow" "$playerColumn" "$colorBgCyan"
			playerRow=0
		elif (( playerRow == lastRow ))
		then
			setGridCellOn "$playerRow" "$playerColumn" "$colorBgCyan"
			playerRow=0
		else
			(( playerRow++ ))
		fi
		checkCompleteRows
	fi
}

checkCompleteRows() {
	completeRows=()
	completeRowsCounter=0
	completeColumns=0

	for (( row = 0; row < rowTotal; row++ ))
	do
		for (( column = 0; column < columnTotal; column++ ))
		do
			n=$(( row * columnTotal + column ))
			(( completeColumns += gridState[n] ))
		done

		(( completeColumns == columnTotal )) && completeRows+=("$row") && (( completeRowsCounter++ ))
		completeColumns=0
	done

	if (( completeRowsCounter > 0 ))
	then
		for row in "${completeRows[@]}"
		do
			for (( column = 0; column < columnTotal; column++ ))
			do
				setGridCellOn "$row" "$column" "$colorBgGreen"
			done

		done
	fi
}

nextFrame() {
	# [ "$gameOver" == true ] && gameOver
	# draw
	# calculate
	# readInput


	setGridCellOn "$playerRow" "$playerColumn" "$playerColor"

	drawGrid

	setGridCellOff "$playerRow" "$playerColumn"

	checkForNextGameCycle



	# if (( playerRow == lastRow ))
	# then
	# 	setGridCellOn "$playerRow" "$playerColumn" "$playerColor"
	# 	playerRow=0
	# fi

	# (( playerRow == lastRow )) && playerRow=0

	readInput

	(( frameCounter == framesPerGameCycle )) && frameCounter=0 || (( frameCounter++ ))

    ( sleep $frameSpeed; kill -ALRM $$ )&
}

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

# setGridCellOn 0 5 "$colorBgRed"

# initGrid

# setGridCellOn 0 5 "$colorBgRed"
# setGridCellOn 3 9 "$colorBgBlue"
# # setGridCellOff 0 5

# drawActiveGrid

# for i in {1..20}
# do
# 	clear
# 	initGrid
# 	(( playerRow++ ))
# 	setGridCellOn "$playerRow" "$playerColumn" "$colorBgRed"
# 	drawActiveGrid
# 	sleep 0.05
# done





# echo -e "${coloredSquare}${coloredSquare}${coloredSquare}"
# echo -e "${emptySquare}${coloredSquare}${emptySquare}"
# echo

# echo -e "${emptySquare}${coloredSquare}"
# echo -e "${coloredSquare}${coloredSquare}"
# echo -e "${emptySquare}${coloredSquare}"

# echo "
# ║000000000000000000║
# ║000000000000000000║
# ║000000000000000000║
# ║000000000000000000║
# ║000000000000000000║
# ║000000000000000000║
# ║000000000000000000║
# ║000000000000000000║
# ║000000000000000000║
# ║000000000000000000║
# ║000000000000000000║
# ║000000000000000000║
# ║000000000000000000║
# ║000000000000000000║
# ║000000000000000000║
# ║000000000000000000║
# ║000000000000000000║
# ║000000000000000000║
# ╚══════════════════╝
# "