local ok, null_ls = pcall(require, 'null-ls')
if not ok then
  return
end

local formatting = null_ls.builtins.formatting
local diagnostics = null_ls.builtins.diagnostics

null_ls.setup({
  debug = false,
  sources = {
    formatting.nixfmt,
    formatting.stylua,
    formatting.black,
    formatting.clang_format,
    diagnostics.statix,
    diagnostics.luacheck.with({ extra_args = { '--globals', 'vim' } }),
    diagnostics.flake8,
    diagnostics.cppcheck
  }
})
