local completion_capabilities = require('cmp_nvim_lsp').default_capabilities()

local icons = {
  Text = '',
  Method = '',
  Function = '',
  Constructor = '',
  Field = 'ﰠ',
  Variable = '',
  Class = 'ﴯ',
  Interface = '',
  Module = '',
  Property = 'ﰠ',
  Unit = '塞',
  Value = '',
  Enum = '',
  Keyword = '',
  Snippet = '',
  Color = '',
  File = '',
  Reference = '',
  Folder = '',
  EnumMember = '',
  Constant = '',
  Struct = 'פּ',
  Event = '',
  Operator = '',
  TypeParameter = '⌬'
}

local common = {
  capabilities = completion_capabilities,
  on_attach = function(_, _)
    local map = vim.keymap.set
    local lsp = vim.lsp.buf
    local opts = { silent = true }

    map('n', 'gD', lsp.declaration, opts)
    map('n', 'gd', lsp.definition, opts)
    map('n', 'K', lsp.hover, opts)
    map('n', 'gi', lsp.implementation, opts)
    map('n', '<C-k>', lsp.signature_help, opts)
    map('n', '<Leader>D', lsp.type_definition, opts)
    map('n', '<Leader>rn', lsp.rename, opts)
    map('n', '<Leader>C', lsp.code_action, opts)
    map('n', '<Leader>R', lsp.references, opts)
    map('n', '<Leader>F', lsp.formatting, opts)

    for i, kind in ipairs(vim.lsp.protocol.CompletionItemKind) do
      vim.lsp.protocol.CompletionItemKind[i] = icons[kind] or kind
    end
  end,
  flags = { debounce_text_changes = 500 },
}

local servers = {
  ccls = {
    init_options = {
      -- For build directories containing a compile_commands.json for the
      -- commands executed to compile a compilation unit.
      compilationDatabaseDirectory = './out/',
      filetypes = { 'c', 'cpp', 'cxx', 'cppm', 'cxxm', 'h', 'hpp', 'hxx' }
    },
  },
  pyright = {},
  nil_ls = {},
  sumneko_lua = function()
    local runtime_path = vim.split(package.path, ';')
    table.insert(runtime_path, 'lua/?.lua')
    table.insert(runtime_path, 'lua/?/init.lua')

    return {
      settings = {
        Lua = {
          runtime = {
            version = 'LuaJIT',
            path = runtime_path,
          },
          diagnostics = { globals = { 'vim' } },
          workspace = {
            library = vim.api.nvim_get_runtime_file('', true),
            checkThirdParty = false,
          },
        },
      },
    }
  end,
  rust_analyzer = {},
}

local lspconfig = require('lspconfig')
for server, config in pairs(servers) do
  if type(config) == 'function' then
    config = config()
  end
  lspconfig[server].setup(vim.tbl_deep_extend('force', config, common))
end

-- Show diagnostics as a tree in virtual lines
require('lsp_lines').setup()

vim.diagnostic.config({
  virtual_text = false,
  signs = true,
  underline = true,
  update_in_insert = true,
  severity_sort = true
})

-- Highlight line number instead of having icons in sign columns
vim.fn.sign_define('DiagnosticSignError', { text = '', numhl = 'DiagnosticSignError' })
vim.fn.sign_define('DiagnosticSignWarning', { text = '', numhl = 'DiagnosticSignWarning' })
vim.fn.sign_define('DiagnosticSignInformation', { text = '', numhl = 'DiagnosticSignInformation' })
vim.fn.sign_define('DiagnosticSignHint', { text = '', numhl = 'DiagnosticSignHint' })
