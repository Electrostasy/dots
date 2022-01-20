require('lsp.null_ls')

local icons = require('lsp.icons')
local lsp_capabilities = vim.lsp.protocol.make_client_capabilities()
local completion_capabilities = require('cmp_nvim_lsp').update_capabilities(lsp_capabilities)

-- Set up LSP configurations
local shared_config = {
  capabilities = completion_capabilities,
  on_attach = (function(_, buffer_num)
    local function map(...) vim.api.nvim_buf_set_keymap(buffer_num, ...) end
    local map_opts = { noremap = true, silent = true }
    map('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<CR>', map_opts)
    map('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>', map_opts)
    map('n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>', map_opts)
    map('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', map_opts)
    map('n', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', map_opts)
    map('n', '<Space>D', '<cmd>lua vim.lsp.buf.type_definition()<CR>', map_opts)
    map('n', '<Space>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', map_opts)
    map('n', '<Space>ca', '<cmd>lua vim.lsp.buf.code_action()<CR>', map_opts)
    map('n', '<Space>R', '<cmd>lua vim.lsp.buf.references()<CR>', map_opts)
    map('n', '<Space>f', '<cmd>lua vim.lsp.buf.formatting()<CR>', map_opts)

    for i, kind in ipairs(vim.lsp.protocol.CompletionItemKind) do
      vim.lsp.protocol.CompletionItemKind[i] = icons[kind] or kind
    end
  end),
  flags = {
    debounce_text_changes = 500,
  },
}

local lspconfig = require('lspconfig')
local servers = { 'sumneko_lua', 'rnix', 'ccls', 'texlab', 'bashls', 'pyright' }

-- Apply server-specific config from lsp dir
for _, server in ipairs(servers) do
  local ok, module = pcall(require, 'lsp.servers.' .. server)
  if not ok then
    module = {}
  end
  lspconfig[server].setup(vim.tbl_deep_extend('force', module, shared_config))
end

-- Show LSP diagnostics in virtual lines
require('lsp_lines').register_lsp_virtual_lines()
vim.diagnostic.config({
  virtual_lines = true,
  virtual_text = false,
  signs = true,
  underline = true,
  update_in_insert = false,
  severity_sort = true
})

-- Highlight line number instead of having icons in sign columns
vim.fn.sign_define("DiagnosticSignError", { text = "", numhl = "DiagnosticSignError" })
vim.fn.sign_define("DiagnosticSignWarning", { text = "", numhl = "DiagnosticSignWarning" })
vim.fn.sign_define("DiagnosticSignInformation", { text = "", numhl = "DiagnosticSignInformation" })
vim.fn.sign_define("DiagnosticSignHint", { text = "", numhl = "DiagnosticSignHint" })

