#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# MIT License
# Copyright (c) 2025 Filis Futsarov
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# Absence.IO API docs
# https://documenter.getpostman.com/view/799228/absenceio-api-documentation/2Fwbis#030e6fd3-051f-4c14-ae14-b5290a9335d8

# Determine if we're interactive or not
use_ansi() { test -t 1; }

# only output colors if our output is to terminal
# https://misc.flogisoft.com/bash/tip_colors_and_formatting
if use_ansi ; then
    GREEN="\033[0;32m"
    RED="\033[0;31m"
    BOLD="\033[1m"
    BOLD_GREEN="\033[1;32m"
    CLEAR="\033[0m"
else
    GREEN=""
    RED=""
    BOLD=""
    BOLD_GREEN=""
    CLEAR=""
fi

# ANSI color output helpers
function green() { echo -en "${GREEN}"$@"${CLEAR}"; }
function red() { echo -en "${RED}"$@"${CLEAR}"; }
function bold() { echo -en "${BOLD}"$@"${CLEAR}"; }
function bold_green() { echo -en "${BOLD_GREEN}"$@"${CLEAR}"; }
function normal() { echo -en "${CLEAR}"$@"${CLEAR}"; }
function str_pad() {
  local str="$1"
  local length="$2"
  local pad_char="${3:- }"

  # Calculate how many characters to add
  local str_length=${#str}
  if (( str_length >= length )); then
    echo "$str" # No padding needed
  else
    local padding=$(( length - str_length ))
    local padded_str="$str"
    
    # Pad the string
    for (( i=0; i<padding; i++ )); do
      padded_str="$padded_str$pad_char"
    done
    
    echo "$padded_str"
  fi
}

function success() {
    local check="✔"
    green $check
    # white space
    echo -e "\012"
}

function error() {
    local x="✘"
    red $x
    # white space
    echo -e "\012"
}

function config_exists() {
    [ -f "$DIR/absence.json" ]
}

function get_config_id() {
    jq -r .id "$DIR/absence.json"
}

function get_config_key() {
    jq -r .key "$DIR/absence.json"
}

function get_config_start_from() {
    jq -r .start_from "$DIR/absence.json"
}

function get_config_schedule() {
    jq -r .schedule "$DIR/absence.json"
}

function create_config() {
    echo '{
    "id": "fill",
    "key": "fill",
    "schedule": [
        {
            "start": "08:00",
            "end": "14:00",
            "type": "work"
        },
        {
            "start": "14:00",
            "end": "15:00",
            "type": "break"
        },
        {
            "start": "15:00",
            "end": "17:00",
            "type": "work"
        }
    ]
}
' > "$DIR/absence.json"
}

function request() {
    # store the response with together with the status code at the and of the content on error
    http_response=$(curl --max-time 3 --silent --show-error --write-out "#HTTPSTATUS#:%{http_code}" "$@" 2>&1)
    curl_status=$?


    local http_body=$(echo $http_response | sed -E 's/#HTTPSTATUS#\:[0-9]{3}$//')
    local http_status=$(echo $http_response | tr -d '\n' | sed -E 's/.*#HTTPSTATUS#:([0-9]{3})$/\1/')
    
    # first number of http status code 400 -> 4
    # bash's maximum status code is 255, so it doesn't make sense to return actual codes
    local short_http_status=${http_status:0:1}

    if [[ $curl_status -ne 0 ]]; then
        jq="$(jq -njc --arg status "$curl_status" \
            --arg body "$http_body" '{status: ($status | tonumber), body: $body}')"
        printf "$jq"
        return $curl_status
    fi

    # 200,201,2xx are converted to bash's success code: 0
    if [ $short_http_status -eq 2 ]; then
        short_http_status=0
    else
        jq="$(jq -njc --arg status "$http_status" \
            --arg body "$http_body" '{status: ($status | tonumber), body: $body}')"
        printf "$jq"
        return $short_http_status
    fi

    printf "$http_body"
    return $short_http_status
}

# request ifconfig.me
# exit 1

function generate_nonce() {
    openssl rand -hex 16
}

function generate_hawk_header() {
    # auth
    local id=$(get_config_id)
    local key=$(get_config_key)

    # hawk details
    local timestamp=$(date +%s)
    local nonce=$(generate_nonce)
    
    local method="$1"
    local resource="$2"
    local uri="/api/v2/$resource"
    local host="app.absence.io"
    local port="443"


    # new lines are critical
    local normalized_mac="hawk.1.header
$timestamp
$nonce
$method
$uri
$host
$port


"

    if echo | openssl dgst -sha256 -hmac "test" >/dev/null 2>&1; then
        # Linux
        mac=$(echo -n "$normalized_mac" | openssl dgst -sha256 -hmac "$key" -binary | base64)
    else
        # macOS
        mac=$(echo -n "$normalized_mac" | openssl dgst -sha256 -mac HMAC -macopt key:"$key" -binary | base64)
    fi
    
    printf "Hawk id=\"$id\", ts=\"$timestamp\", nonce=\"$nonce\", mac=\"$mac\""
}

