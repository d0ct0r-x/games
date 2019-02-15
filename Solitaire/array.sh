#!/bin/bash

array1=(1 2 3)
array2=(4 5 6)

themes=("${array1[@]}" "${array2[@]}")
theme=("${array1[@]}")
themeId=0
themeParamsTotal="${#array1[@]}"
themeTotal=$(( ${#themes[@]} / themeParamsTotal ))

cycleColorTheme() {
    (( themeId = (themeId + 1) % themeTotal ))
    theme=("${themes[@]:(themeId * themeParamsTotal):(themeParamsTotal)}")
}

printArray() {
    local array=("$@")
    printf '%s\n' "${array[@]}"
}

cycleColorTheme
echo "$themeId"
printArray "${theme[@]}"

cycleColorTheme
echo "$themeId"
printArray "${theme[@]}"