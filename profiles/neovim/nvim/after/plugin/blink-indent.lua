-- :h blink-indent-config
require('blink.indent').setup({
  mappings = {
    object_scope = '',
    object_scope_with_border = '',
    goto_top = '',
    goto_bottom = '',
  },
  static = {
    char = '▏',
    highlights = { 'BlinkIndent' },
  },
  scope = {
    char = '▏',
    highlights = { 'BlinkIndentScope' },
  },
})
