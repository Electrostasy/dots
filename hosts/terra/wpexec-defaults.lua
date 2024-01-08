local headphones = "hifiman_sundara_input"
local microphone = "rnnoise_output";

local om = ObjectManager {
  Interest {
    type = "node",
    Constraint { "media.class", "equals", "Audio/Sink", type = "pw-global" },
    Constraint { "node.name", "equals", headphones, type = "pw-global" },
  },

  Interest {
    type = "node",
    Constraint { "media.class", "equals", "Audio/Source", type = "pw-global" },
    Constraint { "node.name", "equals", microphone, type = "pw-global" },
  }
}

local headphones_found = false
local microphone_found = false
om:connect('object-added', function(_, node)
  local name = node.properties['node.name']
  local media_class = node.properties['media.class']

  if not headphones_found and name == headphones then
    headphones_found = true
  end

  if not microphone_found and name == microphone then
    microphone_found = true
  end

  Core.require_api('default-nodes', function(default_nodes)
    default_nodes:call('set-default-configured-node-name', media_class, name)
    if headphones_found and microphone_found then
      Core.quit()
    end
  end)

end)

om:activate()
