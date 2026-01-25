return {
  cmd = { 'emmylua_ls' },
  filetypes = { 'lua' },
  root_markers = {
    '.luacheckrc',
    '.luarc.json',
    '.emmyrc.json',
    '.git',
  },

  settings = {
    Lua = {
      runtime = {
        version = 'LuaJIT',
        requirePattern = {
          'lua/?.lua',
          'lua/?/init.lua',
        },
      },
      diagnostics = { globals = { 'vim' } },
      workspace = {
        library = vim.api.nvim_get_runtime_file('lua', true),
      },
      hint = {
        indexHint = false,
      },
    },
  },
}
