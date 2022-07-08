local colours = require('kanagawa.colors').setup()

local M = {}

M.palette = {
  modules = {
    fg = colours.fujiWhite, bg = colours.sumiInk0
  },
  git = {
    additions = { fg = colours.autumnGreen, bg = colours.winterGreen },
    removals = { fg = colours.autumnRed, bg = colours.winterRed },
    changes = { fg = colours.autumnYellow, bg = colours.winterYellow },
    branch = { fg = colours.sumiInk0, bg = colours.autumnGreen },
  },
}

M.separators = {
  block = '█',
  slant = {
    lu = '',
    ld = '',
    ru = '',
    rd = ''
  }
}

return M
