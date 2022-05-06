vim.g.do_filetype_lua = 1

local config = {
  filenames = {
    ['flake.lock'] = 'json',
    ['cargo.lock'] = 'toml'
  },
  extensions = {
    yuck = 'clojure'
  },
}

vim.filetype.add({
  filename = config.filenames,
  extension = config.extensions
})

-- Load these filetype mappings in Telescope
require('plenary.filetype').add_table({
  file_name = config.filenames,
  extension = config.extensions
})
