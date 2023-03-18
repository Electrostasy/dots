require('indent_blankline').setup({
  -- Plugin acts weird under WSL
  enabled = vim.env.WSL_INTEROP == nil and vim.env.WSL_DISTRO_NAME == nil,
  show_trailing_blankline_indent = false,
  -- use_treesitter = true,
  show_current_context = true,
  show_first_indent_level = true,
  context_patterns = {
    'struct', '.*expression', '.*statement',
  }
})
