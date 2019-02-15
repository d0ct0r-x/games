#!/bin/bash

stock='1 2 3 4 5 6'
stockTotal=6
waste=
wasteTotal=0
wasteLimit=3
wasteIndex="$wasteLimit"

printStep() {
    local array=($waste)
    local visible="${array[*]: -wasteIndex}"
    printf '%-10s %-15s %-15s %-15s\n' "${FUNCNAME[1]} ->" "[${stock}]" "[${waste}]" "[${visible}]"
}

init(){
    printStep
    echo
}

deal() {
    local array=($stock)
    local takeTotal

    if (( stockTotal > 0 ))
    then
        takeTotal=$(( stockTotal < wasteLimit ? stockTotal : wasteLimit ))
        (( wasteTotal > 0 )) && waste+=" "
        waste+="${array[*]::takeTotal}"
        stock="${array[*]:takeTotal}"
        (( wasteTotal += takeTotal ))
        (( stockTotal -= takeTotal ))
        wasteIndex="$takeTotal"
    else
        stock="$waste"
        waste=
        stockTotal="$wasteTotal"
        wasteTotal=0
        wasteIndex=0
    fi

    printStep
}

take() {
    (( wasteTotal == 0 )) && printStep && return

    local array=($waste)
    (( wasteTotal-- ))
    (( wasteIndex-- ))
    waste="${array[*]::wasteTotal}"

    printStep
}

init
deal
take
deal
take
deal
take
deal