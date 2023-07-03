-- Disable built-in plugins.
vim.g.loaded_netrw = 1
vim.g.loaded_netrwFileHandlers = 1
vim.g.loaded_netrwPlugin = 1
vim.g.loaded_netrwSettings = 1
vim.g.loaded_gzip = 1
vim.g.loaded_tar = 1
vim.g.loaded_tarPlugin = 1
vim.g.loaded_zip = 1
vim.g.loaded_zipPlugin = 1
vim.g.loaded_getscript = 1
vim.g.loaded_getscriptPlugin = 1
vim.g.loaded_vimball = 1
vim.g.loaded_vimballPlugin = 1
vim.g.loaded_matchit = 1
vim.g.loaded_matchparen = 1
vim.g.loaded_2html_plugin = 1

-- Add a blinking cursor in certain modes.
vim.opt.guicursor = {
  'n-c-v:block',
  'i-ci-ve-r-o:blinkwait250-blinkon250-blinkoff250',
  'i-ci-ve:ver25',
  'r-cr-o:hor20'
}

vim.opt.termguicolors = true
vim.opt.background = 'dark'
vim.cmd.colorscheme('tranquil')

require('nvim-treesitter.configs').setup({
  highlight = { enable = true },
  indent = { enable = true },
  incremental_selection = { enable = false },
  playground = { enable = true },

  -- Available under plugins/showpairs.lua.
  showpairs = { enable = true },
})

require('hlargs').setup()
require('gitsigns').setup()

vim.g.mapleader = ' ' -- Set <Leader> for keymaps.
vim.opt.hidden = true -- Allow dirty buffers in the background.
vim.opt.showmode = false -- Don't show mode in command line.
vim.opt.backspace = 'indent,eol,start'
vim.opt.number = true
vim.opt.updatetime = 300 -- Delay after user input before plugins are activated.
vim.opt.timeoutlen = 500
vim.opt.ruler = true

-- Hide search count from message area, it is shown in the statusline.
vim.opt.shortmess:append('S')

-- Highlight line containing cursor only on active buffer.
vim.opt.cursorline = true
vim.api.nvim_create_augroup('ActiveBufferCursorline', { clear = true })
vim.api.nvim_create_autocmd({ 'WinEnter', 'WinLeave' }, {
  group = 'ActiveBufferCursorline',
  pattern = '*',
  callback = function()
    vim.opt_local.cursorline = not vim.opt_local.cursorline:get()
  end
})

-- Highlight yanked region.
vim.api.nvim_create_augroup('HighlightOnYank', { clear = true })
vim.api.nvim_create_autocmd('TextYankPost', {
  group = 'HighlightOnYank',
  pattern = '*',
  callback = function()
    vim.highlight.on_yank({ timeout = 250 })
  end,
})

-- These autocommands set relativenumber when entering visual/select line/block
-- modes, and unset it when leaving them, allowing for easier range-based
-- selections and movements.
vim.api.nvim_create_augroup('DynamicRelativeNumber', { clear = true })
vim.api.nvim_create_autocmd('ModeChanged', {
  group = 'DynamicRelativeNumber',
  -- When switching to visual/select line/block modes.
  pattern = { '*:V', '*:\22', '*:s', '*:\19' },
  callback = function()
    vim.opt_local.relativenumber = true
  end,
})
vim.api.nvim_create_autocmd('ModeChanged', {
  group = 'DynamicRelativeNumber',
  -- When switching from visual/select line/block modes.
  pattern = { 'V:*', '\22:*', 'S:*', '\19:*' },
  callback = function()
    vim.opt_local.relativenumber = false
  end,
})

vim.opt.hlsearch = true -- Highlight search matches.
vim.opt.incsearch = true -- Highlight search matches while typing.
vim.opt.inccommand = 'nosplit' -- Live preview when substituting.
vim.opt.ignorecase = true
vim.opt.smartcase = true

vim.opt.autoindent = true

vim.opt.wrap = false
vim.opt.splitbelow = true
vim.opt.splitright = true

-- Better window separators.
vim.opt.fillchars:append({
  horiz = '━',
  horizup = '┻',
  horizdown = '┳',
  vert = '┃',
  vertleft = '┨',
  vertright = '┣',
  verthoriz = '╋',
})

