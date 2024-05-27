vim.lsp.start({
  name = 'jedi-language-server',
  cmd = { 'jedi-language-server' },
  root_dir = vim.fs.root(0, {
    'pyproject.toml',
    'setup.py',
    'setup.cfg',
    'requirements.txt'
  }),
})
