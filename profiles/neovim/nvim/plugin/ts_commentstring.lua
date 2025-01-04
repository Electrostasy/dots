if vim.g.loaded_ts_commentstring then
  return
end

local augroup = vim.api.nvim_create_augroup('CommentString', { })

vim.api.nvim_create_autocmd({ 'BufReadPost', 'FileType' }, {
  group = augroup,
  pattern = '*.*',
  desc = 'Set up treesitter commentstring for the buffer',
  callback = function(event)
    local ok, parser = pcall(vim.treesitter.get_parser, event.buf)
    if not ok then
      return
    end

    local filetype_at_root = vim.bo[event.buf].filetype

    vim.api.nvim_create_autocmd('CursorMoved', {
      group = augroup,
      buffer = event.buf,
      desc = 'Update the commentstring',
      callback = function()
        local cursor = vim.api.nvim_win_get_cursor(0)
        local filetype_at_cursor = parser:language_for_range({ cursor[1] - 1, cursor[2], cursor[1] - 1, cursor[2] + 1 }):lang()

        local cs = vim.filetype.get_option(filetype_at_cursor, 'commentstring')
        if cs then
          vim.api.nvim_set_option_value('commentstring', cs, { buf = event.buf })
        else
          vim.api.nvim_set_option_value('commentstring', vim.filetype.get_option(filetype_at_root, 'commentstring'), { buf = event.buf })
        end
      end,
    })
  end,
})

vim.g.loaded_ts_commentstring = true
