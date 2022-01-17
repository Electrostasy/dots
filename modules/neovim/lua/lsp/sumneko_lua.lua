local sumneko_bin = (function()
  for _, p in pairs(vim.split(vim.env.PATH, ":")) do
    if string.find(p, "lua-language-server", 1, true) ~= nil then return p end
  end
end)()
local sumneko_root = string.sub(sumneko_bin, 1, string.len(sumneko_bin) - 4)
local sumneko_executable = sumneko_bin.."/lua-language-server"
local sumneko_main = sumneko_root.."/share/lua-language-server/main.lua"

local runtime_path = vim.split(package.path, ';')
table.insert(runtime_path, "lua/?.lua")
table.insert(runtime_path, "lua/?/init.lua")

return {
  cmd = { sumneko_executable, "-E", sumneko_main },
  settings = {
    Lua = {
      runtime = {
        version = 'LuaJIT',
        path = runtime_path,
      },
      diagnostics = {
        globals = { 'vim' },
      },
      workspace = {
        library = vim.api.nvim_get_runtime_file("", true),
      },
      telemetry = {
        enable = false,
      },
    },
  },
}

