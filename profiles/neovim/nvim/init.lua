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

  vim.o.showbreak = '↳'
  vim.o.list = true
  vim.opt.listchars = normal_listchars

  vim.api.nvim_create_autocmd({ 'InsertEnter', 'InsertLeavePre' }, {
    group = vim.api.nvim_create_augroup('InsertModeListChars', { }),
    desc = 'Show full listchars only in Insert mode',
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

      -- Execute `OptionSet` autocmds manually instead of running this nested.
      vim.api.nvim_exec_autocmds('OptionSet', {
        group = 'IndentBlankline',
        pattern = 'listchars',
      })
    end
  })
end

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

-- We cannot use only ModeChanged, as that will conflict with blink.cmp's
-- completion window by shifting it to the left whenever the completion items
-- are scrolled. Adapted from the example provided at `:h ModeChanged`.
vim.wo.number = true
vim.api.nvim_create_autocmd({ 'ModeChanged', 'WinEnter', 'WinLeave' }, {
  group = vim.api.nvim_create_augroup('DynamicRelativeNumber', { }),
  desc = 'Set relativenumber when entering visual/select line/block modes',
  pattern = { '[vV\x16]*:*', '*:[vV\x16]*' },
  callback = function()
    vim.wo.relativenumber = vim.api.nvim_get_mode().mode:find('[vV\22]') and true or false
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
