local telescope = require('telescope')
local actions = require('telescope.actions')
local builtin = require('telescope.builtin')

local config = {
  defaults = {
    layout_config = { prompt_position = 'top' },
    sorting_strategy = 'ascending',
    prompt_prefix = ' ',
    dynamic_preview_title = true,
    selection_caret = '▶ ',
    borderchars = {
      prompt = { '', '', '', '', '', '', '', '' },
      results = { '', '', '', '', '', '', '', '' },
      preview = { '─', '│', '─', '│', '┌', '┐', '┘', '└' },
    },
    -- borderchars = { preview = { '┌', '┐', '', '│', '└', '┘' } },
  },
  pickers = {
    buffers = {
      mappings = {
        i = {
          ['<C-d>'] = actions.delete_buffer,
          ['<C-leader>'] = actions.add_selection
        }
      }
    }
  },
  extensions = {
    fzf = {
      fuzzy = true,
      override_generic_sorter = true,
      override_file_sorter = true,
      case_mode = 'smart_case',
    },
  }
}

telescope.setup(config)
telescope.load_extension('fzf')

vim.keymap.set('n', '<leader>b', builtin.buffers, { silent = true })
vim.keymap.set('n', '<leader>e', function()
  local ret = os.execute('git rev-parse --is-inside-work-tree')
  if ret == 0 then
    builtin.git_files()
  else
    builtin.find_files()
  end
end, { silent = true })
vim.keymap.set('n', '<leader>g', builtin.live_grep, { silent = true })
vim.keymap.set('n', '<leader>r', builtin.lsp_references, { silent = true })
vim.keymap.set('n', '<leader>d', builtin.lsp_definitions, { silent = true })
vim.keymap.set('n', '<leader>D', builtin.lsp_type_definitions, { silent = true })
vim.keymap.set('n', '<leader>i', builtin.lsp_implementations, { silent = true })

local telescope_group = vim.api.nvim_create_augroup('TelescopeNoCursorline', { clear = true })
vim.api.nvim_create_autocmd('FileType', {
  group = telescope_group,
  pattern = { 'TelescopePrompt', 'TelescopeResults' },
  callback = function()
    vim.opt.cursorline = false
  end
})
