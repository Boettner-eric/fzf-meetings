#!/usr/bin/env zsh
# A fzf script to fetch and display google calendar events via fzf

open_meeting_url() {
  local url="$1"
  local zoom_regex='https?://([a-zA-Z0-9-]+\.)?zoom\.us/j/([0-9]+)'
  
  if [[ "$url" =~ $zoom_regex ]]; then
    local conf_id="${match[2]}"
    local pwd_regex='pwd=([^&]+)'
    local zoom_url="zoommtg://zoom.us/join?confno=${conf_id}"
    
    if [[ "$url" =~ $pwd_regex ]]; then
      zoom_url="${zoom_url}&pwd=${match[1]}"
    fi
    
    open "$zoom_url"
  else
    open "$url"
  fi
}

meetings=$(jq -f format-meetings.jq meetings.json)
rerun=$(echo "$meetings" | jq -r .rerun)

# need this to calculate padding
width=$(tput cols)

# fetch a fresh set of meetings when the cache is stale
local reload_opt=()
if [[ -n "$rerun" && "$rerun" != "null" ]]; then
  reload_opt=(--bind "load:reload(./reload-meetings.sh $width)+unbind(load)")
fi

local jq_args='[(.title + " " + (" " * (($width | tonumber - 10) - (.title | length) - (.timeframe | length))) + "\u001b[2m" + .timeframe + "\u001b[0m"), (. | @json)]'

result=$(
  echo $meetings | \
  jq -r ".items[] | $jq_args | @tsv" --arg width "$width" | \
  fzf --delimiter=$'\t' \
    --border --padding 1,1 \
    --border-label ' Meetings ' \
    --with-nth=1 \
    --ansi \
    "${reload_opt[@]}" \
    --preview='echo {2} | jq -r "\" \" + .title + \"\n \" + .subtitle + \"\n \" + .arg"' \
    --preview-window=up:3:wrap \
    --header='Enter: Open meeting | Alt-O: Open calendar | Ctrl-O: Copy meeting URL' \
    --expect=alt-o,ctrl-o,enter
  )
# can't bind the cmd key to anything in the terminal

key=$(echo "$result" | head -1)
selection=$(echo "$result" | tail -n +2 | cut -f2)

if [ -n "$selection" ]; then
  case "$key" in
    alt-o)
      echo "$selection" | jq -r .calendar | xargs open
      echo "$selection" | jq -r '"Opened "  + .email + " calendar to: " + .title';;
    ctrl-o)
      echo "$selection" | jq -r ".arg" | pbcopy 
      echo "$selection" | jq -r '"Copied URL: " + .arg';;
    enter|o)
      open_meeting_url $(echo "$selection" | jq -r .arg)
      echo "$selection" | jq -r '.title + "\n" + .subtitle';;
  esac
else
  echo "No meeting selected"
fi
