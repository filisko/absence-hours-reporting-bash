#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "$DIR/../../src/absence.sh"

function test_when_date_is_incorrect() {

    result="$(get_holiday "invalid date")"

    assert_contains "A valid date is required" "$result"
}

function test_it_reads_from_cache() {
    HOLIDAYS_CACHE='{"name":"diada_de_catalunya","dates":["2025-09-11T00:00:00.000Z"]}'
    
    read result < <(get_holiday 2025-09-11)

    assert_equals "diada_de_catalunya" "$result"
}