-- Show listchars while in Insert mode.
local normal_listchars = {
  extends = '»',
  precedes = '«',
  trail = '∙',
}
local insert_listchars = {
  eol = '¶',
  tab = '--▸',
  space = '·',
  lead = '·',
  nbsp = '¤',
}
vim.opt.showbreak = '↳'
vim.opt.list = true
vim.opt.listchars = normal_listchars
vim.api.nvim_create_augroup('InsertModeListChars', { clear = true })
vim.api.nvim_create_autocmd({ 'InsertEnter', 'InsertLeavePre' }, {
  group = 'InsertModeListChars',
  pattern = '*',
  callback = function(args)
    if vim.tbl_contains({ 'quickfix', 'prompt' }, vim.opt_local.buftype:get()) then
      return
    end

    if args.event == 'InsertEnter' then
      vim.opt_local.listchars = insert_listchars
    else
      vim.opt_local.listchars = normal_listchars
    end

    -- Refresh indents, leading whitespace can get stuck when entering/leaving
    -- insert mode.
    require('indent_blankline').refresh()
  end
})

-- Additional filetypes to register.
-- Until plenary.nvim evaluates vim.filetype, we have to register them with
-- plenary.nvim too.
-- https://github.com/nvim-lua/plenary.nvim/issues/400
local filetypes = {
  filename = {
    ['flake.lock'] = 'json',
    ['cargo.lock'] = 'toml'
  },
  extension = {},
}
vim.filetype.add(filetypes)
require('plenary.filetype').add_table({
  file_name = filetypes.filename,
  extension = filetypes.extension
})

-- Keymaps when an LSP is attached to the buffer.
local lsp_lines = require('lsp_lines')
local lsp_mappings = {
  { 'n', 'gD', vim.lsp.buf.declaration, { silent = true, buffer = true } },
  { 'n', 'gd', vim.lsp.buf.definition, { silent = true, buffer = true } },
  { 'n', 'K', vim.lsp.buf.hover, { silent = true, buffer = true } },
  { 'n', 'gi', vim.lsp.buf.implementation, { silent = true, buffer = true } },
  { 'n', '<C-k>', vim.lsp.buf.signature_help, { silent = true, buffer = true } },
  { 'n', '<Leader>D', vim.lsp.buf.type_definition, { silent = true, buffer = true } },
  { 'n', '<Leader>rn', vim.lsp.buf.rename, { silent = true, buffer = true } },
  { 'n', '<Leader>C', vim.lsp.buf.code_action, { silent = true, buffer = true } },
  { 'n', '<Leader>R', vim.lsp.buf.references, { silent = true, buffer = true } },
  { 'n', '<Leader>F', vim.lsp.buf.format, { silent = true, buffer = true } },
  { 'n', '<Leader>d', function()
    local virt_text = vim.diagnostic.config().virtual_text
    vim.diagnostic.config({
      virtual_text = not virt_text,
      virtual_lines = virt_text,
    })
  end },
}

vim.api.nvim_create_augroup('LspMappings', { clear = true })
vim.api.nvim_create_autocmd({ 'LspAttach', 'LspDetach' }, {
  group = 'LspMappings',
  pattern = '*',
  callback = function(args)
    if args.event == 'LspAttach' then
      for _, mapping in ipairs(lsp_mappings) do
        vim.keymap.set(unpack(mapping))
      end

      -- Show virtual lines by default.
      lsp_lines.setup()
      vim.diagnostic.config({
        virtual_text = false,
        virtual_lines = true,
      })
    else
      -- TODO: Unload lsp_lines as well.
      for _, mapping in ipairs(lsp_mappings) do
        vim.keymap.del(unpack(mapping))
      end
    end
  end
})

-- :h diagnostic-signs
vim.fn.sign_define('DiagnosticSignError', { text = '', texthl = 'DiagnosticSignError' })
vim.fn.sign_define('DiagnosticSignWarn', { text = '', texthl = 'DiagnosticSignWarn' })
vim.fn.sign_define('DiagnosticSignInfo', { text = '', texthl = 'DiagnosticSignInfo' })
vim.fn.sign_define('DiagnosticSignHint', { text = '󰞋', texthl = 'DiagnosticSignHint' })
