-- Disable built-in completion.
-- https://github.com/hrsh7th/nvim-cmp/discussions/941
vim.opt.complete = ''
vim.opt.completeopt = ''

-- Avoid depending on lspkind.nvim when this is all we use these icons for.
local kind_icons = {
  Text = '',
  Method = '',
  Function = '',
  Constructor = '',
  Field = '',
  Variable = '',
  Class = '',
  Interface = '',
  Module = '',
  Property = '',
  Unit = '',
  Value = '',
  Enum = '',
  Keyword = '',
  Snippet = '~',
  Color = '',
  File = '',
  Reference = '',
  Folder = '',
  EnumMember = '',
  Constant = '',
  Struct = '',
  Event = '',
  Operator = '',
  TypeParameter = '',
}

-- Generate highlight groups for completion item menu. Item kinds are dark
-- foreground and bright background, so the menu text uses the kind background.
for kind, _ in pairs(kind_icons) do
  local kind_group = vim.api.nvim_get_hl_by_name(('CmpItemKind%s'):format(kind), true)
  vim.api.nvim_set_hl(0, ('CmpItemMenu%s'):format(kind), {
    fg = kind_group.background
  })
end

local cmp = require('cmp')
local luasnip = require('luasnip')

local has_words_before = function()
  local line, col = unpack(vim.api.nvim_win_get_cursor(0))
  return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match('%s') == nil
end

cmp.setup({
  snippet = { expand = function(args) luasnip.lsp_expand(args.body) end },
  mapping = cmp.mapping.preset.insert({
    ['<Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      elseif luasnip.expand_or_jumpable() then
        luasnip.expand_or_jump()
      elseif has_words_before() then
        cmp.complete()
      else
        fallback()
      end
    end, { 'i', 's' }),
    ['<S-Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      elseif luasnip.jumpable(-1) then
        luasnip.jump(-1)
      else
        fallback()
      end
    end, { 'i', 's' }),
    ['<C-j>'] = cmp.mapping.scroll_docs(-1),
    ['<C-k>'] = cmp.mapping.scroll_docs(1),
    ['<C-e>'] = cmp.mapping.abort(),
    ['<CR>'] = cmp.mapping.confirm({ select = false }),
  }),
  sources = {
    { name = 'luasnip' },
    { name = 'nvim_lsp' },
    { name = 'path', option = { trailing_slash = true } },
  },
  formatting = {
    fields = {
      cmp.ItemField.Kind,
      cmp.ItemField.Abbr,
      cmp.ItemField.Menu,
    },
    -- Inspired by these posts:
    -- https://github.com/hrsh7th/nvim-cmp/pull/901
    format = function(_, item)
      item.menu_hl_group = ('CmpItemMenu%s'):format(item.kind)
      item.menu = item.kind
      item.kind = (' %s '):format(kind_icons[item.kind])
      return item
    end,
  },
  window = {
    completion = {
      col_offset = -3,
      side_padding = 0,
    },
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
  view = { entries = 'custom' },
  experimental = { ghost_text = true },
})
