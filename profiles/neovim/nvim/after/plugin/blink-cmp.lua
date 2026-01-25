local luminance = require('util').luminance

-- Reverse the fg/bg highlights for BlinkCmpKind* and set them as
-- BlinkCmpKindIcon*, so the icons will have a bright bg and a dark fg while
-- the kind names will have a dark bg and a bright fg.
for kind in pairs(require('blink.cmp.config').appearance.kind_icons) do
  local kind_hl = 'BlinkCmpKind' .. kind
  local group = vim.api.nvim_get_hl(0, { name = kind_hl, link = false, create = false })
  if group ~= nil then
    if luminance(group.fg) > luminance(group.bg) then
      group.fg, group.bg = group.bg, group.fg
    end

    ---@diagnostic disable-next-line: param-type-mismatch
    vim.api.nvim_set_hl(0, 'BlinkCmpKindIcon' .. kind, group)
  end
end

require('blink.cmp').setup({
  keymap = {
    preset = 'enter',
    ['<C-space>'] = false,
    ['<C-d>'] = { 'show_documentation', 'hide_documentation', 'fallback' },
    ['<C-b>'] = { function(cmp) return cmp.scroll_documentation_up(1) end, 'fallback' },
    ['<C-f>'] = { function(cmp) return cmp.scroll_documentation_down(1) end, 'fallback' },
  },
  completion = {
    menu = {
      draw = {
        padding = { 0, 1 },
        columns = { { 'kind_icon' }, { 'label', 'label_description', gap = 1 }, { 'kind' } },
        components = {
          kind_icon = {
            text = function(ctx) return ' ' .. ctx.kind_icon .. ' ' end,
            highlight = function(ctx) return 'BlinkCmpKindIcon' .. ctx.kind end,
          },
          kind = {
            highlight = function(ctx) return 'BlinkCmpKind' .. ctx.kind end,
          },
        },
      },
    },
    ghost_text = {
      enabled = true,
    },
    list = {
      selection = {
        auto_insert = false,
      },
    },
  },
  sources = {
    providers = {
      lsp = {
        -- If an LSP takes a long time to initialize or return completions,
        -- conditionally mark it as async so we get other completions first:
        -- https://github.com/Saghen/blink.cmp/issues/540#issuecomment-2542050104
        -- async = function()
        --   local clients = { 'lua-language-server' }
        --   return vim.iter(vim.lsp.get_clients({ bufnr = 0 }))
        --     :any(function(client)
        --       return vim.tbl_contains(clients, client.name)
        --     end)
        -- end,
      },
    },
  },
  signature = {
    enabled = true,
    window = {
      show_documentation = false,
    },
  },
  fuzzy = {
    sorts = {
      'score',
      -- Prioritize items without leading or multiple underscores in label.
      'label',
      'sort_text',
    },

    implementation = 'rust',
    prebuilt_binaries = {
      download = false,
    },
  },
})
