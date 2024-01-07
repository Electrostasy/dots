#!/usr/bin/env wpexec

-- Nodes we want to adjust the volume of.
local dac = "JDS Labs EL DAC II+"
local mic = "Fifine K658  Microphone"

-- Nodes we want to set as defaults.
local headphones_eq = "hifiman_sundara_input"
local mic_nc = "rnnoise_output";

local om = ObjectManager {
  Interest {
    type = "node",
    Constraint { "media.class", "equals", "Audio/Sink", type = "pw-global" },
    Constraint { "node.nick", "equals", dac, type = "pw-global" },
  },

  Interest {
    type = "node",
    Constraint { "media.class", "equals", "Audio/Source", type = "pw-global" },
    Constraint { "node.nick", "equals", mic, type = "pw-global" },
  },

  Interest {
    type = "node",
    Constraint { "media.class", "equals", "Audio/Sink", type = "pw-global" },
    Constraint { "node.name", "equals", headphones_eq, type = "pw-global" },
  },

  Interest {
    type = "node",
    Constraint { "media.class", "equals", "Audio/Source", type = "pw-global" },
    Constraint { "node.name", "equals", mic_nc, type = "pw-global" },
  },
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

local headphones_eq_found = false
local mic_nc_found = false
om:connect('object-added', function(_, node)
  local name = node.properties['node.name']
  if name == headphones_eq then
    headphones_eq_found = true
  elseif name == mic_nc then
    mic_nc_found = true
  end

  Core.require_api('default-nodes', function(default_nodes)
    default_nodes:call('set-default-configured-node-name', node.properties['media.class'], name)

    if headphones_eq_found and mic_nc_found then
      Core.quit()
    end
  end)
end)

om:activate()
