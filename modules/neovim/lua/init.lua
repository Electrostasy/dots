require('options')
require('filetype')

require('statusline')
require('picker')
require('completion')
require('lsp')

-- vim.api.nvim_buf_set_keymap('n', '<C-h', '<C-w>h', { expr = true, noremap = true })
-- vim.api.nvim_buf_set_keymap('n', '<C-j', '<C-w>j', { expr = true, noremap = true })
-- vim.api.nvim_buf_set_keymap('n', '<C-k', '<C-w>k', { expr = true, noremap = true })
-- vim.api.nvim_buf_set_keymap('n', '<C-l', '<C-w>l', { expr = true, noremap = true })

-- Delete word at cursor while in Insert mode
vim.api.nvim_set_keymap('i', '<C-d>', "<ESC>diwi", { silent = true, noremap = true })

require('gitsigns').setup({})
require('lightspeed').setup({})
require('hlargs').setup({})
vim.cmd[[highlight! link Hlargs TSParameter]]

local colours = require('kanagawa.colors').setup()
require('kanagawa').setup({
  overrides = {
    StatusLine = { bg = colours.sumiInk1 },
    StatusLineNC = { bg = colours.sumiInk1 },
    Whitespace = { fg = colours.sumiInk2 },
    NonText = { fg = colours.sumiInk2 },
    DiagnosticVirtualTextError = { fg = colours.samuraiRed, bg = colours.winterRed },
    DiagnosticVirtualTextWarn = { fg = colours.roninYellow, bg = colours.winterYellow },
    DiagnosticVirtualTextInfo = { fg = colours.waveAqua1, bg = colours.winterBlue },
    DiagnosticVirtualTextHint = { fg = colours.dragonBlue, bg = colours.winterBlue },
    TelescopeNormal = { fg = colours.fujiWhite, bg = colours.sumiInk0 },
    TelescopeBorder = { fg = colours.sumiInk4, bg = colours.sumiInk0 },
    TelescopePreviewNormal = { bg = colours.sumiInk1 },
    TelescopePreviewBorder = { fg = colours.sumiInk0, bg = colours.sumiInk0 },
    -- TelescopeResultsNormal = { bg = colours.sumiInk0 },
    -- TelescopeResultsBorder = { bg = colours.sumiInk0 },
    -- TelescopeResultsTitle = { fg = colours.sumiInk0, bg = colours.fujiGray },
    -- TelescopePreviewNormal = { bg = colours.sumiInk0 },
    -- TelescopePreviewBorder = { bg = colours.sumiInk0 },
    -- TelescopePreviewTitle = { fg = colours.sumiInk0, bg = colours.fujiGray },
    -- TelescopePromptNormal = { bg = colours.sumiInk0 },
    -- TelescopePromptBorder = { bg = colours.sumiInk0 },
    -- TelescopePromptTitle = { fg = colours.sumiInk0, bg = colours.fujiGray },
  }
})
vim.cmd[[colorscheme kanagawa]]

require('modes').setup({
  colors = {
    copy = colours.springGreen,
    delete = colours.waveRed,
    insert = colours.autumnYellow,
    visual = colours.springBlue
  },
  line_opacity = 0.1,
  set_cursor = true
})
require('nvim-web-devicons').setup({})

require('nvim-treesitter.configs').setup({
  highlight = { enable = true },
  indent = { enable = true, disable = { "python" } },
  incremental_selection = { enable = false },
  playground = { enable = true },
})

require('indent_blankline').setup({
  show_trailing_blankline_indent = false,
  use_treesitter = true,
  show_current_context = true,
  -- show_current_context_start = true,
  show_first_indent_level = true,
  char = '🭰',
  filetype_exclude = { },
  buftype_exclude = { 'help', 'terminal', 'nofile', 'prompt' },
  context_patterns = {
    -- Common/C/C++
    'class', 'struct', 'function', 'method', '.*expression', '.*statement', 'for.*', '.*list',
    -- Nix
    'bind', '.*attrset', 'parenthesized',
    -- Lua
    'table', 'arguments'
  }
})
-- Fixes cursorline ghosting with indent-blankline on empty lines
vim.opt.colorcolumn = "9999999";

require('colorizer').setup({
    '*', 'nix', 'html', 'javascript',
    css = {
      css = true
    }
  }, { 
    mode = 'background',
    RGB = false,
    RRGGBB = true,
    RRGGBBAA = true,
    names = false,
    css = false
  }
)

