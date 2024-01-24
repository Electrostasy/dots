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

require('nvim-treesitter').define_modules({
  showpairs = {
    is_supported = function(lang)
      return vim.treesitter.query.get(lang, 'showpairs')
    end,
    attach = function(bufnr, lang)
      vim.api.nvim_create_augroup(augroup, { clear = false })
      vim.api.nvim_create_autocmd('BufLeave', {
        group = augroup,
        buffer = bufnr,
        callback = clear_highlights
      })
      vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
        group = augroup,
        buffer = bufnr,
        callback = function()
          place_highlights(vim.treesitter.query.get(lang, 'showpairs'))
        end,
      })
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
