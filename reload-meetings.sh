#!/usr/bin/env zsh
# This will be called via fzf's load binding (to reload the results list on first load)
# It fetches new meetings with the python script then formats and sends them to fzf

local jq_args='[(.title + " " + (" " * (($width | tonumber - 10) - (.title | length) - (.timeframe | length))) + "\u001b[2m" + .timeframe + "\u001b[0m"), (. | @json)]'

python3 meetings.py > /dev/null
jq -f format-meetings.jq meetings.json | jq -r ".items[] | $jq_args | @tsv" --arg width "$1"
