#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "$DIR/../../src/absence.sh"

# avoids "lib/bashunit: line 1053: printf: 1.54: invalid number" error
export LC_NUMERIC="en_US.UTF-8"

function test_when_start_date_and_end_date_are_incorrect() { 
    result="$(get_absences_count)"
    assert_contains "Start Date and End Date are require" "$result"

    result="$(get_absences_count "2023-10-01")"
    assert_contains "Start Date and End Date are require" "$result"

    result="$(get_absences_count "invalid date")"
    assert_contains "Start Date and End Date are require" "$result"

    result="$(get_absences_count "2023-10-01" "invalid date")"
    assert_contains "Start Date and End Date are require" "$result"
}

function test_when_request_fails_result_gets_echoed() {
    mock get_config_id 'echo "123456"'

    mock api "echo 'some really really bad error because its not even JSON'; return 5"

    result="$(get_absences_count "2025-04-01" "2025-04-02")"

    assert_contains "API error: Don't know how to handle it" "$result"
    assert_contains "some really really bad error" "$result"
}

function test_valid_json_payload_is_sent() {
    mock get_config_id 'echo "123456"'

    mock api 'echo "input params $@"; return 5'

    result="$(get_absences_count "2025-04-01" "2025-04-02")"

    assert_contains "POST absences" "$result"
    assert_contains 'input params POST absences {
  "skip": 0,
  "limit": 100,
  "filter": {
    "assignedToId": "123456",
    "start": {
      "$gte": "2025-04-01T00:00:00.000Z"
    },
    "end": {
      "$lte": "2025-04-02T00:00:00.000Z"
    }
  },
  "relations": [
    "asssignedToId"
  ]
}' "$result"
}

function test_count_is_read() {
    mock get_config_id 'echo "123456"'

    mock api "echo '{\"status\": 200, \"body\": {\"count\": 5}}'; return 5"

    result="$(get_absences_count "2025-04-01" "2025-04-02")"

    assert_contains 5 "$result"
}

