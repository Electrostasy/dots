-- Disable builtin plugins
vim.g.loaded_matchit = 1
vim.g.loaded_matchparen = 1
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

vim.opt.termguicolors = true
vim.opt.hidden = true -- Allow dirty buffers in the background
vim.opt.showmode = false -- Don't show mode in command line

vim.opt.backspace = 'indent,eol,start'

vim.opt.number = true -- Show current line number
vim.opt.ruler = true -- Show cursor location in file
vim.opt.updatetime = 300 -- Delay after user input before plugins are activated
vim.opt.timeoutlen = 500

vim.opt.cursorline = true -- Highlight line of cursor while in Insert mode
local augroup = vim.api.nvim_create_augroup('ActiveBufferCursorline', { clear = true })
vim.api.nvim_create_autocmd('BufEnter', {
  group = augroup,
  pattern = '*',
  callback = function() vim.opt.cursorline = true end
})
vim.api.nvim_create_autocmd('BufLeave', {
  group = augroup,
  pattern = '*',
  callback = function() vim.opt.cursorline = false end
})

vim.opt.hlsearch = true -- Highlight search matches
vim.opt.incsearch = true -- Highlight search matches while typing
vim.opt.inccommand = 'nosplit' -- Live preview when substituting
vim.opt.smartcase = true -- Match search pattern case only if pattern is mixed case

vim.opt.autoindent = true -- Maintain current indentation on new line
vim.opt.expandtab = true -- Tabs are expanded into spaces
vim.opt.shiftwidth = 2 -- Use 2 spaces for indentation
vim.opt.tabstop = 2 -- Tabs are 2 spaces wide

vim.opt.wrap = false -- Prevent lines from wrapping
vim.opt.splitbelow = true -- Put new windows below current
vim.opt.splitright = true -- Put new windows right of current

-- Show non-whitespace characters while in Insert mode
vim.opt.listchars = {
  eol = '↲',
  space = '·',
  tab = '––>',
  nbsp = '×'
}
augroup = vim.api.nvim_create_augroup('InsertModeListChars', { clear = true })
vim.api.nvim_create_autocmd('InsertEnter', {
  group = augroup,
  pattern = '*',
  callback = function() vim.opt.list = true end
})
vim.api.nvim_create_autocmd({ 'InsertLeave', 'InsertLeavePre' }, {
  group = augroup,
  pattern = '*',
  callback = function() vim.opt.list = false end
})

-- Filetypes configuration
local filetypes = {
  filenames = {
    ['flake.lock'] = 'json',
    ['cargo.lock'] = 'toml'
  },
  extensions = {
    yuck = 'clojure'
  },
}

vim.g.do_filetype_lua = 1
vim.filetype.add({
  filename = filetypes.filenames,
  extension = filetypes.extensions
})
-- Loads filetype in telescope
require('plenary.filetype').add_table({
  file_name = filetypes.filenames,
  extension = filetypes.extensions
})
