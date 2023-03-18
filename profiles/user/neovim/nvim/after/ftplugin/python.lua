local root_pattern = {
  'pyproject.toml',
  'setup.py',
  'setup.cfg',
  'requirements.txt'
}

vim.lsp.start({
  name = 'jedi-language-server',
  cmd = { 'jedi-language-server' },
  root_dir = vim.fs.dirname(vim.fs.find(root_pattern, { upward = true })[1]),
})
