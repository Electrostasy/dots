local cmp = require('cmp')
local luasnip = require('luasnip')

local has_words_before = function()
  local line, col = unpack(vim.api.nvim_win_get_cursor(0))
  return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
end

vim.opt.completeopt = 'menu,menuone,noselect'

cmp.setup({
  snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body)
    end
  },
  mapping = cmp.mapping.preset.insert({
    ["<Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      elseif luasnip.expand_or_jumpable() then
        luasnip.expand_or_jump()
      elseif has_words_before() then
        cmp.complete()
      else
        fallback()
      end
    end, { "i", "s" }),
    ["<S-Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      elseif luasnip.jumpable(-1) then
        luasnip.jump(-1)
      else
        fallback()
      end
    end, { "i", "s" }),
    ['<C-j>'] = cmp.mapping.scroll_docs(-1),
    ['<C-k>'] = cmp.mapping.scroll_docs(1),
    ['<C-e>'] = cmp.mapping.abort(),
    ['<CR>'] = cmp.mapping.confirm({ select = false }),
  }),
  sources = {
    { name = 'nvim_lsp' },
    { name = 'buffer' },
    { name = 'path' },
    { name = 'luasnip'},
  },
  formatting = {
    fields = {
      cmp.ItemField.Kind,
      cmp.ItemField.Abbr,
      cmp.ItemField.Menu,
    },
    -- Stolen from here:
    -- https://github.com/hrsh7th/nvim-cmp/pull/901
    -- https://github.com/CKolkey/.config/blob/master/.config/nvim/lua/plugins/_completion.lua#L10-L17
    format = function(entry, vim_item)
      local kind = require('lspkind').cmp_format({ mode = "symbol_text", maxwidth = 50 })(entry, vim_item)
      local strings = vim.split(kind.kind, "%s", { trimempty = true })
      kind.kind = " " .. strings[1] .. " "
      kind.menu = "(" .. strings[2] .. ")"
      return kind
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
  view = { entries = 'custom'}
})
