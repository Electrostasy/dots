if vim.g.loaded_showpairs then
  return
end

local ns = vim.api.nvim_create_namespace('ShowPairs')
local augroup = vim.api.nvim_create_augroup('ShowPairs', { clear = false })

local extmark_ids = {
  opening = 1,
  closing = 2,
}

local del_extmarks = function()
  vim.api.nvim_buf_del_extmark(0, ns, extmark_ids.opening)
  vim.api.nvim_buf_del_extmark(0, ns, extmark_ids.closing)
end

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

-- Workaround for `vim.treesitter.is_in_node_range()` not working in exceptions
-- like in Lua: `query.captures[id]` - the entire container node is `captures[id]`,
-- so if we check whether the cursor is within the container node, which works for
-- other nodes just fine, if the cursor is on `captures` outside of the brackets,
-- the brackets will still get matched.
local cursor_is_in_node_range = function(cursor, start_node, end_node)
  local start_row, start_col = start_node:start()
  local end_row, end_col = end_node:start()

  local container = { start_row, start_col, end_row, end_col }
  local range = { cursor[1] - 1, cursor[2], cursor[1] - 1, cursor[2] }

  -- This uses private API but I do not want to reimplement it right now.
  return require('vim.treesitter._range').contains(container, range)
end

local place_extmarks = function(query)
  local cursor = vim.api.nvim_win_get_cursor(0)
  local parent_node = vim.treesitter.get_node()

  while parent_node do
    for _, match, _ in query:iter_matches(parent_node, 0) do
      local opening, closing
      for id, node in pairs(match) do
        local name = query.captures[id]
        if name == 'opening' then
          opening = node
        elseif name == 'closing' then
          closing = node
        end
      end

      if cursor_is_in_node_range(cursor, opening, closing) then
        set_extmark_for_node(extmark_ids.opening, opening)
        set_extmark_for_node(extmark_ids.closing, closing)
        return
      else
        del_extmarks()
      end
    end

    parent_node = parent_node:parent()
  end

  del_extmarks()
end

vim.api.nvim_create_autocmd({ 'BufReadPost', 'FileType' }, {
  group = augroup,
  callback = function(event)
    local filetype = vim.opt_local.filetype:get()
    local query = vim.treesitter.query.get(filetype, 'showpairs')
    if not query then
      vim.api.nvim_clear_autocmds({
        group = augroup,
        buffer = event.buf,
        event = { 'BufLeave', 'CursorMoved', 'CursorMovedI' },
      })
      return
    end

    vim.api.nvim_create_autocmd('BufLeave', {
      group = augroup,
      buffer = event.buf,
      callback = del_extmarks
    })

    vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
      group = augroup,
      buffer = event.buf,
      callback = function()
        place_extmarks(query)
      end,
    })
  end,
})

vim.g.loaded_showpairs = true
