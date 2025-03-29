#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "$DIR/../../src/absence.sh"

# avoids "lib/bashunit: line 1053: printf: 1.54: invalid number" error
export LC_NUMERIC="en_US.UTF-8"

function test_when_invalid_method_is_provided() {
    result="$(api NOPE /users)"

    assert_contains "HTTP method must be one of: GET,POST,PUT,PATCH,DELETE" "$result"
}

function test_resource_is_required() {
    result="$(api GET)"

    assert_contains "The resource is required." "$result"
}

# function test_asd() {
#     result="$(api GET /users)"

#     function request() {
#         echo "input params: $@"
#     }

#     mock request -X  'echo "asdasd"'

#     assert_contains "test" "$result"
# }
