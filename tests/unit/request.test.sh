#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "$DIR/../../src/absence.sh"

function test_http_response_error() {    
    mock curl 'echo "content#HTTPSTATUS#:404"; return 0'

    result=$(request http://localhost)
    status=$?

    assert_equals 4 "$status"
    assert_equals 404 $(echo "$result" | jq -r .status)
    assert_equals "content" $(echo "$result" | jq -rc .body)
}

function test_curl_internal_error() {
    mock curl 'echo "curl: (28) Resolving timed out after 3001 milliseconds " >&2; \
            echo "#HTTPSTATUS#:000"; \
            return 28'

    result="$(request "http://slow-host")"
    status=$?

    assert_equals 28 "$status"
    assert_equals 28 $(echo "$result" | jq -r .status)
    assert_equals "curl: (28) Resolving timed out after 3001 milliseconds " "$(echo "$result" | jq -rj .body)"
}

function test_json_is_not_returned_on_success_only_the_content_and_200_are_translated_to_0_status() {
    mock curl 'echo "content#HTTPSTATUS#:200"'

    result="$(request "http://valid-host")"
    status=$?

    assert_equals 0 "$status"
    assert_equals "content" "$result"
}
