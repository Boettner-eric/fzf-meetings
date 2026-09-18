#!/usr/bin/env zsh
# This will be called via fzf's load binding (to reload the results list on first load)
# It fetches new meetings with the python script then formats and sends them to fzf

local jq_args='[(.title + " " + (" " * (($width | tonumber - 10) - (.title | length) - (.timeframe | length))) + "\u001b[2m" + .timeframe + "\u001b[0m"), (. | @json)]'

# Exclude list from config.json, e.g. {"exclude": ["event name"]}. Fall back to an
# empty list when the file is missing or the value is not a JSON array so jq never fails on it.
excluded_events="$(jq -c '.exclude // []' config.json 2>/dev/null)"
if ! printf '%s' "$excluded_events" | jq -e 'type == "array"' > /dev/null 2>&1; then
  excluded_events="[]"
fi

./.venv/bin/python3 meetings.py > /dev/null
jq --argjson excluded_events "$excluded_events" -f format-meetings.jq meetings.json | jq -r ".items[] | $jq_args | @tsv" --arg width "$1"
