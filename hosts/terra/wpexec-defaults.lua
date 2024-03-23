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

om:connect('object-added', function(_, node)
  Core.timeout_add(100, function()
    local name = node.properties['node.name']
    local media_class = node.properties['media.class']

    Core.require_api('default-nodes', function(default_nodes)
      default_nodes:call('set-default-configured-node-name', media_class, name)
      local headphones_found = default_nodes:call('get-default-configured-node-name', 'Audio/Sink') == headphones
      local microphone_found = default_nodes:call('get-default-configured-node-name', 'Audio/Source') == microphone
      if headphones_found and microphone_found then
        Core.quit()
      end
    end)

    return true
  end)

end)

om:activate()
