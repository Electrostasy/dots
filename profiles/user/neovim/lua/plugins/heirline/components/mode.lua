local utils = require('plugins.heirline.utils')
local kanagawa = require('kanagawa.colors').setup()

local palette = utils.palette
local slants = utils.separators.slant

return {
  static = {
    mode_names = {
      n = "Normal",
      no = "Normal",
      nov = "Normal",
      noV = "Normal",
      ["no\22"] = "Normal",
      niI = "Normal",
      niR = "Normal",
      niV = "Normal",
      nt = "Normal",
      v = "Visual",
      vs = "Visual",
      V = "V-Line",
      Vs = "V-Line",
      ["\22"] = "V-Block",
      ["\22ss"] = "V-Block",
      s = "Select",
      S = "Select",
      ["\19"] = "Select",
      i = "Insert",
      ic = "Insert",
      ix = "Insert",
      R = "Replace",
      Rc = "Replace",
      Rx = "Replace",
      Rv = "V-Replace",
      Rvc = "V-Replace",
      Rvx = "V-Replace",
      c = "Command",
      cv = "Ex-Command",
      r = "Prompt",
      rm = "More Prompt",
      ["r?"] = "Confirm",
      ["!"] = "Shell",
      t = "Terminal",
    },
  },

  init = function(self)
    self.mode_name = self.mode_names[vim.fn.mode()]
  end,

  {
    provider = ' ',
    hl = function(self)
      return { fg = self:get_mode_colour() }
    end,
  },
  {
    provider = function(self)
      return ' ' .. self.mode_name .. ' '
    end,
    hl = function(self)
      return { fg = palette.modules.bg, bg = self:get_mode_colour(), bold = true }
    end
  },
  {
    provider = slants.lu,
    hl = function(self)
      return { fg = palette.modules.bg, bg = self:get_mode_colour() }
    end,
  }
}
