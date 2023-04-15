local ns = vim.api.nvim_create_namespace('showpairs')
local augroup = 'ShowPairs'

local function clear_highlights()
  vim.api.nvim_buf_del_extmark(0, ns, 1)
  vim.api.nvim_buf_del_extmark(0, ns, 2)
end

local function place_highlights(lang_query)
  -- Get the node the cursor is on, and search upwards until a @container is found.
  local cursor_row, cursor_col = unpack(vim.api.nvim_win_get_cursor(0))

  -- We have to pcall here, because get_node_at_pos errors (loudly) if we're on
  -- the first line in the buffer and there is no node there. Conversely, if we
  -- don't reduce cursor_row by 1, we have the same problem on the last row of
  -- the buffer.
  local ok, node = pcall(vim.treesitter.get_node, {
    bufnr = 0,
    pos = { cursor_row - 1, cursor_col }
  })

  if not ok then
    clear_highlights()
    return
  end

  while node do
    for _, match, _ in lang_query:iter_matches(node, 0) do
      local opening, closing
      for match_id, match_node in pairs(match) do
        if opening and closing and vim.treesitter.is_in_node_range(match_node, cursor_row - 1, cursor_col) then
          local opening_start_row, opening_start_col, opening_end_row, opening_end_col = opening:range()
          local closing_start_row, closing_start_col, closing_end_row, closing_end_col = closing:range()

          if opening_start_row == cursor_row - 1 and opening_start_col > cursor_col then
            goto continue
          end

          if closing_end_row == cursor_row - 1 and closing_end_col - 1 < cursor_col then
            goto continue
          end

          vim.api.nvim_buf_set_extmark(0, ns, opening_start_row, opening_start_col, {
            id = 1,
            end_row = opening_end_row,
            end_col = opening_end_col,
            hl_group = 'MatchParen',
            hl_mode = 'combine',
          })
          vim.api.nvim_buf_set_extmark(0, ns, closing_start_row, closing_start_col, {
            id = 2,
            end_row = closing_end_row,
            end_col = closing_end_col,
            hl_group = 'MatchParen',
            hl_mode = 'combine',
            -- Workaround to prevent errors when matching pair is inserted at
            -- the end of the line.
            -- TODO: Closing pair is not highlighted.
            strict = false,
          })

          return
        end

        local name = lang_query.captures[match_id]
        if name == 'opening' then
          opening = match_node
        elseif name == 'closing' then
          closing = match_node
        end

        ::continue::
      end
    end

    node = node:parent()
  end

  clear_highlights()
end

local function on_buf_leave(bufnr)
  return {
    group = augroup,
    buffer = bufnr,
    callback = clear_highlights,
  }
end

local function on_cursor_moved(bufnr, lang)
  local lang_query = vim.treesitter.query.get(lang, 'showpairs')
  return {
    group = augroup,
    buffer = bufnr,
    callback = function()
      place_highlights(lang_query)
    end,
  }
end

require('nvim-treesitter').define_modules({
  showpairs = {
    is_supported = function(lang)
      return vim.treesitter.query.get(lang, 'showpairs')
    end,
    attach = function(bufnr, lang)
      vim.api.nvim_create_augroup(augroup, { clear = false })
      vim.api.nvim_create_autocmd('BufLeave', on_buf_leave(bufnr))
      vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, on_cursor_moved(bufnr, lang))
    end,
    detach = function(bufnr)
      clear_highlights()

      local autocmds = vim.api.nvim_get_autocmds({
        group = augroup,
        buffer = bufnr
      })

      for autocmd in pairs(autocmds) do
        vim.api.nvim_del_autocmd(autocmd.id)
      end

      if #vim.api.nvim_get_autocmds({ group = augroup }) > 0 then
        vim.api.nvim_del_augroup_by_name(augroup)
      end
    end,
  }
})

-- local configured_pairs = {
--   { opening = '(', closing = ')' },
--   { opening = '<', closing = '>' },
--   { opening = '[', closing = ']' },
--   { opening = '{', closing = '}' },
-- }

