#!/bin/bash

empty=" "
fullBlock="█"
upperHalfBlock="▀"
lowerHalfBlock="▄"

colorNone=""
colorReset="$(tput sgr0)"
colorFgRed="$(tput setaf 1)"
colorFgGreen="$(tput setaf 2)"
colorFgYellow="$(tput setaf 3)"

colorFgLightOlive=$(tput setaf 187)
colorFgOlive=$(tput setaf 101)
colorFgDarkOlive=$(tput setaf 59)
colorFgBlack=$(tput setaf 0)

image=()
imageBlock=()
imageColor=()
input="\0"

cursorX=0
cursorY=0

currentBlockIndex=0
currentColorIndex=0

xMax=80
yMax=25
lastX=$(( xMax - 1 ))
lastY=$(( yMax - 1 ))
imageSize=$(( xMax * yMax ))

blocks=(
	"$empty"
	"$fullBlock"
	"$upperHalfBlock"
	"$lowerHalfBlock"
)

colors=(
	"$colorNone"
	"$colorFgLightOlive"
	"$colorFgOlive"
	"$colorFgDarkOlive"
	"$colorFgBlack"
)

initImage() {
	for (( n = 0; n < imageSize; n++ ))
	do
		imageBlock+=(0)
		imageColor+=(0)
		image+=("${colors[0]}${blocks[0]}")
	done
}

drawImage() {
	imageString=

	for (( y = 0; y < yMax; y++ ))
	do
		for (( x = 0; x < xMax; x++ ))
		do
			n=$(( y * xMax + x ))
			imageString+="${image[n]}"
		done

		imageString+="|\n"
	done

	for (( x = 0; x < xMax; x++ ))
	do
		imageString+="-"
	done

	imageString+="+"

	tput cup 0 0
	printf '%b' "$imageString"
	tput cup "$cursorY" "$cursorX"
}

readInput() {
	read -rsn1 input

	case "$input" in
        q) quit;;
		e) exportEscapeString;;

        i) moveCursor up;;
        k) moveCursor down;;
        l) moveCursor right;;
        j) moveCursor left;;

		z) cycleBlockBy 1;;
		x) cycleColorBy 1;;
	esac
}

quit() {
	clear
	exit
}

exportEscapeString() {
	imageString=

	for (( y = 0; y < yMax; y++ ))
	do
		for (( x = 0; x < xMax; x++ ))
		do
			n=$(( y * xMax + x ))
			imageString+="${image[n]}"
		done

		imageString+="\n"
	done

	clear
	printf '%s\n' "${imageString//$'\e'/\\033}"
	exit
}

moveCursor() {
	direction="$1"
	input="\0"

	case "$direction" in
        up) (( cursorY > 0 )) && (( cursorY-- ));;
        down) (( cursorY < lastY )) && (( cursorY++ ));;
        right) (( cursorX < lastX )) && (( cursorX++ ));;
        left) (( cursorX > 0 )) && (( cursorX-- ));;
	esac
}

cycleBlockBy() {
	distance="$1"
	blockTotal="${#blocks[@]}"
	input="\0"
	n=$(( cursorY * xMax + cursorX ))

	currentBlockIndex="${imageBlock[n]}"
	currentColorIndex="${imageColor[n]}"

	(( currentBlockIndex = (currentBlockIndex + distance) % blockTotal ))
	(( currentBlockIndex < 0 )) && (( currentBlockIndex += blockTotal ))

	imageBlock[n]="$currentBlockIndex"
	image[n]="${colors[currentColorIndex]}${blocks[currentBlockIndex]}${colorReset}"
}

cycleColorBy() {
	distance="$1"
	colorTotal="${#colors[@]}"
	input="\0"
	n=$(( cursorY * xMax + cursorX ))

	currentBlockIndex="${imageBlock[n]}"
	currentColorIndex="${imageColor[n]}"

	(( currentColorIndex = (currentColorIndex + distance) % colorTotal ))
	(( currentColorIndex < 0 )) && (( currentColorIndex += colorTotal ))

	imageColor[n]="$currentColorIndex"
	image[n]="${colors[currentColorIndex]}${blocks[currentBlockIndex]}${colorReset}"
}

tput clear
tput cup 0 0
initImage

while :
do
	drawImage
	readInput
	sleep 0.01
done

#     ___    
#    /1\\\       ___ _     
#    //2\\      / 1 \ \  
#               -----






