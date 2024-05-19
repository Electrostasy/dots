local root_pattern = {
  '.luarc.json',
  '.luarc.jsonc',
  '.luacheckrc',
  '.stylua.toml',
  'stylua.toml',
  'selene.toml',
  'selene.yml',
  '.git'
}

local path = vim.split(package.path, ';')
table.insert(path, 'lua/?.lua')
table.insert(path, 'lua/?/init.lua')

vim.lsp.start({
  name = 'lua-language-server',
  cmd = { 'lua-language-server' },
  root_dir = vim.fs.dirname(vim.fs.find(root_pattern, { upward = true })[1]),

  settings = {
    Lua = {
      runtime = { version = 'LuaJIT', path = path },
      diagnostics = { globals = { 'vim' } },
      workspace = {
        library = vim.api.nvim_get_runtime_file('', true),
        checkThirdParty = false,
      },
      hint = {
        enable = true,
        arrayIndex = "Disable",
      },
    },
  },
})

vim.lsp.inlay_hint.enable()
