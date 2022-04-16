#!/usr/bin/env fish

set -l opts (fish_opt -s v -l volume -r)
set opts $opts (fish_opt -s m -l mute_switch)
set opts $opts (fish_opt -s o -l object_id -r)
set opts $opts (fish_opt -s p -l playback_monitor)
set opts $opts (fish_opt -s r -l record_monitor)
set opts $opts (fish_opt -s n -l nodes)
argparse $opts -- $argv

# jq can't find the scripts without changing cwd
cd (realpath (dirname (status -f)))

if set -q _flag_v; and set -q _flag_o
  pw-cli set-param $_flag_o Props "{\"volume\": $(math $_flag_v / 100.0)}"
end

if set -q _flag_m; and set -q _flag_m
  set -l muted (pw-dump $_flag_o | jq '.[].info.params.Props | map(select(.mute != null) | .mute) | flatten[]')
  switch $muted
    case 'true'; set muted 'false'
    case 'false'; set muted 'true'
  end
  pw-cli set-param $_flag_o Props "{\"mute\": $muted}"
end

function monitor_volume -a "type"
  set -l id (pw-cat "-$type" --list-targets | string match -rg '^\*\s(\d{1,})')
  pw-dump -m $id | jq -f ./volume-mute-filter.jq
end

if set -q _flag_p; monitor_volume "p"; end
if set -q _flag_r; monitor_volume "r"; end

if set -q _flag_n
  pw-dump -m | jq -ncMf ./pw-nodes-filter.jq
end
