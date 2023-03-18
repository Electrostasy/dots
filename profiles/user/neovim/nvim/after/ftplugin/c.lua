local root_pattern = {
  'compile_commands.json',
  'compile_flags.txt',
  'configure.ac',
  '.git',
}

vim.lsp.start({
  name = 'clangd',
  cmd = { 'clangd' },
  root_dir = vim.fs.dirname(vim.fs.find(root_pattern, { upward = true })[1]),
})

-- TODO: Implement a source/header switch?
