local conditions = require('heirline.conditions')
local utils = require('plugins.heirline.utils')
local kanagawa = require('kanagawa.colors').setup()

local slants = utils.separators.slant
local palette = utils.palette

return {
  condition = conditions.has_diagnostics,

  static = {
    error_icon = '',
    warn_icon = '',
    info_icon = '',
    hint_icon = '',
  },

  init = function(self)
    self.errors = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.ERROR })
    self.warnings = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.WARN })
    self.hints = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.HINT })
    self.info = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.INFO })
  end,

  {
    provider = slants.ld,
    hl = { fg = kanagawa.sumiInk0, bg = palette.modules.bg }
  },
  {
    provider = function(self)
      return self.errors > 0 and (self.error_icon .. ' ' .. self.errors)
    end,
    hl = { fg = kanagawa.autumnRed, bg = kanagawa.sumiInk0 },
  },
  {
    provider = function(self)
      return self.warnings > 0 and (self.warn_icon .. ' ' .. self.warnings)
    end,
    hl = { fg = kanagawa.autumnYellow, bg = kanagawa.sumiInk0 },
  },
  {
    provider = function(self)
      return self.info > 0 and (self.info_icon .. ' ' .. self.info)
    end,
    hl = { fg = kanagawa.waveAqua1, bg = kanagawa.sumiInk0 },
  },
  {
    provider = function(self)
      return self.hints > 0 and (self.hint_icon .. ' ' .. self.hints)
    end,
    hl = { fg = kanagawa.dragonBlue, bg = kanagawa.sumiInk0 },
  },
  {
    provider = slants.ru,
    hl = { fg = kanagawa.sumiInk0, bg = palette.modules.bg }
  },
}
