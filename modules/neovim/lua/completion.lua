local icons = {
  Text = "",
  Method = "",
  Function = "",
  Constructor = "",
  Field = "ﰠ",
  Variable = "",
  Class = "ﴯ",
  Interface = "",
  Module = "",
  Property = "ﰠ",
  Unit = "塞",
  Value = "",
  Enum = "",
  Keyword = "",
  Snippet = "",
  Color = "",
  File = "",
  Reference = "",
  Folder = "",
  EnumMember = "",
  Constant = "",
  Struct = "פּ",
  Event = "",
  Operator = "",
  TypeParameter = "⌬"
}

-- Highlight line number instead of having icons in sign columns
vim.fn.sign_define("LspDiagnosticsSignError", { text = "", numhl = "LspDiagnosticsSignError" })
vim.fn.sign_define("LspDiagnosticsSignWarning", { text = "", numhl = "LspDiagnosticsSignWarning" })
vim.fn.sign_define("LspDiagnosticsSignInformation", { text = "", numhl = "LspDiagnosticsSignInformation" })
vim.fn.sign_define("LspDiagnosticsSignHint", { text = "", numhl = "LspDiagnosticsSignHint" })

-- Set up nvim-cmp completion menu
local cmp = require('cmp')

cmp.setup({
  snippet = {
    expand = function(args)
      require('luasnip').lsp_expand(args.body)
    end
  },
  mapping = {
    ['<C-d>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-e>'] = cmp.mapping.close(),
    ['<CR>'] = cmp.mapping.confirm({
      behavior = cmp.ConfirmBehavior.Insert,
      select = true
    }),
  },
  sources = {
    { name = 'nvim_lsp' },
    { name = 'buffer' },
    { name = 'path' },
    { name = 'luasnip'},
  },
  formatting = {
    format = require('lspkind').cmp_format({
      with_text = true,
      symbol_map = icons,
      menu = {
        buffer = '[Buffer]',
        nvim_lsp = '[LSP]',
        luasnip = '[Snippet]',
        path = '[Path]'
      }
    }),
  },
  sorting = {
    comparators = {
      cmp.config.compare.offset,
      cmp.config.compare.exact,
      cmp.config.compare.score,
      require('cmp-under-comparator').under,
      cmp.config.compare.kind,
      cmp.config.compare.sort_text,
      cmp.config.compare.length,
      cmp.config.compare.order
    }
  },
  experimental = {
    native_menu = false,
    ghost_text = true
  }
})

cmp.setup.cmdline('/', {
  sources = cmp.config.sources({
    { name = 'buffer' }
  })
})

cmp.setup.cmdline(':', {
  sources = cmp.config.sources({
    { name = 'path' },
    { name = 'cmdline' }
  })
})

vim.opt.completeopt = 'menu,menuone,noselect'

local lsp_capabilities = vim.lsp.protocol.make_client_capabilities()
local completion_capabilities = require('cmp_nvim_lsp').update_capabilities(lsp_capabilities)

-- Set up LSP configurations
local lspconfig = require('lspconfig')
local shared_config = {
  capabilities = completion_capabilities,
  on_attach = (function(_, buffer_num)
    -- Keymap
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

    -- LSP UI customization
    for i, kind in ipairs(vim.lsp.protocol.CompletionItemKind) do
      vim.lsp.protocol.CompletionItemKind[i] = icons[kind] or kind
    end
  end),
  flags = {
    debounce_text_changes = 500,
  },
}

local servers = { 'sumneko_lua', 'rnix', 'ccls', 'texlab', 'bashls' }
-- Apply server configuration from the ./lsp/ directory, if it exists
for _, server in ipairs(servers) do
  local ok, module = pcall(require, 'lsp.'..server)
  if not ok then
    module = nil
  end
  if module then
    lspconfig[server].setup(vim.tbl_deep_extend('force', module, shared_config))
  else
    lspconfig[server].setup(shared_config)
  end
end

-- Show LSP diagnostics in virtual lines
require('lsp_lines').register_lsp_virtual_lines()
vim.diagnostic.config({
  virtual_lines = true,
  virtual_text = false,
  prefix = ' ▾',
  signs = true,
  underline = true,
  update_in_insert = false
})

