require('nvim-highlight-colors').setup({
  render = 'virtual',
  virtual_symbol = '▾',
  enable_named_colors = false,

  exclude_filetypes = { 'devicetree' },
  exclude_buftypes = { 'devicetree' },
})
