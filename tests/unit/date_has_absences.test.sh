#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "$DIR/../../src/absence.sh"

function test_when_start_date_and_end_date_are_incorrect() { 
    result="$(date_has_absences)"
    assert_contains "The start date must be valid" "$result"

    result="$(date_has_absences "invalid date")"
    assert_contains "The start date must be valid" "$result"
}

function test_when_date_is_in() {
    mock get_config_id 'echo "123456"'

    ABSENCES_CACHE='[{"_id":"67e5759ca495742d3e841dbc","days":[{"date":"2025-03-27T00:00:00.000Z"}]},{"_id":"67c6d21603467b7dffc01485","days":[{"date":"2025-03-10T00:00:00.000Z"},{"date":"2025-04-01T00:00:00.000Z"}]}]'

    result="$(date_has_absences "2025-04-01")"
    status=$?

    assert_contains 0 "$status"
}

function test_when_date_is_not_there() {
    mock get_config_id 'echo "123456"'

    ABSENCES_CACHE='[{"_id":"67e5759ca495742d3e841dbc","days":[{"date":"2025-03-27T00:00:00.000Z"}]},{"_id":"67c6d21603467b7dffc01485","days":[{"date":"2025-03-10T00:00:00.000Z"}]}]'

    result="$(date_has_absences "2025-04-01")"
    status=$?

    assert_contains 1 "$status"

}

function test_when_empty() {
    mock get_config_id 'echo "123456"'

    ABSENCES_CACHE='[]'

    result="$(date_has_absences "2025-04-01")"
    status=$?

    assert_contains 1 "$status"

}
