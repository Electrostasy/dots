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
  'i-ci-v-ve-r-o:blinkwait250-blinkon250-blinkoff250-Cursor',
  'i-ci-ve:ver25-Cursor',
  'r-cr-o:hor20-Cursor'
}

-- Restore cursor for VTE based (and some other) terminal emulators:
-- https://github.com/neovim/neovim/issues/4396#issuecomment-1377191592
vim.api.nvim_create_augroup('RestoreGuicursor', { clear = true })
vim.api.nvim_create_autocmd('VimLeave', {
  group = 'RestoreGuicursor',
  pattern = '*',
  callback = function()
    vim.opt.guicursor = {}
    vim.fn.chansend(vim.v.stderr, '\x1b[ q')
  end
})

vim.opt.termguicolors = true
vim.opt.background = 'dark'
vim.cmd.colorscheme('poimandres')

-- We do not need to exhaustively specify all the fields.
---@diagnostic disable-next-line: missing-fields
require('nvim-treesitter.configs').setup({
  highlight = { enable = true },
  indent = { enable = true },
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
vim.opt.inccommand = 'nosplit' -- Live preview for supporting commands.
vim.opt.ignorecase = true
vim.opt.smartcase = true

vim.opt.autoindent = true

vim.opt.wrap = false
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.keymap.set('n', '<C-h>', '<C-w>h', { silent = true })
vim.keymap.set('n', '<C-j>', '<C-w>j', { silent = true })
vim.keymap.set('n', '<C-k>', '<C-w>k', { silent = true })
vim.keymap.set('n', '<C-l>', '<C-w>l', { silent = true })
vim.keymap.set('n', '<C-Left>', '<C-w>h', { silent = true })
vim.keymap.set('n', '<C-Up>', '<C-w>j', { silent = true })
vim.keymap.set('n', '<C-Down>', '<C-w>j', { silent = true })
vim.keymap.set('n', '<C-Right>', '<C-w>l', { silent = true })

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
do
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

      vim.opt_local.listchars = args.event == 'InsertEnter' and insert_listchars or normal_listchars

      -- When we first enter Insert mode, the listchars in indentation are not
      -- visible until the cursor is first moved, unless we refresh ibl first.
      require('ibl').debounced_refresh(args.buf)
    end
  })
end

-- Parameter highlighting.
require('hlargs').setup()