-- -- Preprocess the pairs list.
-- for i, value in ipairs(configured_pairs) do
--   configured_pairs[i] = {
--     opening = value.opening:byte(),
--     closing = value.closing:byte()
--   }
-- end

-- local function parse()
--   -- If this filetype is not supported, don't continue.
--   local ft = vim.opt.filetype:get()
--   local ft_patterns = patterns[ft]
--   if not ft_patterns then
--     return
--   end

--   local cursor_row, cursor_col = unpack(vim.api.nvim_win_get_cursor(0))
--   local node = vim.treesitter.get_node_at_pos(0, cursor_row - 1, cursor_col)

--   while node do
--     local type = node:type()

--     local start_row, start_col, end_row, end_col = node:range()
--     local text = vim.treesitter.get_node_text(node, 0, { concat = false })

--     if vim.tbl_contains(ft_patterns.fallback, type) then
--       -- Use manual parsing method on the parent treesitter node.
--       -- TODO: Skip pairs in string nodes.
--       for _, pair in ipairs(configured_pairs) do
--         local opening_char = pair.opening
--         local closing_char = pair.closing

--         -- Otherwise, fall back to parsing from the cursor position outwards
--         -- until a matching pair is determined.
--         local search_at

--         -- Search to the right and down for a pair.
--         local hl_end_row, hl_end_col
--         local right = 1
--         if cursor_row - 1 == start_row then
--           search_at = cursor_col - start_col + 1
--         else
--           search_at = cursor_col + 1
--         end
--         for row = cursor_row, end_row + 1 do
--           local col = search_at
--           while col < #text[row - start_row] + 1 do
--             local char = text[row - start_row]:byte(col)
--             local is_closing = char == closing_char
--             local is_opening = char == opening_char

--             if is_closing then
--               right = right - 1
--             elseif is_opening then
--               right = right + 1
--             end

--             if is_closing or is_opening then
--               hl_end_row = row
--               hl_end_col = col
--             end

--             if right == 0 then
--               break
--             end

--             col = col + 1
--           end

--           if right == 0 then
--             break
--           end

--           search_at = 1
--         end

--         -- Search to the left and up for a pair.
--         local hl_start_row, hl_start_col
--         local left = 1
--         if cursor_row - 1 == start_row then
--           search_at = cursor_col - start_col + 1
--         else
--           search_at = cursor_col + 1
--         end
--         for row = cursor_row, start_row, -1 do
--           local col = search_at
--           while col > 0 do
--             local char = text[row - start_row]:byte(col)
--             local is_closing = char == closing_char
--             local is_opening = char == opening_char

--             if is_closing then
--               left = left + 1
--             elseif is_opening then
--               left = left - 1
--             end

--             if is_closing or is_opening then
--               hl_start_row = row
--               hl_start_col = col
--             end

--             if left == 0 then
--               break
--             end

--             col = col - 1
--           end

--           if left == 0 then
--             break
--           end

--           if row - start_row - 1 > 0 then
--             search_at = #text[row - start_row - 1]
--           else
--             break
--           end
--         end

--         local has_left = left == 0
--         local has_right = right == 0
--         local on_left = has_left and right == 1
--         local on_right = left == 1 and has_right

--         if has_left and has_right or on_left or on_right then
--           -- If there is only 1 line, apply indentation to both. Otherwise,
--           -- only to the beginning.
--           if hl_end_row == hl_start_row then
--             hl_end_col = hl_end_col + start_col
--             hl_start_col = hl_start_col + start_col
--           else
--             hl_start_col = hl_start_col + start_col
--           end

--           highlight(hl_start_row, hl_start_col, hl_end_row, hl_end_col)
--           return
--         end
--       end
--     end

--     -- If the node didn't match any of the patterns, try the parent node.
--     node = node:parent()
--   end

--   unhighlight()
-- end
