-- :h gitsigns-config
require('gitsigns').setup({
  culhl = true, -- required for cursorline highlights.
  signs = {
    add = { text = '┃' },
    change = { text = '┃' },
    delete = { text = '┃' },
    topdelete = { text = '╏' },
    changedelete = { text = '┇' },
    untracked = { text = '┊' },
  },
})
