#!/usr/bin/env fish

set -l opts (fish_opt -s v -l var_toggle)
set opts $opts (fish_opt -s i -l init)
set opts $opts (fish_opt -s w -l win_toggle)
set opts $opts (fish_opt -s n -l name -r)
argparse -x 'v,w' $opts -- $argv

if set -q _flag_i
  for window in bar clock audio
    eww open $window
  end
end

if set -q _flag_v; and set -q _flag_n
  set -l value (eww get $_flag_n)
  switch $value
    case true; set value false
    case false; set value true
  end
  eww update $_flag_n=$value
end
