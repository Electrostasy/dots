if vim.g.loaded_incremental_selection then
  return
end

local augroup = vim.api.nvim_create_augroup('IncrementalSelection', { clear = true })

local node_visual_select = function(node)
  -- If we were previously in V-Line or V-Block modes, this will make sure `gv`
  -- is run in Visual.
  if vim.fn.visualmode() ~= 'v' then
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('v<Esc>', false, true, true), 'nx', false)
  end

  local start_row, start_col, end_row, end_col

  -- Root node can have a weird range that messes up nvim_buf_set_mark. This fix
  -- replaces the root node's end range with its last child's end range.
  -- Seems to be an issue with the Lua parser at least.
  -- TODO: How to detect this?
  local root = node:tree():root()
  if node:id() == root:id() then
    start_row, start_col, _, _ = root:range()
    _, _, end_row, end_col = root:child(root:child_count() - 1):range()
  else
    start_row, start_col, end_row, end_col = node:range()
  end

  vim.api.nvim_buf_set_mark(0, '<', start_row + 1, start_col, {})
  vim.api.nvim_buf_set_mark(0, '>', end_row + 1, end_col - 1, {})

  vim.api.nvim_feedkeys('gv', 'nx', false)
end

local parent_nodes = {}

-- Expand visual selection to parent node.
local expand = function(init_node)
  return function()
    local parent
    if vim.tbl_isempty(parent_nodes) then
      parent = init_node:parent()
    else
      parent = parent_nodes[#parent_nodes]:parent()
    end

    if not parent then
      return
    end

    -- If next parent's range is the same as the previous parent's, find a parent
    -- node that is actually bigger.
    local _, _, child_start_byte, _, _, child_end_byte = parent_nodes[#parent_nodes]:range(true)
    while parent do
      local _, _, parent_start_byte, _, _, parent_end_byte = parent:range(true)

      if parent_start_byte < child_start_byte and child_end_byte < parent_end_byte then
        table.insert(parent_nodes, parent)
        node_visual_select(parent)
        return
      end

      parent = parent:parent()
    end
  end
end

-- Contract visual selection to last parent node (child).
local contract = function()
  local node
  if #parent_nodes > 1 then
    node = table.remove(parent_nodes)
  else
    node = parent_nodes[#parent_nodes]
  end

  node_visual_select(node)
end

-- Select current node and define keymaps for going up and down the tree.
local enter = function()
  -- TODO: Setting timeoutlen like this will set it globally for the duration of
  -- incremental selection, look into making it only for the binds with vim.on_key?
  ---@diagnostic disable-next-line: undefined-field
  local old_timeoutlen = vim.opt.timeoutlen:get()
  vim.opt.timeoutlen = 0

  -- Select the current node at cursor.
  local init_node = vim.treesitter.get_node()
  node_visual_select(init_node)

  parent_nodes = { init_node }

  vim.keymap.set('v', '<Space>', expand(init_node), { buffer = true })
  vim.keymap.set('v', '<C-Space>', contract, { buffer = true })

  -- Setup an autocmd to clean up after ourselves.
  local previous_modechange = nil
  vim.api.nvim_create_autocmd('ModeChanged', {
    group = augroup,
    pattern = { 'v:*', '*:v' },
    callback = function(event)
      if previous_modechange ~= event.match and event.match:sub(event.match:len()) ~= 'v' then
        vim.keymap.del('v', '<Space>', { buffer = true })
        vim.keymap.del('v', '<C-Space>', { buffer = true })
        vim.opt.timeoutlen = old_timeoutlen
        previous_modechange = nil
        return true
      end

      previous_modechange = event.match
    end,
  })
end

vim.api.nvim_create_autocmd({ 'BufReadPost', 'FileType' }, {
  group = augroup,
  callback = function(event)
    if not vim.treesitter.language.get_lang(vim.opt_local.filetype:get()) then
      if vim.fn.mapcheck('<C-Space', 'n') ~= '' then
        vim.keymap.del('n', '<C-Space>', { buffer = event.buf })
      end
      return
    end

    vim.keymap.set('n', '<C-Space>', enter, { buffer = event.buf })
  end,
})

vim.g.loaded_incremental_selection = true
