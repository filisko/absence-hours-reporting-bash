#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "$DIR/../../src/absence.sh"

# avoids "lib/bashunit: line 1053: printf: 1.54: invalid number" error
export LC_NUMERIC="en_US.UTF-8"

function test_when_invalid_method_is_provided() {
    result="$(api NOPE users)"
    status=$?

    assert_equals 1 "$status"
    assert_contains "HTTP method must be one of: GET,POST,PUT,PATCH,DELETE" "$result"
}

function test_resource_is_required() {
    result="$(api GET)"
    status=$?

    assert_equals 1 "$status"
    assert_contains "The resource is required." "$result"
}

function test_hawk_header_is_passed_to_curl() {
    # generate_hawk_header mocks
    mock date 'echo "123456"'
    mock generate_nonce 'echo "xxxxxxxx"'
    
    mock request 'echo "input params: $@"'

    result=$(api GET users)

    assert_contains '-X GET -H Content-Type: application/json -H Authorization: Hawk id="616943a72c4d8027af9b7a3e", ts="123456", nonce="xxxxxxxx", mac="YejPmNdFSqziOHF+rzBmHrvTEGIl42mm41iJAk39lTQ=' "$result"

    assert_contains "https://app.absence.io/api/v2/users" "$result"
}
