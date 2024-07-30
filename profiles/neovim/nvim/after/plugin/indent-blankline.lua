local ibl = require('ibl')

-- :h ibl.config
local config = {
  indent = { char = '▏' },
  scope = {
    show_start = false,
    show_end = false
  },
}

ibl.setup(config)

-- When changing colorschemes, the highlight groups used by ibl are not updated.
vim.api.nvim_create_autocmd('ColorScheme', {
  group = vim.api.nvim_create_augroup('IblUpdateGroups', { }),
  pattern = '*',
  callback = function()
    ibl.update({})
  end
})
