local set = vim.opt

-- Disable builtin plugins
vim.g.loaded_matchit = 0
vim.g.loaded_matchparen = 0
vim.g.loaded_getscript = 1
vim.g.loaded_getscriptPlugin = 1
vim.g.loaded_gzip = 1
vim.g.loaded_logiPat = 1
vim.g.loaded_netrw = 1
vim.g.loaded_netrwFileHandlers = 1
vim.g.loaded_netrwPlugin = 1
vim.g.loaded_netrwSettings = 1
vim.g.loaded_rrhelper = 1
vim.g.loaded_tar = 1
vim.g.loaded_tarPlugin = 1
vim.g.loaded_vimball = 1
vim.g.loaded_vimballPlugin = 1
vim.g.loaded_zip = 1
vim.g.loaded_zipPlugin = 1
vim.g.loaded_2html_plugin = 1

vim.g.mapleader = ' '

set.termguicolors = true
set.hidden = true -- Allow dirty buffers in the background
set.showmode = false -- Don't show mode in command line

set.backspace = 'indent,eol,start'

set.number = true -- Show current line number
set.ruler = true -- Show cursor location in file
set.updatetime = 300 -- Delay after user input before plugins are activated

set.cursorline = true -- Highlight line of cursor while in Insert mode
local augroup = vim.api.nvim_create_augroup("ActiveBufferCursorline", { clear = true })
vim.api.nvim_create_autocmd("BufEnter", {
  group = augroup,
  pattern = "*",
  callback = function() vim.opt.cursorline = true end
})
vim.api.nvim_create_autocmd("BufLeave", {
  group = augroup,
  pattern = "*",
  callback = function() vim.opt.cursorline = false end
})

set.hlsearch = true -- Highlight search matches
set.incsearch = true -- Highlight search matches while typing
set.inccommand = 'nosplit' -- Live preview when substituting
set.smartcase = true -- Match search pattern case only if pattern is mixed case

set.autoindent = true -- Maintain current indentation on new line
set.expandtab = true -- Tabs are expanded into spaces
set.shiftwidth = 2 -- Use 2 spaces for indentation
set.tabstop = 2 -- Tabs are 2 spaces wide

set.wrap = false -- Prevent lines from wrapping
set.splitbelow = true -- Put new windows below current
set.splitright = true -- Put new windows right of current

-- Show non-whitespace characters while in Insert mode
set.listchars:append('eol:↲')
set.listchars:append('space:·')
set.listchars:append('tab:––>')
set.listchars:append('nbsp:×')

local augroup = vim.api.nvim_create_augroup("InsertModeListChars", { clear = true })
vim.api.nvim_create_autocmd("InsertEnter", {
  group = augroup,
  pattern = "*",
  callback = function() vim.opt.list = true end
})
vim.api.nvim_create_autocmd({ "InsertLeave", "InsertLeavePre" }, {
  group = augroup,
  pattern = "*",
  callback = function() vim.opt.list = false end
})
