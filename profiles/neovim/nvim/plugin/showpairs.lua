if vim.g.loaded_showpairs then
  return
end

local ns = vim.api.nvim_create_namespace('ShowPairs')
local augroup = vim.api.nvim_create_augroup('ShowPairs', { })

local symbol_pairs = {
  -- Common pairs.
  { '(', ')' },
  { '{', '}' },
  { '[', ']' },

  -- bash command subtitution.
  -- fish command subtitution.
  { '$(', ')' },

  -- bash arithmetic expansion.
  { '$((', '))' },

  -- bash parameter expansion.
  -- Nix interpolation.
  { '${', '}' },

  -- bash test statement.
  -- Lua multiline string.
  -- C++ attribute declaration.
  { '[[', ']]' },

  -- C++ templates.
  -- Rust type parameters.
  { '<', '>' },
}

local lang_to_query_cache = {}

local invalidate_tree_queries = function(tree)
  lang_to_query_cache[tree:lang()] = nil
end

local cache_tree_queries = function(tree)
  local lang = tree:lang()

  if lang_to_query_cache[lang] then
    return
  end

  local query = {}
  local symbols = vim.treesitter.language.inspect(lang).symbols
  for _, pair in pairs(symbol_pairs) do
    local left_supported = false
    local right_supported = false
    for _, value in pairs(symbols) do
      if not left_supported and value[1] == pair[1] then
        left_supported = true
      end

      if not right_supported and value[1] == pair[2] then
        right_supported = true
      end

      if left_supported and right_supported then
        table.insert(query, ('(_ (("%s" @opening) ("%s" @closing)))'):format(pair[1], pair[2]))
        break
      end
    end
  end

  lang_to_query_cache[lang] = vim.treesitter.query.parse(lang, table.concat(query))
end

local remove_highlight = function(bufnr)
  vim.api.nvim_buf_del_extmark(bufnr, ns, 1)
  vim.api.nvim_buf_del_extmark(bufnr, ns, 2)
end

local add_highlight = function(bufnr)
  local cursor = vim.api.nvim_win_get_cursor(0)
  local cursor_range = { cursor[1] - 1, cursor[2], cursor[1] - 1, cursor[2] + 1 }

  -- `LanguageTree:trees()` does not include child languages.
  local trees = {}
  vim.treesitter.get_parser():for_each_tree(function(_, tree)
    if not tree:contains(cursor_range) then
      return
    end

    table.insert(trees, tree)
  end)

  for i = #trees, 1, -1 do
    local tree = trees[i]

    local query = lang_to_query_cache[tree:lang()]
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
        local opening_match, closing_match
        for id, opening_or_closing_match in pairs(match) do
          local name = query.captures[id]

          if name == 'opening' then
            opening_match = opening_or_closing_match
          elseif name == 'closing' then
            closing_match = opening_or_closing_match
          end
        end

        local opening_start_row, opening_start_col, opening_end_row, opening_end_col = opening_match:range()
        local closing_start_row, closing_start_col, closing_end_row, closing_end_col = closing_match:range()

        local mocked_node = {
          range = function (_, _)
            return opening_start_row, opening_start_col, closing_end_row, closing_end_col
          end
        }

        -- Nodes can be mocked with tables in this API, so let's abuse it.
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

    -- Register callbacks for each added language tree to cache the queries,
    -- doing it on every CursorMoved event is feasible but some parsers like
    -- markdown seem to struggle.
    parser:register_cbs({
      on_child_removed = invalidate_tree_queries,
      on_child_added = cache_tree_queries,
    })

    -- Perform an initial pass to cache the queries.
    parser:for_each_tree(function(_, tree)
      cache_tree_queries(tree)
    end)

    vim.api.nvim_create_autocmd('BufLeave', {
      group = augroup,
      buffer = event.buf,
      callback = function()
        remove_highlight(event.buf)
      end,
    })

    vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
      group = augroup,
      buffer = event.buf,
      callback = function()
        if not add_highlight(event.buf) then
          remove_highlight(event.buf)
        end
      end,
    })
  end,
})

vim.g.loaded_showpairs = true