function api() {
    local method="$1"
    declare -a methods=("GET" "POST" "PUT" "PATCH" "DELETE")
    local imploded_methods=$(IFS=","; echo "${methods[*]}")

    local resource="$2"
    local payload="$3"
    local url="https://app.absence.io/api/v2/$resource"

    if [[ ! "${methods[@]}" =~ "${method}" ]]; then
        echo $(error; red 'HTTP method must be one of: '$imploded_methods'')
        return 1
    fi

    if [[ -z $resource ]]; then
        echo $(error; red 'The resource is required.')
        return 1
    fi

    local hawk_header="$(generate_hawk_header "$method" "$resource")"
    
    local headers=(-H "Content-Type: application/json" -H "Authorization: $hawk_header")  
    [[ -n $payload ]] && local data=(-d "$payload")  

    request -X "$method" "${headers[@]}" "${data[@]}" "$url"
}

function get_remote_user() {
    local id=$(get_config_id)

    api "GET" "users/$id"
}

function show_greetings() {
    response="$(get_remote_user)"
    status=$?

    if [ $status -ne 0 ]; then
        http_status="$(echo -n "$response" | jq -r '.status')"
        http_body="$(echo -n "$response" | jq -r '.body')"

        if [[ $http_status -eq 401 ]]; then
            echo $(error; red "Unauthorized (401) error: Please check your credentials")
            echo "$http_body" | jq
            return 4
        else
            echo $(error; red "$http_status error: Don't know how to handle it") 
            echo "Response: $response"
            return 5
        fi
    fi

    name=$(printf "$(echo "$response" | jq -r '.name')")

    echo $(bold_green "Hi $name! 👋😊")
}

function get_date_monday() {
    date_to_check="$1"

    if date --version >/dev/null 2>&1; then
        # GNU date (Linux)
        day_of_week=$(date -d "$date_to_check" +%u)
    else
        # BSD date (macOS)
        day_of_week=$(date -j -f "%Y-%m-%d" "$date_to_check" +%u)
    fi

    # Calculate the number of days to subtract to reach the previous Monday
    days_to_subtract=$((day_of_week - 1))

    if date --version >/dev/null 2>&1; then
        # GNU date (Linux)
        monday_date=$(date -d "$date_to_check -$days_to_subtract days" +%Y-%m-%d)
    else
        # BSD date (macOS)
        monday_date=$(date -j -v-"$days_to_subtract"d -f "%Y-%m-%d" "$date_to_check" "+%Y-%m-%d")
    fi

    printf "$monday_date"
}

function is_valid_date() {
    local input="$1"

    if [[ -z "$input" ]]; then
        return 1
    fi

    if date --version >/dev/null 2>&1; then
        # GNU date (Linux)
        date -d "$input" "+%Y-%m-%d" &>/dev/null
    else
        # BSD date (macOS)
        date -j -f "%Y-%m-%d" "$input" "+%Y-%m-%d" &>/dev/null
    fi
}

function date_is_workable() {
    local start_date="$1"
    
    if date --version >/dev/null 2>&1; then
        # GNU date (Linux)
        day_of_week=$(date -d "$start_date" +%u)
    else
        # BSD date (macOS)
        day_of_week=$(date -j -f "%Y-%m-%d" "$start_date" +%u)
    fi
    
    # Check if it's Saturday (6) or Sunday (7)
    if [[ "$day_of_week" -eq 6 ]] || [[ "$day_of_week" -eq 7 ]]; then
        return 1
    fi
}

