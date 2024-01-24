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
  'n-c-v:block-Cursor',
  'i-ci-ve-r-o:blinkwait250-blinkon250-blinkoff250-Cursor',
  'i-ci-ve:ver25-Cursor',
  'r-cr-o:hor20-Cursor'
}

vim.opt.termguicolors = true
vim.opt.background = 'dark'
vim.cmd.colorscheme('poimandres')

-- We do not need to exhaustively specify all the fields.
---@diagnostic disable-next-line: missing-fields
require('nvim-treesitter.configs').setup({
  highlight = { enable = true },
  indent = { enable = true },
  incremental_selection = {
    enable = true,
    keymaps = {
      init_selection = '<C-Space>',
      node_incremental = '<Space>',
      node_decremental = '<C-Space>',
      scope_incremental = nil,
    },
  },

  -- Available under plugins/showpairs.lua.
  showpairs = { enable = true },
})

-- TODO: Signs in the signcolumn ignore cursorline background.
-- :h gitsigns-config
require('gitsigns').setup({
  signs = {
    add = { text = '┃' },
    change = { text = '┃' },
    delete = { text = '┃' },
    topdelete = { text = '╏' },
    changedelete = { text = '┇' },
    untracked = { text = '┊' },
  },
})

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
vim.api.nvim_create_augroup('ActiveBufferCursorline', { clear = true })
vim.api.nvim_create_autocmd({ 'BufEnter', 'WinLeave' }, {
  group = 'ActiveBufferCursorline',
  pattern = '*',
  callback = function(args)
    vim.opt_local.cursorline = args.event == 'BufEnter'
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

-- Set relativenumber when entering visual/select line/block modes, and unset
-- it when leaving them, allowing for easier range-based selections and movements.
vim.api.nvim_create_augroup('DynamicRelativeNumber', { clear = true })
vim.api.nvim_create_autocmd('ModeChanged', {
  group = 'DynamicRelativeNumber',
  pattern = '*',
  callback = function(args)
    vim.opt_local.relativenumber = vim.tbl_contains({ 'n:V', 'n:\22', 'n:s', 'n:\19' }, args.match)
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
vim.keymap.set('n', '<C-h>', '<C-w>h')
vim.keymap.set('n', '<C-j>', '<C-w>j')
vim.keymap.set('n', '<C-k>', '<C-w>k')
vim.keymap.set('n', '<C-l>', '<C-w>l')
vim.keymap.set('n', '<C-Left>', '<C-w>h')
vim.keymap.set('n', '<C-Up>', '<C-w>j')
vim.keymap.set('n', '<C-Down>', '<C-w>j')
vim.keymap.set('n', '<C-Right>', '<C-w>l')

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
    if vim.tbl_contains({ 'quickfix', 'prompt' }, args.match) then
      return
    end

    if args.event == 'InsertEnter' then
      vim.opt_local.listchars = insert_listchars
    else
      vim.opt_local.listchars = normal_listchars
    end

    require('ibl').debounced_refresh(0)
  end
})

-- https://github.com/nvim-telescope/telescope.nvim/pull/2529
vim.filetype.add({
  filename = {
    ['flake.lock'] = 'json',
  },
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

-- Parameter highlighting.
local hlargs = require('hlargs')
hlargs.setup()

vim.api.nvim_create_augroup('LspMappings', { clear = true })
vim.api.nvim_create_autocmd({ 'LspAttach', 'LspDetach' }, {
  group = 'LspMappings',
  pattern = '*',
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    local capabilities = client.server_capabilities
    local hasSemanticTokens = capabilities.semanticTokensProvider and capabilities.semanticTokensProvider.full

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

      -- If LSP supports semantic tokens, disable Hlargs for the current buffer.
      -- :h hlargs-lsp
      if hasSemanticTokens then
        hlargs.disable_buf(args.buf)
      end
    else
      for _, mapping in ipairs(lsp_mappings) do
        vim.keymap.del(unpack(mapping))
      end

      -- If LSP supports semantic tokens, enable Hlargs for the current buffer.
      -- :h hlargs-lsp
      if hasSemanticTokens then
        hlargs.enable_buf(args.buf)
      end
    end
  end
})

-- :h diagnostic-signs
vim.fn.sign_define('DiagnosticSignError', { text = '', texthl = 'DiagnosticSignError' })
vim.fn.sign_define('DiagnosticSignWarn', { text = '', texthl = 'DiagnosticSignWarn' })
vim.fn.sign_define('DiagnosticSignInfo', { text = '', texthl = 'DiagnosticSignInfo' })
vim.fn.sign_define('DiagnosticSignHint', { text = '󰞋', texthl = 'DiagnosticSignHint' })
