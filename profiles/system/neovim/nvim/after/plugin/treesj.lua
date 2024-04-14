-- Override line join with treesitter-based line joining/splitting.

local trj = require('treesj')
trj.setup({ use_default_keymaps = false })

vim.keymap.set('n', 'J', trj.toggle, { silent = true })
