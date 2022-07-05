require('options')
require('filetype')
require('colorscheme')
require('treesitter')
require('statusline')
require('picker')
require('completion')
require('lsp')

require('gitsigns').setup({})
require('lightspeed').setup({})
require('nvim-web-devicons').setup({})

require('indent_blankline').setup({
-- Plugin acts weird under WSL
  enabled = vim.env.WSL_INTEROP == nil and vim.env.WSL_DISTRO_NAME == nil,
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

