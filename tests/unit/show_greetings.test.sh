#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "$DIR/../../src/absence.sh"

function test_it_shows_the_name() {
    mock get_remote_user "echo '{\"name\": \"Filis Futsarov\"}'; return 0"
    
    result="$(show_greetings)"

    assert_contains "Hi Filis Futsarov! 👋😊" "$result"
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
}
