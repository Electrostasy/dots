#!/usr/bin/env fish

set -l opts (fish_opt -s d -l date)
set opts $opts (fish_opt -s t -l time)
argparse $opts -- $argv

if set -q _flag_d
  while true
    date +"%Y-%m-%d"
    sleep (math (date -d "tomorrow 00:00:00" +"%s") - (date +"%s"))
  end
end

if set -q _flag_t
  while true
    date +"%R"
    sleep (math 60 - (date +"%S"))
  end
end
