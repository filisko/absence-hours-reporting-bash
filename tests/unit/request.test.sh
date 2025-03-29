#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "$DIR/../../src/absence.sh"

# avoids "lib/bashunit: line 1053: printf: 1.54: invalid number" error
export LC_NUMERIC="en_US.UTF-8"

function test_http_error() {    
    mock curl 'echo "content#HTTPSTATUS#:404"; return 0'

    result=$(request http://localhost)
    status=$?

    assert_equals 4 "$status"
    assert_equals 404 $(echo "$result" | jq -r .status)
    assert_equals "content" $(echo "$result" | jq -rc .body)
}

function test_only_curl_error() {
    result="$(request "http://invalid-host")"
    status=$?

    assert_equals 6 "$status"
    assert_equals 6 $(echo "$result" | jq -r .status)
    assert_equals "curl: (6) Could not resolve host: invalid-host " "$(echo "$result" | jq -rj .body)"
}

function test_json_is_not_returned_on_success_only_the_content_and_200_are_translated_to_0_status() {
    mock curl 'echo "content#HTTPSTATUS#:200"'

    result="$(request "http://invalid-host")"
    status=$?

    assert_equals 0 "$status"
    assert_equals "content" "$result"
}
