local telescope_actions = require('telescope.actions')
require('telescope').setup({
  defaults = {
    layout_config = {
      prompt_position = 'top'
    },
    sorting_strategy = 'ascending',
    prompt_prefix = ' ',
    dynamic_preview_title = true,
    selection_caret = '▶ ',
  },
  pickers = {
    buffers = {
      -- borderchars = {
      --   prompt = { "█", "", "C", "", "█", "█", "G", "H" },
      --   results = { "", "", "", "", "", "", "", "" },
      --   preview = { "─", "│", "─", "│", "╭", "╮", "╯", "┗" },
      -- },
      mappings = {
        i = {
          ["<C-d>"] = telescope_actions.delete_buffer,
        }
      },
      preview = {
        filetype_hook = function(filepath, bufnr, opts)
          local excluded = vim.tbl_filter(function(extension)
            return filepath:match(extension)
          end, { ".*%.png" })
          if not vim.tbl_isempty(excluded) then
            require("telescope.previewers.utils").set_preview_message(
              bufnr, opts.winid, string.format("I don't like %s files!", excluded[1]:sub(5, -1))
            )
            return false
          end
          return true
        end
      },
    },
  }
})

vim.api.nvim_set_keymap('n', '<leader>b', "<cmd>lua require('telescope.builtin').buffers({ ignore_current_buffer = true })<cr>", { silent = true, noremap = true })
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
