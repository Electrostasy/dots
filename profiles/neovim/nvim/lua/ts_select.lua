local M = {}

local select_node = function(node)
  -- If we were previously in V-Line or V-Block modes, this will make sure `gv`
  -- is run in Visual.
  if vim.fn.visualmode() ~= 'v' then
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('v<Esc>', false, true, true), 'nx', false)
  end

  local start_row, start_col, end_row, end_col

  -- Root node can have a weird range that messes up nvim_buf_set_mark.
  -- This seems to be an issue with at least the tree-sitter-lua parser.
  local root = node:tree():root()
  if node:id() == root:id() then
    -- Replace the root node's end range with its last child's end range,
    -- making the selection range what is expected by the user.
    start_row, start_col, _, _ = root:range()
    _, _, end_row, end_col = root:child(root:child_count() - 1):range()
  else
    start_row, start_col, end_row, end_col = node:range()
  end

  -- Reposition the marks and reselect them. We always target the current buffer.
  vim.api.nvim_buf_set_mark(0, '<', start_row + 1, start_col, {})
  vim.api.nvim_buf_set_mark(0, '>', end_row + 1, end_col - 1, {})
  vim.api.nvim_feedkeys('gv', 'nx', false)
end

-- Store a history of expanded nodes for contracting the selection.
local parent_nodes = {}

--- Expand visual selection to the next parent node
M.expand = function()
  local child = vim.treesitter.get_node()
  if not child then
    return
  end

  -- On first expansion, parent_nodes is either empty or invalid (from a newly
  -- initiated expansion).
  if vim.tbl_isempty(parent_nodes) or not vim.treesitter.is_ancestor(child, parent_nodes[1]) then
    parent_nodes = { child }
  end

  -- If next parent's range is the same as the previous parent's, find a parent
  -- node that is actually bigger, selecting what is expected by the user.
  local parent = child:parent()
  while parent do
    local _, _, child_start_byte, _, _, child_end_byte = child:range(true)
    local _, _, parent_start_byte, _, _, parent_end_byte = parent:range(true)

    if parent_start_byte < child_start_byte and parent_end_byte > child_end_byte then
      table.insert(parent_nodes, parent)
      select_node(parent)
      return
    end

    child = parent
    parent = parent:parent()
  end
end

--- Contract visual selection to the previous parent node
M.contract = function()
  local parent
  if #parent_nodes > 1 then
    parent = table.remove(parent_nodes)
  else
    parent = parent_nodes[1]
  end

  select_node(parent)
end

return M
