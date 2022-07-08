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

local colors = require('kanagawa.colors').setup()
local utils = require('statusline.utils')

local palette = utils.palette

-- Statusline components
local mode = require('statusline.components.mode')
local git = require('statusline.components.git')
local filename = require('statusline.components.filename')
local diagnostics = require('statusline.components.diagnostics')
local encoding = {
  provider = (vim.bo.fenc ~= '' and vim.bo.fenc) or vim.o.enc,
  hl = { fg = colors.sumiInk4, bg = palette.modules.bg, italic = true }
}
local ruler = {
  provider = '%l:%c',
  hl = { fg = colors.sumiInk4, bg = palette.modules.bg, italic = true }
}
local indent_type = {
  provider = function()
    local indent = vim.o.tabstop
    local indent_by = vim.o.shiftwidth

    local tabs_or_spaces = (vim.o.expandtab and 'spc' or 'tab') .. '=' .. indent
    local indent_increase = indent ~= indent_by and 'sw=' .. indent_by or ''

    return tabs_or_spaces .. ' ' .. indent_increase
  end,
  hl = { fg = colors.sumiInk4, bg = palette.modules.bg, italic = true }
}
local right_align = { provider = '%=' }
local space = { provider = ' ' }

local components = {
  filename, space,
  encoding, space,
  indent_type, right_align, space,
  ruler, space,
  diagnostics, git
}
for _, component in ipairs(components) do
  table.insert(mode, component)
end

require('heirline').setup({
  mode
})
