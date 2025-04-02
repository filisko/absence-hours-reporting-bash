#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "$DIR/../src/absence.sh"

# avoids "lib/bashunit: line 1053: printf: 1.54: invalid number" error
export LC_NUMERIC="en_US.UTF-8"

function ok() {
    return 0
}

function fail() {
    return 1
}

function test_when_there_isnt_a_config_file_its_created() {
    mock config_exists fail
    mock create_config ok

    result="$(run)"

    assert_contains "A config file was not found so one was created (absence.json)" "$result"
}

function test_when_greetings_fail_it_exits() {
    mock config_exists ok

    function show_greetings() {
        echo "Error from greetings"
        return 1
    }

    result="$(run)"

    assert_equals "Error from greetings" "$result"
}

function test_daily_entry_creation() {
    mock config_exists ok
    mock show_greetings "echo 'Hi! 👋😊'"

    mock create_remote_time_entries 'echo "input params: $@"'

    mock today "echo '2025-03-26'"

    result="$(run)"

    assert_equals "Hi! 👋😊input params: 2025-03-26 2025-03-26" "$result"
}

function test_help() {
    mock check_dependencies ok
    mock config_exists ok

    # Sunday
    mock today "echo '2025-03-02'"

    result="$(run help)"

    assert_contains "Available options" "$result"
}

function test_daily_entry_creation_on_a_weekend() {
    mock check_dependencies ok
    mock config_exists ok
    mock show_greetings ok

    # Sunday
    mock today "echo '2025-03-02'"

    result="$(run)"

    assert_contains "Today must be a working day" "$result"
}

function test_when_week_has_finished_entries_are_created_for_all_the_week() {
    mock config_exists ok
    mock show_greetings ok

    mock create_remote_time_entries 'echo "input params: $@"'
    
    mock today "echo '2025-03-01'"

    result="$(run "week")"

    assert_contains "input params: 2025-02-24 2025-02-28" "$result"
}

function test_when_week_hasnt_finished_yet_it_does_what_it_can() {
    mock config_exists ok
    mock show_greetings ok
    
    mock create_remote_time_entries 'echo "input params: $@"'

    mock today "echo '2025-02-26'"

    result="$(run "week")"

    assert_contains "input params: 2025-02-24 2025-02-26" "$result"
}

function test_when_start_date_and_end_date_are_passed_but_end_date_is_invalid() {
    mock config_exists ok
    mock show_greetings ok

    result="$(run "2025-02-24" "wrong")"

    assert_contains "End Date is required" "$result"
}

function test_when_start_date_and_end_date() {
    mock config_exists ok
    mock show_greetings ok
    
    mock create_remote_time_entries 'echo "input params: $@"'

    result="$(run "2025-02-24" "2025-02-27")"

    assert_contains "input params: 2025-02-24 2025-02-27" "$result"
}

function test_show_last_time_entry() {
    mock config_exists ok
    mock show_greetings ok

    mock show_last_timespan_entry 'echo "method called"'
    
    # mock today "echo '2025-03-01'"

    result="$(run "last")"

    assert_contains "This is how it looks your last timespan entry" "$result"
    assert_contains "method called" "$result"
}
