if vim.g.loaded_showpairs then
  return
end

local ns = vim.api.nvim_create_namespace('ShowPairs')
local augroup = vim.api.nvim_create_augroup('ShowPairs', { })

local extmark_ids = {
  opening = 1,
  closing = 2,
}

local remove_highlight = function()
  vim.api.nvim_buf_del_extmark(0, ns, extmark_ids.opening)
  vim.api.nvim_buf_del_extmark(0, ns, extmark_ids.closing)
end

local add_highlight = function(opening_node, closing_node)
  local set_extmark_for_node = function(id, node)
    local start_row, start_col, end_row, end_col = node:range()
    vim.api.nvim_buf_set_extmark(0, ns, start_row, start_col, {
      id = id,
      end_row = end_row,
      end_col = end_col,
      hl_group = 'MatchParen',
      hl_mode = 'combine',
    })
  end

  set_extmark_for_node(extmark_ids.opening, opening_node)
  set_extmark_for_node(extmark_ids.closing, closing_node)
end

-- Workaround for `vim.treesitter.is_in_node_range()` not working in exceptions
-- like in Lua: `query.captures[id]` - the entire container node is `captures[id]`,
-- so if we check whether the cursor is within the container node, which works for
-- other nodes just fine, if the cursor is on `captures` outside of the brackets,
-- the brackets will still get matched.
local is_range_between_nodes = function(range, start_node, end_node)
  local start_row, start_col = start_node:start()
  local end_row, end_col = end_node:start()

  local container = { start_row, start_col, end_row, end_col }

  -- This uses private API but I do not want to reimplement it right now.
  return require('vim.treesitter._range').contains(container, range)
end

local try_add_highlight = function()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local cursor_range = { cursor[1] - 1, cursor[2], cursor[1] - 1, cursor[2] }

  local trees = {}
  vim.treesitter.get_parser():for_each_tree(function(_, tree)
    if tree:contains(cursor_range) then
      table.insert(trees, tree)
    end
  end)

  for i = #trees, 1, -1 do
    local tree = trees[i]
    local query = vim.treesitter.query.get(tree:lang(), 'showpairs')
    if query == nil then
      return
    end

    local node = tree:named_node_for_range(cursor_range)
    while node do
      for _, match, _ in query:iter_matches(node, 0) do
        local opening_match, closing_match
        for id, opening_or_closing_match in pairs(match) do
          local name = query.captures[id]
          if name == 'opening' then
            opening_match = opening_or_closing_match
          elseif name == 'closing' then
            closing_match = opening_or_closing_match
          end
        end

        -- FIXME: This will not highlight the parent node of a comment for some reason.
        if is_range_between_nodes(cursor_range, opening_match, closing_match) then
          add_highlight(opening_match, closing_match)
          return
        end
      end

      node = node:parent()
    end
  end

  remove_highlight()
end

vim.api.nvim_create_autocmd({ 'BufReadPost', 'FileType' }, {
  group = augroup,
  desc = 'Set up showpairs for the buffer',
  callback = function(event)
    local query = vim.treesitter.query.get(vim.opt_local.filetype:get(), 'showpairs')
    if not query then
      return
    end

    vim.api.nvim_create_autocmd('BufLeave', {
      group = augroup,
      buffer = event.buf,
      callback = remove_highlight
    })

    vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
      group = augroup,
      buffer = event.buf,
      callback = try_add_highlight,
    })
  end,
})

vim.g.loaded_showpairs = true
