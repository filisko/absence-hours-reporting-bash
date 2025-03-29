#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "$DIR/../../src/absence.sh"

# avoids "lib/bashunit: line 1053: printf: 1.54: invalid number" error
export LC_NUMERIC="en_US.UTF-8"

function test_when_start_date_and_end_date_are_incorrect() { 
    result="$(create_remote_time_entries)"
    assert_contains "Start Date and End Date are require" "$result"

    result="$(create_remote_time_entries "2023-10-01")"
    assert_contains "Start Date and End Date are require" "$result"

    result="$(create_remote_time_entries "invalid date")"
    assert_contains "Start Date and End Date are require" "$result"

    result="$(create_remote_time_entries "2023-10-01" "invalid date")"
    assert_contains "Start Date and End Date are require" "$result"
}

function test_when_start_date_is_greater_than_end_date() {
    result="$(create_remote_time_entries "2023-10-05" "2023-10-01")"

    assert_contains "Start Date cannot be greater than End Date" "$result"
}


function test_when_type_is_in_invalid_returns_an_error() {
    
    result="$(create_remote_time_entries "2023-10-01" "2023-10-01" "invalid")"

    assert_contains "Possible work types are: work, break" "$result"
}

function test_when_schedules_is_empty_returns_an_error() {
    mock get_config_schedule "echo '[]'"
    
    result="$(create_remote_time_entries "2023-10-01" "2023-10-01")"

    assert_contains "Schedules list cannot be empty" "$result"
}

function test_schedule_entries_are_created() {
    mock get_config_schedule "echo '[{\"start\": \"09:00\", \"end\": \"12:00\", \"type\": \"work\"}, {\"start\": \"12:00\", \"end\": \"13:00\", \"type\": \"break\"}]'"

    mock get_config_id 'echo "12345"'

    mock api "echo '{\"status\": 200, \"body\": null}'"

    result="$(create_remote_time_entries "2023-10-01" "2023-10-02")"

    assert_contains "Date range: 2023-10-01 to 2023-10-02" "$result"

    assert_contains "Date: 2023-10-01" "$result"
    assert_contains "Creating work entry from 09:00 to 12:00" "$result"
    assert_contains "Creating break entry from 12:00 to 13:00" "$result"

    assert_contains "Date: 2023-10-02" "$result"
}

function test_when_there_is_an_api_422_error() {
    mock get_config_schedule "echo '[{\"start\": \"09:00\", \"end\": \"17:00\", \"type\": \"work\"}]'"
    
    mock api "echo '{\"status\": 422, \"body\": null}'; return 4"

    result="$(create_remote_time_entries "2023-10-01" "2023-10-01")"

    assert_contains "Date range: 2023-10-01 to 2023-10-01" "$result"
    assert_contains "Date: 2023-10-01" "$result"
    assert_contains "Validation error (422)" "$result"
}

function test_when_there_is_an_api_412_error() {
    mock get_config_schedule "echo '[{\"start\": \"09:00\", \"end\": \"17:00\", \"type\": \"work\"}]'"
    
    mock api "echo '{\"status\": 412, \"body\": \"Entries cannot overlap\"}'; return 4"

    result="$(create_remote_time_entries "2023-10-01" "2023-10-01")"

    assert_contains "Precondition Failed (412) error: Entries cannot overlap" "$result"
}

function test_when_there_is_an_api_500_error() {
    mock get_config_schedule "echo '[{\"start\": \"09:00\", \"end\": \"17:00\", \"type\": \"work\"}]'"
    
    mock api "echo '{\"status\": 500, \"body\": \"Internal error\"}'; return 5"

    result="$(create_remote_time_entries "2023-10-01" "2023-10-01")"

    assert_contains "500 error: Don't know how to handle it" "$result"
}

