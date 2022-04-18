#!/run/current-system/sw/bin/awk

/^\w/ { out = $1 }
/(current)/ { res = $1 }
/Position:/ { pos = $2 }
/Transform:/ { transform = $2 }
/Scale:/ { outputs[out] = res ":" pos ":" transform ":" $2 }
END {
  for (output in outputs) {
    split(outputs[output], fields, ":")
    if (fields[4] > max_scale) {
      max_scale = fields[4]
      max_scale_output = output
    }
  }

  for (output in outputs) {
    split(outputs[output], fields, ":")
    split(fields[1], resolution, "x")
    split(fields[2], position, ",")

    if (output != max_scale_output) {
      resolution[1] *= max_scale
      resolution[2] *= max_scale

      if (fields[3] == "normal") {
        position[2] *= max_scale
      } else {
        position[1] *= max_scale

        temp = resolution[2]
        resolution[2] = resolution[1]
        resolution[1] = temp
      }
    }

    # Get the maximum size of the background
    x = position[1] + resolution[1]
    y = position[2] + resolution[2]
    if (x > bg_res[1]) bg_res[1] = x
    if (y > bg_res[2]) bg_res[2] = y

    crop_cmds[output] = sprintf("\\( mpr:bg -crop %ix%i+%i+%i +write /tmp/spanbg_%s.jpg \\)", resolution[1], resolution[2], position[1], position[2], output)
    setbg_cmds[output] = sprintf("-o %s -i /tmp/spanbg_%s.jpg", output, output)
  }

  # Generate crop command for background
  crop_cmd = sprintf("convert %s -resize %ix%i -write mpr:bg +delete -respect-parentheses", bg, bg_res[1], bg_res[2])
  for (output in crop_cmds) {
    crop_cmd = crop_cmd " " crop_cmds[output]
  }
  system(crop_cmd)

  # Generate set backgrounds command
  setbg_cmd = "swaybg"
  for (output in setbg_cmds) {
    setbg_cmd = setbg_cmd " " setbg_cmds[output]
  }
  system(setbg_cmd)
}

