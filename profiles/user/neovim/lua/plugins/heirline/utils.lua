local colours = require('kanagawa.colors').setup()
local theme = require('kanagawa.themes').default(colours)

local M = {}

M.palette = {
  modules = {
    fg = theme.fg, bg = theme.bg_dark
  },
  git = {
    additions = { fg = theme.git.added, bg = theme.diff.add },
    removals = { fg = theme.git.removed, bg = theme.diff.delete },
    changes = { fg = theme.git.changed, bg = theme.diff.text },
    branch = { fg = theme.bg_dark },
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
