local M = {}

-- Expand from the target node outwards to include leading and trailing comments
-- until an empty line is found, and return a range.
local expand_range_to_comments = function(node)
  local start_row, start_col, end_row, end_col = node:range()

  local sibling_node = node:prev_named_sibling()
  while sibling_node do
    local sibling_start_row, sibling_start_col, sibling_end_row, _ = sibling_node:range()

    if not sibling_node:type():find('comment') or math.abs(sibling_end_row - start_row) > 1 then
      break
    end

    start_row = sibling_start_row
    start_col = sibling_start_col

    sibling_node = sibling_node:prev_named_sibling()
  end

  sibling_node = node:next_named_sibling()
  while sibling_node do
    local sibling_start_row, _, sibling_end_row, sibling_end_col = sibling_node:range()

    if not sibling_node:type():find('comment') or math.abs(sibling_start_row - end_row) > 1 then
      break
    end

    end_row = sibling_end_row
    end_col = sibling_end_col

    sibling_node = sibling_node:next_named_sibling()
  end

  return start_row, start_col, end_row, end_col
end

-- Sorts all the named nodes that are children of the node under the cursor
-- without touching the delimiters or their occupied positions. Comments are
-- not sorted, but if they are 'attached' to the node (not separated by a line)
-- they move with it wherever it ends up getting sorted to.
M.sort_nodes_on_cursor = function()
  local winnr = vim.api.nvim_get_current_win()
  local cursor = vim.api.nvim_win_get_cursor(winnr)

  local bufnr = vim.api.nvim_win_get_buf(winnr)
  local parser = vim.treesitter.get_parser(bufnr)
  if not parser then
    return
  end

  parser:parse()

  local target_node = parser:named_node_for_range({ cursor[1] - 1, cursor[2], cursor[1] - 1, cursor[2] + 1}, { ignore_injections = false })
  if not target_node then
    return
  end

  local named_children = target_node:named_children()

  -- If we are on a container node, get its named children instead.
  while #named_children == 1 do
    target_node = named_children[1]
    named_children = target_node:named_children()
  end

  named_children = vim.iter(named_children)

  if vim.api.nvim_get_mode().mode:sub(1, 1):lower() == 'v' then
    -- The '< and '> marks are only set after we leave Visual mode, so we leave
    -- visual mode and reselect the range in order to have them represent the
    -- current visual selection.
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>gv', false, true, true), 'nx', false)

    -- Remove any nodes that are outside the visual selection.
    named_children:filter(function(node)
      local start_row, start_col = unpack(vim.api.nvim_buf_get_mark(bufnr, '<'))
      local end_row, end_col = unpack(vim.api.nvim_buf_get_mark(bufnr, '>'))

      local mocked_node = {
        range = function (_, _)
          return start_row - 1, start_col, end_row - 1, end_col
        end
      }

      return vim.treesitter.node_contains(mocked_node, { node:range() })
    end)
  end

  named_children = named_children
    :filter(function(node)
      return not node:type():find('comment')
    end)
    :map(function(node)
      return {
        sort_key = vim.treesitter.get_node_text(node, bufnr),
        range = { expand_range_to_comments(node) },
      }
    end)
    :totable()

  -- Need to clone the table for sorting.
  local sorted_children = vim.tbl_extend('keep', named_children, {})
  table.sort(sorted_children, function(a, b)
    return a.sort_key < b.sort_key
  end)

  local text_edits = {}

  for i, named_node in ipairs(named_children) do
    local sorted_start_row, sorted_start_col, sorted_end_row, sorted_end_col = unpack(sorted_children[i].range)
    local named_start_row, named_start_col, named_end_row, named_end_col = unpack(named_node.range)

    local text = vim.api.nvim_buf_get_text(bufnr, sorted_start_row, sorted_start_col, sorted_end_row, sorted_end_col, {})
    table.insert(text_edits, {
      newText = table.concat(text, '\n'),
      range = {
        start = {
          line = named_start_row,
          character = named_start_col,
        },
        ['end'] = {
          line = named_end_row,
          character = named_end_col,
        },
      },
    })
  end

  vim.lsp.util.apply_text_edits(text_edits, bufnr, vim.bo.fileencoding)
end

return M
