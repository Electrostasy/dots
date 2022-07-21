require('nvim-treesitter.configs').setup({
  highlight = { enable = true },
  indent = { enable = true },
  incremental_selection = { enable = false },
  playground = { enable = true },
})

-- Highlight function arguments with nvim-treesitter
require('hlargs').setup({})
vim.api.nvim_create_autocmd('ColorScheme', {
  group = vim.api.nvim_create_augroup('HlargsHighlight', { clear = true }),
  pattern = '*',
  callback = function()
    vim.api.nvim_set_hl(0, 'Hlargs', { link = 'TSParameter' })
  end
})
