#!/bin/bash

colorReset='\033[0m'
colorFgRed='\033[31m'

colorFgWhite='\033[97m'
colorFgLightGrey='\033[37m'
colorFgGrey='\033[90m'
colorFgBlack='\033[30m'
# colorFg256LightGreen='\033[38;5;187m'
# colorFg256Green='\033[38;5;144m'
# colorFg256DarkGreen='\033[38;5;101m'
colorFg256LightGreen='\033[38;5;194m'
colorFg256Green='\033[38;5;71m'
colorFg256DarkGreen='\033[38;5;23m'

colorBgWhite='\033[107m'
colorBgLightGrey='\033[47m'
colorBgGrey='\033[100m'
colorBgBlack='\033[40m'
# colorBg256LightGreen='\033[48;5;187m'
# colorBg256Green='\033[48;5;144m'
# colorBg256DarkGreen='\033[48;5;101m'
colorBg256LightGreen='\033[48;5;194m'
colorBg256Green='\033[48;5;71m'
colorBg256DarkGreen='\033[48;5;23m'

colorFg8bit=("$colorFgWhite" "$colorFgLightGrey" "$colorFgGrey" "$colorFgBlack")
colorBg8bit=("$colorBgWhite" "$colorBgLightGrey" "$colorBgGrey" "$colorBgBlack")

colorFg256bit=("$colorFg256LightGreen" "$colorFg256Green" "$colorFg256DarkGreen" "$colorFgBlack")
colorBg256bit=("$colorBg256LightGreen" "$colorBg256Green" "$colorBg256DarkGreen" "$colorBgBlack")

colorFg=("${colorFg256bit[@]}")
colorBg=("${colorBg256bit[@]}")

escapeString=
currentAscii=
currentFgc=
currentFgcRaw=
currentBgc=
currentBgcRaw=

convertFile() {
lineNum=0

while IFS=',' read x y ascii fgc bgc
do
	# (( lineNum == 500)) && break
	# echo "'$x' '$y' '$ascii' '$fgc' '$bgc'"
	# echo "curFg='$currentFgc' curFgRaw='$currentFgcRaw' curBg='$currentBgc' curBgRaw='$currentBgcRaw'"
	# echo
	(( lineNum > 0 )) && (( x == 0 )) && escapeString+="${colorReset}\n"
	handleAscii
	handleFgc
	handleBgc
	escapeString+="${currentFgc}${currentBgc}${currentAscii}"
	
	(( lineNum++ ))
done < tetris-title.csv

escapeString+="${colorReset}"

printf "$escapeString"
}

handleAscii() {
	case "$ascii" in
		219) currentAscii='█';;
        223) currentAscii='▀';;
        220) currentAscii='▄';;
        84) currentAscii='T';;
        77) currentAscii='M';;
	esac
}

handleFgc() {
	[[ "$fgc" == "$currentFgcRaw" ]] && (( x > 0 )) && currentFgc= && return
	
	currentFgcRaw="$fgc"

	case "$fgc" in
		'#D9FF66') currentFgc="${colorFg[0]}";;
		'#A3D900') currentFgc="${colorFg[1]}";;
		'#86B200') currentFgc="${colorFg[2]}";;
		'#000000') currentFgc="${colorFg[3]}";;
	esac
}

handleBgc() {
	[[ "$bgc" == "$currentBgcRaw" ]] && (( x > 0 )) && currentBgc= && return
	[[ "$currentAscii" == '█' ]] && currentBgc= && currentBgcRaw= && return

	currentBgcRaw="$bgc"

	case "$bgc" in
		'#D9FF66') currentBgc="${colorBg[0]}";;
		'#A3D900') currentBgc="${colorBg[1]}";;
		'#86B200') currentBgc="${colorBg[2]}";;
		'#000000') currentBgc="${colorBg[3]}";;
	esac
}

convertFile
# wc <<< "$escapeString"

# encodedEscapeString=$(gzip <<< "$escapeString" | base64)
# decodedEscapeString=$(base64 -d <<< "$encodedEscapeString" | gunzip)

# printf '%s\n' "$encodedEscapeString"
# printf "$decodedEscapeString"

