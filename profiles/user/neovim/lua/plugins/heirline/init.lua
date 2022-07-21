-- Global statusline
vim.opt.laststatus = 3
vim.opt.fillchars:append({
  horiz = '━',
  horizup = '┻',
  horizdown = '┳',
  vert = '┃',
  vertleft = '┨',
  vertright = '┣',
  verthoriz = '╋',
})

local colours = require('kanagawa.colors').setup()
local theme = require('kanagawa.themes').default(colours)

local conditions = require('heirline.conditions')
local utils = require('plugins.heirline.utils')

local palette = utils.palette

-- Statusline components
local mode = require('plugins.heirline.components.mode')
local git = require('plugins.heirline.components.git')
local filename = require('plugins.heirline.components.filename')
local diagnostics = require('plugins.heirline.components.diagnostics')
local lsp = {
  condition = conditions.lsp_attached,
  provider = function()
    local names = {}
    for _, server in pairs(vim.lsp.buf_get_clients(0)) do
      if server.name ~= 'null-ls' then
        table.insert(names, server.name)
      end
    end
    return table.concat(names, ' ')
  end,
  hl = { fg = theme.bg_light2, bg = palette.modules.bg }
}
local encoding = {
  provider = (vim.bo.fenc ~= '' and vim.bo.fenc) or vim.o.enc,
  hl = { fg = theme.bg_light2, bg = palette.modules.bg, italic = true }
}
local ruler = {
  provider = '%l/%L:%c',
  hl = { fg = theme.bg_light2, bg = palette.modules.bg }
}
local indent_type = {
  provider = function()
    local indent = vim.o.tabstop
    local indent_by = vim.o.shiftwidth

    local tabs_or_spaces = indent .. ' ' .. (vim.o.expandtab and 'spaces' or 'tabs')
    local indent_increase = indent ~= indent_by and 'sw=' .. indent_by or ''

    return tabs_or_spaces .. ' ' .. indent_increase
  end,
  hl = { fg = theme.bg_light2, bg = palette.modules.bg, italic = true }
}
local right_align = { provider = '%=' }
local space = { provider = ' ' }

require('heirline').setup({
  mode,
  filename, space,
  encoding, space,
  indent_type, right_align, space,
  ruler, space,
  diagnostics, lsp, space, git,

  static = {
    mode_colours = {
      n = theme.sm,
      i = theme.git.changed,
      v = theme.sp,
      V = theme.sp,
      ["\22"] = theme.sp,
      c = theme.sp3,
      s = theme.sp,
      S = theme.sp,
      ["\19"] = theme.sp,
      r = theme.git.changed,
      R = theme.git.changed,
      ["!"] = theme.git.removed,
      t = theme.fg_dark
    },
    get_mode_colour = function(self)
      local current_mode = conditions.is_active() and vim.fn.mode() or 'n'
      return self.mode_colours[current_mode]
    end
  }
})
