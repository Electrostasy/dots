local telescope_actions = require('telescope.actions')
require('telescope').setup({
  pickers = {
    defaults = {
      sorting_strategy = 'ascending',
    },
    buffers = {
      prompt_prefix = ' ',
      selection_caret = '▶ ',
      -- borderchars = {
      --   prompt = { "█", "", "C", "", "█", "█", "G", "H" },
      --   results = { "", "", "", "", "", "", "", "" },
      --   preview = { "─", "│", "─", "│", "╭", "╮", "╯", "┗" },
      -- },
      borderchars = {
        prompt = { '─', '', '', '', '─', '─', '', '' },
      },
      prompt_title = 'Buffers',
      theme = 'ivy',
      mappings = {
        i = {
          ["<C-d>"] = telescope_actions.delete_buffer
        }
      }
    },
    live_grep = {
      prompt_prefix = ' ',
      selection_caret = '▶',
      theme = 'ivy'
    },
  }
})

vim.api.nvim_set_keymap('n', '<leader>b', "<cmd>lua require('telescope.builtin').buffers()<cr>", { silent = true, noremap = true })
vim.api.nvim_set_keymap('n', '<leader>e', "<cmd>lua require('telescope.builtin').find_files()<cr>", { silent = true, noremap = true })
vim.api.nvim_set_keymap('n', '<leader>g', "<cmd>lua require('telescope.builtin').live_grep()<cr>", { silent = true, noremap = true })
vim.api.nvim_set_keymap('n', '<leader>G', "<cmd>lua require('telescope.builtin').current_buffer_fuzzy_find()<cr>", { silent = true, noremap = true })
vim.api.nvim_set_keymap('n', '<leader>R', "<cmd>lua require('telescope.builtin').lsp_references()<cr>", { silent = true, noremap = true })
vim.api.nvim_set_keymap('n', '<leader>D', "<cmd>lua require('telescope.builtin').lsp_definitions()<cr>", { silent = true, noremap = true })
vim.api.nvim_set_keymap('n', '<leader>TD', "<cmd>lua require('telescope.builtin').lsp_type_definitions()<cr>", { silent = true, noremap = true })
vim.api.nvim_set_keymap('n', '<leader>I', "<cmd>lua require('telescope.builtin').lsp_implementations()<cr>", { silent = true, noremap = true })
vim.api.nvim_set_keymap('n', '<leader>CA', "<cmd>lua require('telescope.builtin').lsp_code_actions()<cr>", { silent = true, noremap = true })
vim.api.nvim_set_keymap('n', '<leader>DS', "<cmd>lua require('telescope.builtin').lsp_document_symbols()<cr>", { silent = true, noremap = true })
vim.api.nvim_set_keymap('n', '<leader>WS', "<cmd>lua require('telescope.builtin').lsp_workspace_symbols()<cr>", { silent = true, noremap = true })
