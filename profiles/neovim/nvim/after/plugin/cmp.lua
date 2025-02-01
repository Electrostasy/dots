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

-- Flip highlight groups for completion item menu. We need to start with the
-- linked groups first in order to not double-flip them.
do
  local linked_groups = {}
  for kind, _ in pairs(kind_icons) do
    local group_str = ('CmpItemKind%s'):format(kind)
    local group = vim.api.nvim_get_hl(0, { name = group_str })

    if group.link then
      table.insert(linked_groups, group_str)
    end
  end

  for _, group_str in pairs(linked_groups) do
    local group = vim.api.nvim_get_hl(0, { name = group_str, link = false })
    vim.api.nvim_set_hl(0, group_str, { fg = group.bg, bg = group.fg })
  end

  for kind, _ in pairs(kind_icons) do
    local group_str = ('CmpItemKind%s'):format(kind)
    if not vim.tbl_contains(linked_groups, group_str) then
      local group = vim.api.nvim_get_hl(0, { name = group_str })
      vim.api.nvim_set_hl(0, group_str, { fg = group.bg, bg = group.fg })
    end
  end
end

local cmp = require('cmp')
cmp.setup({
  mapping = cmp.mapping.preset.insert({
    ['<Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      elseif vim.snippet.active({ direction = 1 }) then
        vim.snippet.jump(1)
      else
        fallback()
      end
    end, { 'i', 's' }),
    ['<S-Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      elseif vim.snippet.active({ direction = -1 }) then
        vim.snippet.jump(-1)
      else
        fallback()
      end
    end, { 'i', 's' }),
    ['<C-j>'] = cmp.mapping.scroll_docs(-1),
    ['<C-k>'] = cmp.mapping.scroll_docs(1),
    ['<C-e>'] = function()
      if vim.snippet.active({ direction = -1 }) or vim.snippet.active({ direction = 1 }) then
        vim.snippet.stop()
      end
      cmp.mapping.abort()
    end,
    ['<CR>'] = cmp.mapping.confirm({ select = false }),
  }),
  sources = {
    { name = 'nvim_lsp' },
    { name = 'async_path', option = { trailing_slash = true } },
  },
  formatting = {
    expandable_indicator = true,
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
    priority_weight = 2,
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
  view = {
    entries = 'custom',
    follow_cursor = true,
  },
  experimental = { ghost_text = true },
})
