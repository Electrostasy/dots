vim.lsp.start({
  name = 'basedpyright-langserver',
  cmd = { 'basedpyright-langserver', '--stdio' },
  root_dir = vim.fs.root(0, {
    'pyproject.toml',
    'setup.py',
    'setup.cfg',
    'requirements.txt'
  }),

  settings = {
    basedpyright = {
      analysis = {
        autoSearchPaths = true,
        diagnosticMode = 'openFilesOnly',
        useLibraryCodeForTypes = true,
      },
    },
  },
})
