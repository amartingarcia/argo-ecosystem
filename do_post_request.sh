#!/bin/bash

# Do post request
function do_post_request {
    # $1: url, $2: body
    #curl -X POST $1 -d $2
    curl -X POST $1 -d $2 -H "Content-Type: application/json"
}

# Main execution flow
if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <url> (<key=value>...)"
    exit 1
fi

# Parse key-value pairs to form the JSON body
body=""

for i in $(seq 2 $#); do
    key=$(echo ${!i} | cut -d'=' -f1)
    value=$(echo ${!i} | cut -d'=' -f2)
    body="$body\"$key\":\"$value\","
done

body="{${body%,}}"

do_post_request $1 $body
echo
