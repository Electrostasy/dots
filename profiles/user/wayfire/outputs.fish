#!/usr/bin/env fish

set -l outputs (wlopm -j | jq -r '.[].output')

argparse -x on,off 'on' 'off' -- $argv
if set -q _flag_on
  for output in $outputs
    wlopm --on $output
  end
  return 0
end
if set -q _flag_off
  for output in $outputs
    wlopm --off $output
  end
  return 0
end
echo 'Usage:'
echo '  --on: turn all outputs on'
echo '  --off: turn all outputs off'
return 1
