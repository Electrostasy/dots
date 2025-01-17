if vim.g.loaded_ts_showpairs then
  return
end

local ns = vim.api.nvim_create_namespace('ShowPairs')
local augroup = vim.api.nvim_create_augroup('ShowPairs', { })

local symbol_pairs = {
  { '(', ')' },
  { '{', '}' },
  { '[', ']' },
  { '<', '>' },

  -- Shell command subtitution.
  { '$(', ')' },

  -- bash arithmetic expansion.
  { '$((', '))' },

  -- bash parameter expansion.
  -- Nix interpolation.
  { '${', '}' },

  -- bash test statement.
  -- Lua literal string.
  -- C++ attribute specifier sequence.
  { '[[', ']]' },

  -- bash process substitution.
  { '<(', ')' },
  { '>(', ')' },

  -- Rust closure.
  { '|', '|' },
}

local _query_cache = {}

_query_cache.on_child_removed = function(tree)
  _query_cache[tree:lang()] = nil
end

_query_cache.on_child_added = function(tree)
  local lang = tree:lang()

  if _query_cache[lang] then
    return
  end

  local symbols = vim.iter(vim.treesitter.language.inspect(lang).symbols)
    :fold({}, function(acc, _, value)
      acc[value[1]] = true
      return acc
    end)

  _query_cache[lang] = vim.treesitter.query.parse(lang, vim.iter(symbol_pairs)
    :fold('', function(acc, pair)
      local opening = pair[1]
      local closing = pair[2]

      if symbols[opening] and symbols[closing] then
        acc = acc .. ('(_ (("%s" @opening) ("%s" @closing)))'):format(opening, closing)
      end

      return acc
    end))
end

local _remove_highlight = function(bufnr)
  vim.api.nvim_buf_del_extmark(bufnr, ns, 1)
  vim.api.nvim_buf_del_extmark(bufnr, ns, 2)
end

local _add_highlight = function(bufnr)
  local cursor = vim.api.nvim_win_get_cursor(0)
  local cursor_range = { cursor[1] - 1, cursor[2], cursor[1] - 1, cursor[2] + 1 }

  local tree = vim.treesitter.get_parser():language_for_range(cursor_range)
  while tree do
    local query = _query_cache[tree:lang()]
    if not query then
      return false
    end

    -- In some rare cases, usually when removing text/nodes, we can unknowingly
    -- invalidate the tree and *really* break things, needing to kill the nvim
    -- process to recover. This prevents that.
    if not tree:is_valid() then
      tree:parse()
    end

    local node = tree:named_node_for_range(cursor_range)
    while node do
      for _, match, _ in query:iter_matches(node, bufnr) do
        local opening_start_row, opening_start_col, opening_end_row, opening_end_col = match[1]:range()
        local closing_start_row, closing_start_col, closing_end_row, closing_end_col = match[2]:range()

        -- Some nodes can contain the matching pair as part of their node, which
        -- is why we must explicitly check if the cursor is inside the range
        -- between the pair. Nodes can be mocked with tables in this API, so we
        -- abuse it to do exactly that.
        local mocked_node = {
          range = function (_, _)
            return opening_start_row, opening_start_col, closing_end_row, closing_end_col
          end
        }

        ---@diagnostic disable: missing-fields
        if vim.treesitter.node_contains(mocked_node, cursor_range) then
          vim.api.nvim_buf_set_extmark(bufnr, ns, opening_start_row, opening_start_col, {
            id = 1,
            end_row = opening_end_row,
            end_col = opening_end_col,
            hl_group = 'MatchParen',
            hl_mode = 'combine',
          })

          vim.api.nvim_buf_set_extmark(bufnr, ns, closing_start_row, closing_start_col, {
            id = 2,
            end_row = closing_end_row,
            end_col = closing_end_col,
            hl_group = 'MatchParen',
            hl_mode = 'combine',
          })

          return true
        end
      end

      node = node:parent()
    end

    ---@diagnostic disable-next-line: invisible
    tree = tree:parent()
  end

  return false
end

vim.api.nvim_create_autocmd({ 'BufReadPost', 'FileType' }, {
  group = augroup,
  desc = 'Set up showpairs for the buffer',
  callback = function(event)
    local ok, parser = pcall(vim.treesitter.get_parser, event.buf)
    if not ok then
      return
    end

    parser:register_cbs({
      on_child_removed = _query_cache.on_child_removed,
      on_child_added = _query_cache.on_child_added,
    })

    -- The callbacks are not called until a tree is added/removed, so we need
    -- to perform a first pass.
    parser:for_each_tree(function(_, tree)
      _query_cache.on_child_added(tree)
    end)

    vim.api.nvim_create_autocmd('BufLeave', {
      group = augroup,
      buffer = event.buf,
      callback = function()
        _remove_highlight(event.buf)
      end,
    })

    vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
      group = augroup,
      buffer = event.buf,
      callback = function()
        if not _add_highlight(event.buf) then
          _remove_highlight(event.buf)
        end
      end,
    })
  end,
})

vim.g.loaded_ts_showpairs = true
