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

vim.o.termguicolors = true
vim.o.background = 'dark'
vim.cmd.colorscheme('poimandres')

vim.g.mapleader = ' ' -- Set <Leader> for keymaps.
vim.o.showmode = false -- Don't show mode in command line.
vim.opt.shortmess:append('S') -- Hide search count from message area.
vim.o.ignorecase = true -- Ignore case of normal letters in patterns.
vim.o.smartcase = true -- Ignore case when pattern contains lowercase letters only.
vim.o.wrap = false
vim.o.splitbelow = true
vim.o.splitright = true
vim.o.statuscolumn = '%l %C%s'
vim.wo.number = true
vim.o.showbreak = '↳'
vim.o.list = true

-- Add a blinking cursor in certain modes.
vim.opt.guicursor = {
  'n-c-v:block-Cursor',
  'i-ci-v-ve-r-o:blinkwait250-blinkon250-blinkoff250-Cursor',
  'i-ci-ve:ver25-Cursor',
  'r-cr-o:hor20-Cursor'
}

-- https://github.com/neovim/neovim/issues/4396#issuecomment-1377191592
vim.api.nvim_create_autocmd('VimLeave', {
  group = vim.api.nvim_create_augroup('RestoreCursor', { }),
  desc = 'Restore cursor for VTE based (and some other) terminal emulators',
  pattern = '*',
  callback = function()
    vim.opt.guicursor = {}
    vim.api.nvim_chan_send(vim.v.stderr, '\x1b[ q')
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

vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('Treesitter', { }),
  desc = 'Enable treesitter for supported filetypes',
  pattern = '*',
  callback = function(event)
    if #vim.api.nvim_get_runtime_file(('parser/%s.so'):format(event.match), false) == 0 then
      return
    end

    vim.treesitter.start(event.buf, event.match)

    if vim.treesitter.query.get(event.match, 'folds') then
      vim.wo.foldmethod = 'expr'
      vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
      vim.wo.foldlevel = 99
      vim.wo.foldtext = ''
      vim.opt_local.fillchars:append({ fold = ' ' })
    end

    -- Enable treesitter based parameter highlighting.
    require('hlargs').setup()
  end,
})

vim.api.nvim_create_autocmd({ 'BufEnter', 'WinLeave' }, {
  group = vim.api.nvim_create_augroup('ActiveBufferCursorline', { }),
  desc = 'Highlight line containing cursor only on active buffer',
  pattern = '*',
  callback = function(args)
    vim.wo.cursorline = args.event == 'BufEnter'
  end
})

vim.api.nvim_create_autocmd('TextYankPost', {
  group = vim.api.nvim_create_augroup('HighlightOnYank', { }),
  desc = 'Highlight yanked region',
  pattern = '*',
  callback = function()
    vim.highlight.on_yank({ timeout = 250 })
  end,
})

local ignored_buftypes = { 'quickfix', 'nofile', 'help' }
local ignored_filetypes = { 'gitcommit', 'gitrebase', 'svn', 'hgcommit' }
vim.api.nvim_create_autocmd({ 'FileType', 'BufReadPost' }, {
  desc = 'Restore cursor to last known position',
  group = vim.api.nvim_create_augroup('RestoreCursorPosition', { }),
  callback = function(event)
    if vim.tbl_contains(ignored_buftypes, vim.bo.buftype) or vim.tbl_contains(ignored_filetypes, vim.bo.filetype) then
      return
    end

    local position = vim.api.nvim_buf_get_mark(event.buf, [["]])
    local win = vim.fn.bufwinid(event.buf)

    if
      position ~= { 0, 0 } and
      position[1] < vim.api.nvim_buf_line_count(event.buf) and
      win ~= -1
    then
      vim.api.nvim_win_set_cursor(win, position)
      vim.api.nvim_feedkeys('zz', 'nx', true)
    end
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

vim.keymap.set('v', '<Space>', require('ts_select').expand)
vim.keymap.set('v', '<C-Space>', require('ts_select').contract)

vim.keymap.set({ 'n', 'v' }, 'gs', require('ts_sort').sort_nodes_on_cursor)
