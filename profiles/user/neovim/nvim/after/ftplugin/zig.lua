local root_pattern = {
  '.git',
  'build.zig',
  'zls.json',
}

vim.lsp.start({
  name = 'zls',
  cmd = { 'zls' },
  root_dir = vim.fs.dirname(vim.fs.find(root_pattern, { upward = true })[1]),
})
