#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "$DIR/../../src/absence.sh"

# avoids "lib/bashunit: line 1053: printf: 1.54: invalid number" error
export LC_NUMERIC="en_US.UTF-8"

function test_when_request_fails_result_gets_echoed() {
    mock get_config_id 'echo "123456"'

    mock api "echo 'some really really bad error because its not even JSON'; return 5"

    result="$(show_last_timespan_entry)"

    assert_contains "Don't know how to handle it" "$result"
    assert_contains "Response: some really really bad error" "$result"
}

function test_valid_json_payload_is_sent() {
    mock get_config_id 'echo "123456"'

    mock api 'echo "input params $@"; return 5'

    result="$(show_last_timespan_entry)"

    assert_contains 'POST timespans {"limit":1,"sortBy":{"start":-1}}' "$result"
}

function test_data_is_read() {
    mock get_config_id 'echo "123456"'

    mock api "echo '{\"data\": [{
  \"timezone\": \"+0200\",
  \"timezoneName\": \"Central European Summer Time\",
  \"type\": \"work\",
  \"start\": \"2025-04-02T13:00:00.000Z\",
  \"end\": \"2025-04-02T15:00:00.000Z\",
  \"startInTimezone\": \"2025-04-02T15:00:00.000+02:00\",
  \"endInTimezone\": \"2025-04-02T17:00:00.000+02:00\",
  \"source\": {
    \"sourceType\": \"browser\",
    \"sourceId\": \"manual\"
  },
  \"otheFields\": \"are ignored\"
}]}'"


    result="$(show_last_timespan_entry)"

    assert_contains '{
  "timezone": "+0200",
  "timezoneName": "Central European Summer Time",
  "type": "work",
  "start": "2025-04-02T13:00:00.000Z",
  "end": "2025-04-02T15:00:00.000Z",
  "startInTimezone": "2025-04-02T15:00:00.000+02:00",
  "endInTimezone": "2025-04-02T17:00:00.000+02:00",
  "source": {
    "sourceType": "browser",
    "sourceId": "manual"
  }
}' "$result"
}
