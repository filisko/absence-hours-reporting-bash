#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "$DIR/../../src/absence.sh"

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
    
    result="$(create_remote_time_entries "2025-03-01" "2025-03-01")"

    assert_contains "Schedules list cannot be empty" "$result"
}

function test_schedule_entries_are_created() {
    mock get_config_schedule "echo '[{\"start\": \"09:00\", \"end\": \"12:00\", \"type\": \"work\"}, {\"start\": \"12:00\", \"end\": \"13:00\", \"type\": \"break\"}]'"
    mock get_config_id 'echo "123456"'
    mock get_config_timezone 'printf "+0100"'
    mock get_config_timezone_name 'printf "Central European Standar Time"'
    mock date_has_absences 'return 1'

    mock api "echo '{\"startInTimezone\":\"2025-03-03T10:00:00+01:00\",\"endInTimezone\":\"2025-03-03T12:00:00+01:00\"}'"

    result="$(create_remote_time_entries "2025-03-03" "2025-03-04")"

    assert_contains "Date: 2025-03-03" "$result"
    assert_contains "Creating work entry from 09:00 to 12:00" "$result"
    assert_contains "Creating break entry from 12:00 to 13:00" "$result"

    assert_contains "Date: 2025-03-04" "$result"
}

function test_valid_json_payload_is_sent() {
    mock get_config_schedule "echo '[{\"start\": \"09:00\", \"end\": \"12:00\", \"type\": \"work\"}, {\"start\": \"12:00\", \"end\": \"13:00\", \"type\": \"break\"}]'"
    mock get_config_id 'echo "123456"'
    mock get_config_timezone 'printf "+0100"'
    mock get_config_timezone_name 'printf "Central European Standar Time"'
    mock load_absences_into_cache 'return 0'
    mock date_has_absences 'return 1'

    mock api 'echo "input params $@"; return 5'

    result="$(create_remote_time_entries "2025-03-03" "2025-03-04")"

    assert_contains "POST timespans/create" "$result"

    assert_contains "Creating work entry from 09:00 to 12:00" "$result"
    assert_contains 'POST timespans/create {
  "userId": "123456",
  "start": "2025-03-03T09:00:00.000Z",
  "end": "2025-03-03T12:00:00.000Z",
  "type": "work",
  "source": {
    "sourceType": "browser",
    "sourceId": "manual"
  },
  "timezone": "+0100",
  "timezoneName": "Central European Standar Time"
}' "$result"
    assert_contains 'POST timespans/create {
  "userId": "123456",
  "start": "2025-03-04T09:00:00.000Z",
  "end": "2025-03-04T12:00:00.000Z",
  "type": "work",
  "source": {
    "sourceType": "browser",
    "sourceId": "manual"
  },
  "timezone": "+0100",
  "timezoneName": "Central European Standar Time"
}' "$result"

    assert_contains "Creating break entry from 12:00 to 13:00" "$result"
    assert_contains 'POST timespans/create {
  "userId": "123456",
  "start": "2025-03-03T12:00:00.000Z",
  "end": "2025-03-03T13:00:00.000Z",
  "type": "break",
  "source": {
    "sourceType": "browser",
    "sourceId": "manual"
  },
  "timezone": "+0100",
  "timezoneName": "Central European Standar Time"
}' "$result"
    assert_contains 'POST timespans/create {
  "userId": "123456",
  "start": "2025-03-04T12:00:00.000Z",
  "end": "2025-03-04T13:00:00.000Z",
  "type": "break",
  "source": {
    "sourceType": "browser",
    "sourceId": "manual"
  },
  "timezone": "+0100",
  "timezoneName": "Central European Standar Time"
}' "$result"
}

function test_when_current_day_is_a_weekend_it_is_skipped() {
    mock get_config_schedule "echo '[{\"start\": \"09:00\", \"end\": \"17:00\", \"type\": \"work\"}]'"
    mock get_config_id 'echo "123456"'
    mock get_config_timezone 'printf "+0100"'
    mock get_config_timezone_name 'printf "Central European Standar Time"'
    mock load_absences_into_cache 'return 0'

    mock api "echo '{\"status\": 422, \"body\": null}'; return 4"

    result="$(create_remote_time_entries "2025-03-01" "2025-03-01")"

    assert_contains "Date: 2025-03-01" "$result"
    assert_contains "It is not a working day (weekend)." "$result"
}

