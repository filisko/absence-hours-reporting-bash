#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "$DIR/../../src/absence.sh"

function test_it_shows_the_name() {
    mock get_remote_user "echo '{\"name\": \"Filis Futsarov\"}'; return 0"
    
    result="$(show_greetings)"

    assert_contains "Hi Filis Futsarov! 👋😊" "$result"
}

function test_it_stores_holidays_in_cache() {
    mock get_remote_user "echo '{\"name\": \"Filis Futsarov\", \"holidays\": [{\"name\": \"diada_de_catalunya\", \"dates\": [\"2025-09-11T00:00:00.000Z\"]}, {\"name\": \"es_whit_monday\", \"dates\": [\"2025-06-09T00:00:00.000Z\"]}]}'; return 0"
    
    HOLIDAYS_CACHE=""
    
    show_greetings

    assert_contains '{"name":"diada_de_catalunya","dates":["2025-09-11T00:00:00.000Z"]}
{"name":"es_whit_monday","dates":["2025-06-09T00:00:00.000Z"]}' $HOLIDAYS_CACHE
}

function test_401_error() {
    mock get_remote_user "echo '{\"status\": 401, \"body\": \"Unauthorized error\"}'; return 4"
    
    result="$(show_greetings)"

    assert_contains "Unauthorized (401) error: Please check your credentials" "$result"
}

function test_500_error() {
    mock get_remote_user "echo '{\"status\": 500, \"body\": \"Internal error\"}'; return 4"
    
    result="$(show_greetings)"

    assert_contains "500 error: Don't know how to handle it" "$result"
    assert_contains "Response: {\"status\": 500, \"body\": \"Internal error\"}" "$result"
}
