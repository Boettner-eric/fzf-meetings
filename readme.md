# Meetings

A CLI tool to use fzf to show and join google calendar meetings

<img src="screenshots/meets.png" width="600">

# Supports

- Google Meets
- Microsoft Teams
- Zoom Meetings
- Slack Huddles

# Setup

- setup your google calendar api access via this [guide](https://developers.google.com/workspace/calendar/api/quickstart/python#set-up-environment)
- save your generated `credentials.json` to this folder
- `make install` to build `.venv/` and install python requirements
- run `./.venv/bin/python3 meetings.py --register USERNAME` to login a user (supports multiple users via /tokens dir)
- optionally add event titles to `exclude` in `config.json` to hide them (exact title, case insensitive)

# How it works

- `meetings.json` stores a cache of the most recent fetched events
- `config.json` holds user settings, currently just the `exclude` list of event titles to hide
- `meetings-fzf.sh` displays that cache via `format-meetings.jq`
- after the initial load `meetings-fzf.sh` calls `reload-meetings.sh` to rebuild the cache and rerender fzf
