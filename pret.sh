#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset
IFS=$'\n\t'

# The JSON file name.
json="pret.json"

# Usage information in case of incorrect input.
usage() {
    dialog --msgbox "[ERROR] One command is expected." 10 30
    dialog --msgbox "Usage:
./pret.sh init -- Initialize an empty data store
./pret.sh add CODE DESCRIPTION -- Add a new article identified by CODE with the description
./pret.sh lend CODE WHO -- Lend the article CODE to WHO
./pret.sh retrieve CODE -- Retrieve the article CODE
./pret.sh list items|lends -- List all the items or only the lends items" 15 50
    exit 1
}

# Display an error message and exit.
error_message() {
    local message=$1
    dialog --msgbox "[ERROR] $message" 10 30
    exit 1
}

# Init command.
function init() {
    if [[ -f $json ]]; then
        dialog --yesno "Data already exists. Are you sure you want to delete it?" 7 50
        local answer=$?
        if [[ $answer -eq 0 ]]; then
            echo '{ "items": [], "lends": [] }' > "$json"
            dialog --msgbox "JSON file initialized successfully." 10 30
        fi
    else
        echo '{ "items": [], "lends": [] }' > "$json"
        dialog --msgbox "JSON file initialized successfully." 10 30
    fi
    exit 0
}

# Add command.
function add() {
    local code
    local description
    code=$(dialog --inputbox "Enter the code:" 8 40 3>&1 1>&2 2>&3 3>&1)
    description=$(dialog --inputbox "Enter the description:" 8 40 3>&1 1>&2 2>&3 3>&1)

    jq --arg code "$code" --arg description "$description" \
        '.items += [{"code": $code, "description": $description}]' \
        "$json" >temp.json && mv temp.json "$json"

    dialog --msgbox "Item '$code' has been added successfully." 10 30
    exit 0
}

# Lend command.
function lend() {
    local when
    when=$(date +"%d/%m/%Y")
    local what
    local who
    what=$(dialog --inputbox "Enter the code of the item to lend:" 8 40 3>&1 1>&2 2>&3 3>&1)
    who=$(dialog --inputbox "Enter the name of the person to lend to:" 8 40 3>&1 1>&2 2>&3 3>&1)

    jq --arg when "$when" --arg who "$who" --arg what "$what" \
        '.lends += [{ "when": $when, "to_whom": $who, "what": $what}]' \
        "$json" >temp.json && mv temp.json "$json"

    dialog --msgbox "Item '$what' has been lent successfully." 10 30
    exit 0
}

# Retrieve command.
function retrieve() {
    local code
    code=$(dialog --inputbox "Enter the code of the item to retrieve:" 8 40 3>&1 1>&2 2>&3 3>&1)

    local retrieve  
    retrieve=$(jq --arg code "$code" '.lends |= map(select(.what != $code))' "$json")
    if [ "$(cat "$json")" != "$retrieve" ]; then
        echo "$retrieve" >"$json"
        dialog --msgbox "Item '$code' was retrieved successfully." 10 30
        exit 0
    else
        error_message "Item '$code' hasn't been found."
    fi
}

# List command.
function list() {
    local list
    list=$(dialog --inputbox "Enter 'items' to list items or 'lends' to list lends:" 8 40 3>&1 1>&2 2>&3 3>&1)

    case ${list,,} in
        items)
        jq '.items' "$json" > items_temp.json
        dialog --textbox items_temp.json 20 60
        rm items_temp.json
        ;;
        lends)
        jq '.lends' "$json" > lends_temp.json
        dialog --textbox lends_temp.json 20 60
        rm lends_temp.json
        ;;
    *)
        error_message "Invalid input. Please enter 'items' or 'lends'"
        ;;
    esac
}


# Main script.
if [[ $# -lt 1 ]]; then
    usage
fi

COMMAND="$1"
shift

case "$COMMAND" in
    init) init ;;
    add) add ;;
    lend) lend ;;
    retrieve) retrieve ;;
    list) list ;;
    *) usage ;;
esac

