require('options')
require('filetype')
require('completion')
require('statusline')
require('lightspeed')

-- Sane window navigation
-- vim.api.nvim_buf_set_keymap('n', '<C-h', '<C-w>h', { expr = true, noremap = true })
-- vim.api.nvim_buf_set_keymap('n', '<C-j', '<C-w>j', { expr = true, noremap = true })
-- vim.api.nvim_buf_set_keymap('n', '<C-k', '<C-w>k', { expr = true, noremap = true })
-- vim.api.nvim_buf_set_keymap('n', '<C-l', '<C-w>l', { expr = true, noremap = true })

-- Delete word at cursor while in Insert mode
vim.api.nvim_set_keymap('i', '<C-d>', "<ESC>diwi", { silent = true, noremap = true })

require('gitsigns').setup()

local colours = require('kanagawa.colors').setup()
require('kanagawa').setup({
  overrides = {
    Whitespace = { fg = colours.sumiInk2 },
    NonText = { fg = colours.sumiInk2 },
    DiagnosticVirtualTextError = { fg = colours.samuraiRed, bg = colours.winterRed },
    DiagnosticVirtualTextWarn = { fg = colours.roninYellow, bg = colours.winterYellow },
    DiagnosticVirtualTextInfo = { fg = colours.waveAqua1, bg = colours.winterBlue },
    DiagnosticVirtualTextHint = { fg = colours.dragonBlue, bg = colours.winterBlue },
    -- TelescopeResultsNormal = { bg = colours.sumiInk0 },
    -- TelescopeResultsBorder = { bg = colours.sumiInk0 },
    -- TelescopeResultsTitle = { fg = colours.sumiInk0, bg = colours.fujiGray },
    -- TelescopePreviewNormal = { bg = colours.sumiInk0 },
    -- TelescopePreviewBorder = { bg = colours.sumiInk0 },
    -- TelescopePreviewTitle = { fg = colours.sumiInk0, bg = colours.fujiGray },
    -- TelescopePromptNormal = { bg = colours.sumiInk0 },
    -- TelescopePromptBorder = { bg = colours.sumiInk0 },
    -- TelescopePromptTitle = { fg = colours.sumiInk0, bg = colours.fujiGray },
  }
})
vim.cmd[[colorscheme kanagawa]]

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

require('nvim-treesitter.configs').setup({
  highlight = { enable = true },
  indent = { enable = true },
  incremental_selection = { enable = false },
  playground = { enable = true },
})

require('indent_blankline').setup({
  show_trailing_blankline_indent = false,
  use_treesitter = true,
  show_current_context = true,
  -- show_current_context_start = true,
  show_first_indent_level = true,
  char = '│',
  filetype_exclude = { 'TelescopePrompt' },
  buftype_exclude = { 'help', 'terminal', 'nofile' },
  context_patterns = {
    -- Common/C/C++
    'class', 'struct', 'function', 'method', '.*expression', '.*statement', 'for.*', '.*list',
    -- Nix
    'bind', '.*attrset', 'parenthesized',
    -- Lua
    'table', 'arguments'
  }
})
-- Fixes cursorline ghosting with indent-blankline on empty lines
vim.opt.colorcolumn = "9999999";

require('colorizer').setup({
    '*', 'nix', 'html', 'javascript',
    css = {
      css = true
    }
  }, { 
    mode = 'background',
    RGB = false,
    RRGGBB = true,
    RRGGBBAA = true,
    names = false,
    css = false
  }
)

