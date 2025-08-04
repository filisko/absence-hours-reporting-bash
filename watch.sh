#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# watch for code changes (tests or src) and 

if ! command -v inotifywait &>/dev/null; then
    echo "inotifywait is not installed (apt-get install inotify-tools)!"
    exit 1
fi

tests="${1:-$DIR/tests}"
code="${2:-$DIR/src}"

$DIR/lib/bashunit $tests
echo $tests

while inotifywait -e modify $tests $code; do
    $DIR/lib/bashunit $tests
done
