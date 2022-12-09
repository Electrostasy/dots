#!/usr/bin/env awk -f

function reorient(to) {
  switch (to) {
    case "normal": transform = "90";    break
    case "90":     transform = "180";   break
    case "180":    transform = "270";   break
    case "270":    transform = "normal"
  }
  system(sprintf("wlr-randr --output LVDS-1 --transform %s", transform))
}

/^LVDS-1/ { found = !found }
/^  / { if (found && $1 == "Transform:") { reorient($2) }}
