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

vim.opt.termguicolors = true
vim.opt.background = 'dark'
vim.cmd.colorscheme('poimandres')

vim.g.mapleader = ' ' -- Set <Leader> for keymaps.
vim.opt.showmode = false -- Don't show mode in command line.
vim.opt.shortmess:append('S') -- Hide search count from message area.
vim.opt.ignorecase = true -- Ignore case of normal letters in patterns.
vim.opt.smartcase = true -- Ignore case when pattern contains lowercase letters only.
vim.opt.wrap = false
vim.opt.splitbelow = true
vim.opt.splitright = true

-- Add a blinking cursor in certain modes.
vim.opt.guicursor = {
  'n-c-v:block-Cursor',
  'i-ci-v-ve-r-o:blinkwait250-blinkon250-blinkoff250-Cursor',
  'i-ci-ve:ver25-Cursor',
  'r-cr-o:hor20-Cursor'
}

-- Restore cursor for VTE based (and some other) terminal emulators:
-- https://github.com/neovim/neovim/issues/4396#issuecomment-1377191592
vim.api.nvim_create_autocmd('VimLeave', {
  group = vim.api.nvim_create_augroup('RestoreCursor', { }),
  pattern = '*',
  callback = function()
    vim.opt.guicursor = {}
    vim.fn.chansend(vim.v.stderr, '\x1b[ q')
  end
})

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

do
  -- Visible outside of Insert mode.
  local normal_listchars = {
    extends = '»',
    precedes = '«',
    tab = '  ',
    trail = '∙',
  }

  -- Visible only in Insert mode.
  local insert_listchars = {
    eol = '¶',
    lead = '·',
    nbsp = '¤',
    space = '·',
    tab = '··',
  }

  vim.opt.showbreak = '↳'
  vim.opt.list = true
  vim.opt.listchars = normal_listchars

  vim.api.nvim_create_autocmd({ 'InsertEnter', 'InsertLeavePre' }, {
    group = vim.api.nvim_create_augroup('InsertModeListChars', { }),
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

      -- Execute `OptionSet` autocmds manually, instead of running this nested.
      vim.api.nvim_exec_autocmds('OptionSet', {
        group = 'IndentBlankline',
        pattern = 'listchars',
      })
    end
  })
end

-- Enable treesitter highlighting for supported filetypes.
vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('TreesitterHighlight', { }),
  pattern = '*',
  callback = function(event)
    if vim.treesitter.query.get(event.match, 'highlights') then
      vim.treesitter.start(event.buf, event.match)
    end
  end,
})

-- Highlight line containing cursor only on active buffer.
vim.api.nvim_create_autocmd({ 'BufEnter', 'WinLeave' }, {
  group = vim.api.nvim_create_augroup('ActiveBufferCursorline', { }),
  pattern = '*',
  callback = function(args)
    vim.opt_local.cursorline = args.event == 'BufEnter'
  end
})

-- Highlight yanked region.
vim.api.nvim_create_autocmd('TextYankPost', {
  group = vim.api.nvim_create_augroup('HighlightOnYank', { }),
  pattern = '*',
  callback = function()
    vim.highlight.on_yank({ timeout = 250 })
  end,
})

-- Set relativenumber when entering visual/select line/block modes, and unset
-- it when leaving them, allowing for easier range-based selections and movements.
vim.opt.number = true
vim.api.nvim_create_autocmd('ModeChanged', {
  group = vim.api.nvim_create_augroup('DynamicRelativeNumber', { }),
  pattern = '*',
  callback = function(args)
    vim.opt_local.relativenumber = vim.tbl_contains({ 'n:V', 'n:\22', 'n:s', 'n:\19' }, args.match)
  end,
})

vim.keymap.set('n', '<C-h>', '<C-w>h', { silent = true })
vim.keymap.set('n', '<C-j>', '<C-w>j', { silent = true })
vim.keymap.set('n', '<C-k>', '<C-w>k', { silent = true })
vim.keymap.set('n', '<C-l>', '<C-w>l', { silent = true })
vim.keymap.set('n', '<C-Left>', '<C-w>h', { silent = true })
vim.keymap.set('n', '<C-Up>', '<C-w>j', { silent = true })
vim.keymap.set('n', '<C-Down>', '<C-w>j', { silent = true })
vim.keymap.set('n', '<C-Right>', '<C-w>l', { silent = true })

local incremental_selection = require('incremental_selection')
vim.keymap.set('v', '<Space>', incremental_selection.expand)
vim.keymap.set('v', '<C-Space>', incremental_selection.contract)
