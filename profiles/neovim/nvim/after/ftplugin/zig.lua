vim.lsp.start({
  name = 'zls',
  cmd = { 'zls' },
  root_dir = vim.fs.root(0, {
    '.git',
    'build.zig',
    'zls.json',
  })
})
