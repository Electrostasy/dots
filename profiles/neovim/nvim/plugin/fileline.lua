-- Inspired by:
-- https://github.com/lewis6991/fileline.nvim
-- https://github.com/triarius/fileline.nvim
if vim.g.loaded_fileline then
  return
end

local group = vim.api.nvim_create_augroup('FileLine', { })

-- For buffers created at startup, BufAdd is not fired, so we trigger it here
-- manually.
vim.api.nvim_create_autocmd('VimEnter', {
  pattern = '*',
  group = group,
  callback = function()
    for buf in pairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_valid(buf) then
        vim.api.nvim_exec_autocmds('BufAdd', { group = group, buffer = buf })
      end
    end
  end
})

vim.api.nvim_create_autocmd('BufAdd', {
  pattern = { '*:*', '*:*:*' },
  group = group,
  callback = function(event)
    local matches = vim.fn.matchlist(event.file, [[\v^(.{-})(:(\d+))?(:(\d+))?$]])

    local file = matches[2]

    -- Do not continue for buffers with valid colons in their names.
    if file == '' then
      return
    end

    local row = tonumber(matches[4]) or 1
    local column = tonumber(matches[6]) or 1

    vim.cmd.edit(file)
    local win = vim.api.nvim_get_current_win()
    local buf = vim.api.nvim_win_get_buf(win)
    vim.api.nvim_set_current_buf(buf)

    vim.api.nvim_set_option_value('filetype', vim.filetype.match({ buf = buf }), { buf = buf })

    if vim.fn.filereadable(file) == 1 then
      vim.api.nvim_win_set_cursor(0, { row, column - 1 })
    end

    if vim.api.nvim_buf_is_valid(event.buf) then
      vim.api.nvim_buf_delete(event.buf, {})
    end
  end,
})

vim.g.loaded_fileline = 1
