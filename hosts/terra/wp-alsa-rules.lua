local disable_devices = {
  matches = {
    -- GPU HDMI audio.
    {{ "device.name", "equals", "alsa_card.pci-0000_03_00.1" }},
  },
  apply_properties = {
    ["device.disabled"] = true,
  },
}
table.insert(alsa_monitor.rules, disable_devices)

local disable_nodes = {
  matches = {
    -- Microphone sink.
    {{ "node.name", "matches", "alsa_output.usb-FIFINE_Microphones_Fifine*.analog-stereo" }},
  },
  apply_properties = {
    ["node.disabled"] = true,
  },
}
table.insert(alsa_monitor.rules, disable_nodes)

local disable_spdif = {
  matches = {
    {{ "device.nick", "equals", "Fifine K658  Microphone"}},
    {{ "device.nick", "equals", "JDS Labs EL DAC II+"}},
  },
  apply_properties = {
    ["device.profile-set"] = "analog-only.conf"
  }
}
table.insert(alsa_monitor.rules, disable_spdif)
