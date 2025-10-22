#!/bin/bash

# Exit if any of the intermediate steps fail
set -e

# jq will ensure that the values are properly quoted
# and escaped for consumption by the shell.
eval "$(jq -r '@sh "client_id=\(.client_id) secret_name=\(.secret_name)"')"

export az_response=$(az ad app credential reset --id "${client_id}" --append --output json --display-name "${secret_name}" --years 100)
secret=$( jq -r  '.password' <<< "${az_response}" ) 
# Safely produce a JSON object containing the result value.
# jq will ensure that the value is properly quoted
# and escaped to produce a valid JSON string.
jq -n --arg secret "$secret" '{"secret":$secret}'
