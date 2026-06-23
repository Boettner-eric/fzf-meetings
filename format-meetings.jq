def calculate_rerun($cache_time_minutes):
  if (now / 60 - $cache_time_minutes) < 5 then {} else {"rerun": 1} end;

def parse_cache_time($cache_time_str):
  ($cache_time_str | strptime("%d/%m/%Y, %H:%M:%S") | mktime) / 60;

def pad_zero: if . < 10 then "0\(.)" else "\(.)" end;

def get_day_name:
  ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"][.];

def format_time_range($time_str):
  ($time_str | split(" - ") | map(strptime("%Y-%m-%dT%H:%M:%S"))) as [$s, $e]
  | "\($s[3]):\($s[4] | pad_zero) - \($e[3]):\($e[4] | pad_zero)";

def format_simple_time($time_parts):
  "\($time_parts[3] | pad_zero):\($time_parts[4] | pad_zero)";
  
def calc_minute_diff($minutes):
  $minutes - (now | strflocaltime("%Y-%m-%dT%H:%M:%S%z") | strptime("%Y-%m-%dT%H:%M:%S%z") | mktime / 60 - 1) | floor;

def calc_day_diff($time_str):
  (($time_str | split(" - ")[0] | strptime("%Y-%m-%dT%H:%M:%S") | mktime) - 
   (now | strflocaltime("%Y-%m-%d") | strptime("%Y-%m-%d") | mktime)) / 86400 | floor;

def format_duration_phrase($mins):
  if $mins == 1 then "a minute"
  elif $mins < 60 then "\($mins) minutes"
  else
    ($mins / 60 | floor) as $h
    | ($mins % 60) as $m
    | (if $h == 1 then "1 hour" else "\($h) hours" end) as $hour_part
    | if $m == 0 then $hour_part
      elif $m == 1 then "\($hour_part) 1 minute"
      else "\($hour_part) \($m) minutes" end
  end;

def today($minutes_until; $time_range):
  if $minutes_until < 1 then "right now"
  elif $minutes_until >= 1440 then "Today from \($time_range)"
  else
    (if $minutes_until >= 60 and $minutes_until < 120 then "Today at" else "Today from" end) as $when
    | "in \(format_duration_phrase($minutes_until)) | \($when) \($time_range)"
  end;

def update_meeting_subtitle($meeting):
  ($meeting.time | split(" - ") | map(strptime("%Y-%m-%dT%H:%M:%S") | mktime / 60)) as [$start, $end]
  | ($meeting.time | split(" - ") | map(strptime("%Y-%m-%dT%H:%M:%S"))) as [$start_parts, $end_parts]
  | calc_minute_diff($start) as $minutes_until
  | calc_minute_diff($end) as $minutes_left
  | calc_day_diff($meeting.time) as $days_until
  | format_time_range($meeting.time) as $time_range
  | format_simple_time($start_parts) as $simple_time
  | ($meeting + {
      "subtitle": (
        if $minutes_until <= 0 and $minutes_left == 1 then "now (about to end)"   
        elif $minutes_until <= 0 and $minutes_left > 0 then "now (\(format_duration_phrase($minutes_left)) left)"
        elif $minutes_left <= 0 or $days_until < 0 then empty
        elif $days_until == 0 then today($minutes_until; $time_range)
        elif $days_until == 1 then "Tomorrow from \($time_range)"
        elif $days_until < 7 then "\(($start_parts[6]) | get_day_name) \($simple_time)"
        elif $days_until < 14 then "Next \(($start_parts[6]) | get_day_name) \($simple_time)"
        elif $days_until < 21 then "in 2 weeks \($simple_time)"
        elif $days_until < 31 then "\($days_until / 7 | floor) weeks from now"
        elif $days_until < 365 then "\($days_until / 30 | floor) months from now"
        else "\($days_until / 365 | floor) years from now" end
      ),
      "timeframe": (
        if $minutes_until <= 0 and $minutes_left > 0 and $minutes_left < 60 then "now (\($minutes_left)m left)"
        elif $minutes_until <= 0 and $minutes_left > 0 then "now"
        elif $minutes_left <= 0 or $days_until < 0 then empty
        elif $days_until == 0 and $minutes_until < 60 then "in \($minutes_until | tostring | if length == 1 then " " + . else . end)m \($simple_time)"
        elif $days_until == 0  then "\($simple_time)"
        elif $days_until < 7 then "\(($start_parts[6]) | get_day_name | .[0:2]) \($simple_time)"
        elif $days_until < 21 then "\($days_until / 7 | floor)w \($simple_time)"
        else "in \($days_until) days \($simple_time)" end
      )
    });

. + calculate_rerun(parse_cache_time(.variables.cache_time)) 
| .items |= map(update_meeting_subtitle(.))