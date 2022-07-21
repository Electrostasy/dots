require('options')

require('plugins.colorscheme')
require('plugins.heirline')
require('plugins.cmp')
require('plugins.indent_blankline')
require('plugins.comment')
require('plugins.telescope')
require('plugins.treesitter')
require('plugins.null-ls')
require('plugins.lspconfig')

require('nvim-surround').setup({ delimiters = { HTML = false, aliases = false } })
require('gitsigns').setup()
require('nvim-web-devicons').setup()
require('colorizer').setup({ '*', 'nix', 'html', 'javascript', css = { css = true } })