function test_when_current_day_has_absences_it_is_skipped() {
    mock get_config_schedule "echo '[{\"start\": \"09:00\", \"end\": \"17:00\", \"type\": \"work\"}]'"
    mock get_config_id 'echo "123456"'
    mock get_config_timezone 'printf "+0100"'
    mock get_config_timezone_name 'printf "Central European Standar Time"'
    mock load_absences_into_cache 'return 0'
    mock date_has_absences 'return 0'

    result="$(create_remote_time_entries "2025-03-04" "2025-03-04")"

    assert_contains "There were absences found." "$result"
}

function test_when_loading_absences_into_cache_fails() {
    mock get_config_schedule "echo '[{\"start\": \"09:00\", \"end\": \"17:00\", \"type\": \"work\"}]'"
    mock get_config_id 'echo "123456"'
    mock get_config_timezone 'printf "+0100"'
    mock get_config_timezone_name 'printf "Central European Standar Time"'
    mock load_absences_into_cache 'echo "Internal error is echoed"; return 5'

    result="$(create_remote_time_entries "2025-03-04" "2025-03-04")"

    assert_contains "Failed to load absences into cache" "$result"
    assert_contains "Internal error is echoed" "$result"
}

function test_when_current_day_has_holidays_it_is_skipped() {
    mock get_config_schedule "echo '[{\"start\": \"09:00\", \"end\": \"17:00\", \"type\": \"work\"}]'"
    mock get_config_id 'echo "123456"'
    mock get_config_timezone 'printf "+0100"'
    mock get_config_timezone_name 'printf "Central European Standar Time"'
    mock load_absences_into_cache 'return 0'
    mock date_has_absences 'return 1'
    mock get_holiday 'printf "epiphany"'

    result="$(create_remote_time_entries "2025-01-06" "2025-01-06")"

    assert_contains "It is not a working day. Found holidays: epiphany" "$result"
}

function test_when_there_is_an_api_422_error() {
    mock get_config_schedule "echo '[{\"start\": \"09:00\", \"end\": \"17:00\", \"type\": \"work\"}]'"
    mock get_config_id 'echo "123456"'
    mock get_config_timezone 'printf "+0100"'
    mock get_config_timezone_name 'printf "Central European Standar Time"'
    mock load_absences_into_cache 'return 0'
    mock date_has_absences 'return 1'

    mock api "echo '{\"status\": 422, \"body\": null}'; return 4"

    result="$(create_remote_time_entries "2025-03-03" "2025-03-03")"

    assert_contains "Date: 2025-03-03" "$result"
    assert_contains "Validation error (422)" "$result"
}

function test_when_there_is_an_api_412_error() {
    mock get_config_schedule "echo '[{\"start\": \"09:00\", \"end\": \"17:00\", \"type\": \"work\"}]'"
    mock get_config_id 'echo "123456"'
    mock get_config_timezone 'printf "+0100"'
    mock get_config_timezone_name 'printf "Central European Standar Time"'
    mock load_absences_into_cache 'return 0'
    mock date_has_absences 'return 1'
    
    mock api "echo '{\"status\": 412, \"body\": \"Entries cannot overlap\"}'; return 4"


    result="$(create_remote_time_entries "2025-03-03" "2025-03-03")"

    assert_contains "Date: 2025-03-03" "$result"
    assert_contains "Precondition Failed (412) error: Entries cannot overlap" "$result"
}

function test_when_there_is_an_api_500_error() {
    mock get_config_schedule "echo '[{\"start\": \"09:00\", \"end\": \"17:00\", \"type\": \"work\"}]'"
    mock get_config_id 'echo "123456"'
    mock get_config_timezone 'printf "+0100"'
    mock get_config_timezone_name 'printf "Central European Standar Time"'

    mock load_absences_into_cache 'return 0'
    mock date_has_absences 'return 1'

    mock api "echo '{\"status\": 500, \"body\": \"Internal error\"}'; return 5"

    result="$(create_remote_time_entries "2025-03-03" "2025-03-04")"

    assert_contains "500 error: Don't know how to handle it" "$result"
}
