local dac = "alsa_output.usb-JDS_Labs_JDS_Labs_EL_DAC_II_-00.analog-stereo"

local om = ObjectManager {
  Interest {
    type = "node",
    Constraint { "media.class", "equals", "Audio/Sink", type = "pw-global" },
    Constraint { "node.name", "equals", dac, type = "pw-global" },
  }
}

om:connect('object-added', function(_, node)
  local id = node['bound-id']

  -- There seems to be some kind of strange race condition going on here. Unless
  -- there is a timeout, WirePlumber will NEVER set the volume correctly on
  -- startup or reload of the service, but it always works when run manually.
  -- Workaround: keep trying to set volume until it works. Ugh.
  Core.timeout_add(100, function()
    Core.require_api('mixer', function(mixer)
      mixer:call('set-volume', id, 1.0)
      if mixer:call('get-volume', id).volume > 0.999 then
        Core.quit()
      end
    end)
    return true
  end)

end)

om:activate()
