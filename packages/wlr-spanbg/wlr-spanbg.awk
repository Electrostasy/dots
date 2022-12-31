/^\w/ { out = $1 }
/Physical size/ { phys = $3 }
/current/ { res = $1 }
/Position:/ { pos = $2 }
/Transform:/ { transform = $2 }
/Scale:/ { outputs[out] = phys ":" res ":" pos ":" transform ":" $2 }
END {
  for (output in outputs) {
    split(outputs[output], fields, ":")

    split(fields[2], resolution, "x")
    w = resolution[1]
    h = resolution[2]

    split(fields[3], position, ",")
    x = position[1]
    y = position[2]

    transform = fields[4]
    switch (transform) {
      case "normal":
        break;
      case 90:
      case 270:
        t = h
        h = w
        w = t
        break
    }

    # TODO: Currently, scaling makes a 3840p screen with 1.5 scaling use a
    # 1440p background. Need to figure out a way to use the native res. At
    # least it's aligned now.
    scale = fields[5]
    w = w / scale
    h = h / scale

    crop_cmds[output] = sprintf("\\( mpr:bg -crop %ix%i+%i+%i +write /tmp/spanbg_%s.jpg \\)", w, h, x, y, output)
    setbg_cmds[output] = sprintf("-o %s -i /tmp/spanbg_%s.jpg", output, output)
  }

  crop_cmd = sprintf("magick %s -write mpr:bg +delete", bg)
  for (output in outputs) {
    crop_cmd = crop_cmd " " crop_cmds[output]
  }
  crop_cmd = crop_cmd " null:"
  system(crop_cmd)

  setbg_cmd = "swaybg"
  for (output in setbg_cmds) {
    setbg_cmd = setbg_cmd " " setbg_cmds[output]
  }
  system(setbg_cmd)
}
