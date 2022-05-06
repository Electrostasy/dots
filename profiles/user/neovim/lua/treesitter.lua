require('nvim-treesitter.configs').setup({
  highlight = { enable = true },
  indent = { enable = true },
  incremental_selection = { enable = false },
  playground = { enable = true },
})

require('hlargs').setup({})

local hlargs_group = vim.api.nvim_create_augroup('HlargsHighlight', { clear = true })
vim.api.nvim_create_autocmd('ColorScheme', {
  group = hlargs_group,
  pattern = '*',
  callback = function()
    vim.api.nvim_set_hl(0, 'Hlargs', { link = 'TSParameter' })
  end
})
