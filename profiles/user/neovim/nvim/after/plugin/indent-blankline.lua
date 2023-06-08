require('indent_blankline').setup({
  show_trailing_blankline_indent = false,
  -- use_treesitter = true,
  show_current_context = true,
  show_first_indent_level = true,
  context_patterns = {
    'struct', '.*expression', '.*statement',
  }
})
