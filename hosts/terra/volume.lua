local dac = "JDS Labs EL DAC II+"
local mic = "Fifine K658  Microphone"

local function to_interest(string)
  return Interest {
    type = "node",
    Constraint { "media.class", "equals", "Audio/Sink", type = "pw-global" },
    Constraint { "node.nick", "equals", string, type = "pw-global" },
  }
end

local om = ObjectManager {
  to_interest(dac),
  to_interest(mic),
}

local dac_found = false
local mic_found = false
om:connect('object-added', function(_, node)
  local nick = node.properties['node.nick']
  if nick == dac then
    dac_found = true
  elseif nick == mic then
    mic_found = true
  end

  Core.require_api('mixer', function(mixer)
    mixer:call('set-volume', node['bound-id'], 1.0)

    if dac_found and mic_found then
      Core.quit()
    end
  end)
end)

om:activate()
