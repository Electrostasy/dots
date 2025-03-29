local path = vim.split(package.path, ';')
table.insert(path, 'lua/?.lua')
table.insert(path, 'lua/?/init.lua')

return {
  cmd = { 'lua-language-server' },
  filetypes = { 'lua' },
  root_markers = {
    '.luacheckrc',
    '.luarc.json',
    '.luarc.jsonc',
    '.stylua.toml',
    'selene.toml',
    'selene.yml',
    'stylua.toml',
    '.git',
  },

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
}
