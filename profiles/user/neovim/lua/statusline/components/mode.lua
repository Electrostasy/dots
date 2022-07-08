local utils = require('statusline.utils')
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
    mode_colours = {
      n = kanagawa.fujiWhite,
      i = kanagawa.autumnYellow,
      v = kanagawa.springBlue,
      V = kanagawa.springBlue,
      ["\22"] = kanagawa.springBlue,
      c = kanagawa.surimiOrange,
      s = kanagawa.waveBlue2,
      S = kanagawa.waveBlue2,
      ["\19"] = kanagawa.springBlue,
      r = kanagawa.springGreen,
      R = kanagawa.springGreen,
      ["!"] = kanagawa.peachRed,
      t = kanagawa.peachRed
    }
  },

  init = function(self)
    self.mode = vim.fn.mode()
    self.mode_name = self.mode_names[self.mode]
    self.mode_colour = self.mode_colours[self.mode]
  end,

  {
    provider = ' ',
    hl = function(self)
      return { fg = self.mode_colour }
    end,
  },
  {
    provider = function(self)
      return ' ' .. self.mode_name .. ' '
    end,
    hl = function(self)
      return { fg = palette.modules.bg, bg = self.mode_colour, bold = true }
    end
  },
  {
    provider = slants.lu,
    hl = function(self)
      return { fg = palette.modules.bg, bg = self.mode_colour }
    end,
  }
}
