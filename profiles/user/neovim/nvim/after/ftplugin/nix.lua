vim.lsp.start({
  name = 'nil',
  cmd = { 'nil' },
  root_dir = vim.fs.dirname(vim.fs.find({ 'flake.nix', '.git' }, { upward = true })[1]),
})
