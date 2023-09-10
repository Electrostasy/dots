local disable_devices = {
  matches = {
    -- GPU HDMI audio.
    {{ "device.name", "equals", "alsa_card.pci-0000_03_00.1" }},
  },
  apply_properties = {
    ["device.disabled"] = true,
  },
}

local disable_nodes = {
  matches = {
    -- Microphone.
    {{ "node.name", "equals", "alsa_output.usb-FIFINE_Microphones_Fifine_K658_Microphone_REV1.0-00.analog-stereo" }},
  },
  apply_properties = {
    ["node.disabled"] = true,
  },
}

table.insert(alsa_monitor.rules, disable_devices)
table.insert(alsa_monitor.rules, disable_nodes)
