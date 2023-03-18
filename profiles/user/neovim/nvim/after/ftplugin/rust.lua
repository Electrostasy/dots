local root_pattern = {
  'Cargo.toml',
  'rust-project.json'
}

vim.lsp.start({
  name = 'rust-analyzer',
  cmd = { 'rust-analyzer' },
  root_dir = vim.fs.dirname(vim.fs.find(root_pattern, { upward = true })[1]),
})

-- TODO: Cargo workspaces?
