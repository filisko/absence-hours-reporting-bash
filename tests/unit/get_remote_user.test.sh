#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "$DIR/../../src/absence.sh"

# avoids "lib/bashunit: line 1053: printf: 1.54: invalid number" error
export LC_NUMERIC="en_US.UTF-8"

function test_when_request_fails_result_gets_echoed() {
    mock get_config_id 'echo "123456"'

    mock api "echo 'some really really bad error because its not even JSON'; return 5"

    result="$(get_remote_user)"

    assert_contains "some really really bad error" "$result"
}

function test_valid_json_payload_is_sent() {
    mock get_config_id 'echo "123456"'

    mock api 'echo "input params $@"; return 5'

    result="$(get_remote_user)"

    assert_contains 'input params POST users {
  "skip": 0,
  "limit": 1000,
  "filter": {
    "_id": "123456"
  },
  "relations": [
    "holidayIds"
  ]
}' "$result"
}

function test_data_is_read() {
    mock get_config_id 'echo "123456"'

    mock api "echo '{\"count\": 1, \"data\": [{\"name\": \"test\"}]}'"

    result="$(get_remote_user)"

    assert_contains '{"name":"test"}' "$result"
}