function create_remote_time_entries() {
    local start_date=${1}
    local end_date=${2}
    local type=${3:-work}
    declare -a types=("work" "break")

    if ! is_valid_date "$start_date" || ! is_valid_date "$end_date"; then
        echo $(error; red 'Start Date and End Date are required')
        return 1
    fi

    if [[ "$start_date" > "$end_date" ]]; then
        echo $(error; red 'Start Date cannot be greater than End Date')
        return 1
    fi

    if [[ ! "${types[@]}" =~ "${type}" ]]; then
        echo $(error; red 'Possible work types are: work, break')
        return 1
    fi

    local json_schedule="$(get_config_schedule)"

    if [[ $(echo "$json_schedule" | jq -r '. | length') -eq 0 ]]; then
        echo $(error; red 'Schedules list cannot be empty')
        return 1
    fi

    local userId=$(get_config_id)

    echo "Date range: $start_date to $end_date"
    echo ""

    current_date="$start_date"

    while [[ "$current_date" < "$end_date" ]] || [[ "$current_date" == "$end_date" ]]; do
        echo "Date: $current_date"

        echo "$json_schedule" | jq -c '.[]' | while read -r entry; do
            start=$(echo "$entry" | jq -r '.start')
            end=$(echo "$entry" | jq -r '.end')
            type=$(echo "$entry" | jq -r '.type')

            local start_datetime="${current_date}T${start}:00.000Z"
            local end_datetime="${current_date}T${end}:00.000Z"
            
            local json_payload=$(jq -n --arg userId "$userId" --arg start "$start_datetime" \
                --arg end "$end_datetime" --arg type "$type" \
                '{
                    userId: $userId,
                    start: $start,
                    end: $end,
                    type: $type,
                    source: { sourceType: "browser", sourceId: "manual" }
                }')

            echo -n "╰➤ $(str_pad "Creating $type entry from $start to $end" 41) "

            response=$(api "POST" "timespans/create" "$json_payload")
            code=$?

            if [ $code -ne 0 ]; then
                http_status="$(echo -n "$response" | jq -r '.status')"
                http_body="$(echo -n "$response" | jq -r '.body')"

                if [[ $http_status -eq 422 ]]; then
                    echo $(red "┈➤ Validation error (422). The response:")
                    echo "$http_body" | jq
                elif [[ $http_status -eq 412 ]]; then
                    echo $(red "┈➤ Precondition Failed (412) error: $http_body") 
                else
                    echo $(red "┈➤ $http_status error: Don't know how to handle it") 
                    echo "Response: $response"
                fi
            else
                echo $(success)
            fi
        done

        current_date=$(add_days "$current_date" 1)
        echo ""
    done
}

function today() {
    date '+%Y-%m-%d'
}

function add_days() {
    local input_date="$1"
    local days="$2"

    if date --version >/dev/null 2>&1; then
        # GNU date (Linux)
        date -I -d "$input_date +$days days"
    else
        # BSD date (macOS)
        date -j -v+"$days"d -f "%Y-%m-%d" "$input_date" "+%Y-%m-%d"
    fi
}

function check_dependencies() {
    declare -a deps=("jq" "curl" "openssl" "base64" "date")
    
    declare -a missing=()

    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing=("${missing[@]}" "$dep")
        fi
    done

    if [[ ${#missing[@]} -ne 0 ]]; then
        local imploded_methods=$(IFS=","; echo "${missing[*]}")

        echo $(error; red "Dependencies missing: $imploded_methods")

        return 1
    fi
}

function run() {
    check_dependencies
    if [[ $? -ne 0 ]]; then
        return $?
    fi

    if ! config_exists; then
        create_config

        echo "A config file was not found so one was created (absence.json), please fill in your values."
        echo "Go to Absence -> Profile -> Integrations -> API Key (ID/Key)"
        
        return 1
    fi

    # help
    help="$1"
    if [[ "$help" == "help" ]]; then
        echo "Available options:"
        echo ""
        echo "$ absence.sh: Register a time entry for today."
        echo "$ absence.sh week: Registers time entries for the week."
        echo "$ absence.sh 2025-03-25 2025-03-28: Register time entries for a specific range."
        echo "$ absence.sh help: Shows this help."
        echo ""
        echo "Please note all options are restricted to future dates by Absence."
        echo ""
        return 0
    fi

    show_greetings
    if [[ $? -ne 0 ]]; then
        return $?
    fi
    echo ""

    today="$(today)"

    # weekly submit, preferably to run on Friday
    week="$1"
    if [[ "$week" == "week" ]]; then
        monday_of_the_week="$(get_date_monday "$today")"
        end_date=$(add_days "$monday_of_the_week" 4)

        if [[ $end_date > $today ]]; then
            end_date="$today"
        fi
        
        create_remote_time_entries "$monday_of_the_week" "$end_date"

        return 1
    fi

    # manual day start and end ranges
    start_date="$1"
    end_date="$2"
    if is_valid_date "$start_date"; then
        if ! is_valid_date "$end_date"; then
            echo "$(error; red 'End Date is required')"
            return 1
        fi

        create_remote_time_entries "$start_date" "$end_date"
        return $?
    fi

    # today, one working day
    if ! date_is_workable "$today"; then
        echo $(error; red "Today should be a working day, try using the week or dates range options.")
        echo "$ absence.sh week"
        echo "$ absence.sh 2025-03-04 2024-03-06"
        return 1
    fi

    create_remote_time_entries $today $today
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo $(bold "📅 Absence.IO hours reporting tool v1.0.0") 
    echo ""

    run $@
fi
