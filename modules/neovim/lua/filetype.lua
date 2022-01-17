-- Add/override filetype highlighting
local filetypes = {
  by_extension = {
    ['yuck'] = 'clojure',
    ['nix'] = 'nix',
  },
  by_filename = {
    ['flake.lock'] = 'json',
    ['cargo.lock'] = 'toml'
  }
}

-- Use `filetype-nvim` instead of built-in `filetype.vim` for ft detection
vim.g.did_load_filetypes = 1
require('filetype').setup({
  overrides = {
    extensions = filetypes.by_extension,
    literal = filetypes.by_filename
  }
})

-- Add filetypes to `plenary-nvim` for `telescope-nvim` previewers
require('plenary.filetype').add_table({
  extension = filetypes.by_extension,
  file_name = filetypes.by_filename
})
