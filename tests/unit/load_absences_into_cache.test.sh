#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "$DIR/../../src/absence.sh"

# avoids "lib/bashunit: line 1053: printf: 1.54: invalid number" error
export LC_NUMERIC="en_US.UTF-8"

function test_it_stores_absences_in_cache() {
    mock get_config_id 'echo "123456"'

    mock api "echo '{
  \"data\": [
      {
          \"_id\": \"67e5759ca495742d3e841dbc\",
          \"days\": [
              {
                  \"date\": \"2025-03-27T00:00:00.000Z\"
              }
          ]
      },
      {
          \"_id\": \"67c6d21603467b7dffc01485\",
          \"days\": [
              {
                  \"date\": \"2025-03-10T00:00:00.000Z\"
              },
              {
                  \"date\": \"2025-04-01T00:00:00.000Z\"
              }
          ]
      }
  ]
}'"

    ABSENCES_CACHE=""
    
    load_absences_into_cache

    assert_contains '[{"_id":"67e5759ca495742d3e841dbc","days":[{"date":"2025-03-27T00:00:00.000Z"}]},{"_id":"67c6d21603467b7dffc01485","days":[{"date":"2025-03-10T00:00:00.000Z"},{"date":"2025-04-01T00:00:00.000Z"}]}]' $ABSENCES_CACHE
}


function test_when_request_fails_result_gets_echoed() {
    mock get_config_id 'echo "123456"'

    mock api "echo 'some really really bad error because its not even JSON'; return 5"

    result="$(load_absences_into_cache)"

    assert_contains "API error: Don't know how to handle it" "$result"
    assert_contains "some really really bad error" "$result"
}

function test_valid_json_payload_is_sent() {
    mock get_config_id 'echo "123456"'

    mock api 'echo "input params $@"; return 5'

    result="$(load_absences_into_cache "2025-04-01")"

    assert_contains 'input params POST absences {
  "skip": 0,
  "limit": 100,
  "filter": {
    "assignedToId": "123456"
  }
}' "$result"
}


