require('options')
require('filetype')

require('statusline')
require('completion')
require('lsp')

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
  }
})
vim.cmd[[colorscheme kanagawa]]

require("fzf-lua").setup({})
vim.api.nvim_set_keymap("n", "<leader>b", "<cmd>lua require('fzf-lua').buffers()<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<leader>f", "<cmd>lua require('fzf-lua').files()<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<leader>g", "<cmd>lua require('fzf-lua').live_grep_native()<CR>", { noremap = true, silent = true })

require('nvim-web-devicons').setup({})

require('nvim-treesitter.configs').setup({
  highlight = { enable = true },
  indent = { enable = true },
  incremental_selection = { enable = false },
  playground = { enable = true },
})

require('indent_blankline').setup({
  show_trailing_blankline_indent = false,
  use_treesitter = true,
  show_current_context = true,
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

