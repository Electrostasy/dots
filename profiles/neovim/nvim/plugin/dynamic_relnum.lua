-- Adapted from the example provided at `:h ModeChanged`.
if vim.g.loaded_dynamic_relnum then
  return
end

local augroup = vim.api.nvim_create_augroup('DynamicRelativeNumber', { })

local callback = function()
  vim.wo.relativenumber = vim.api.nvim_get_mode().mode:find('[vV\22]') and vim.wo.number or false
end

vim.api.nvim_create_autocmd('ModeChanged', {
  group = augroup,
  desc = 'Set relativenumber when entering visual/select line/block modes',
  pattern = { '[vV\x16]*:*', '*:[vV\x16]*' },
  callback = callback,
})

-- We cannot use only ModeChanged, as that will conflict with blink.cmp's
-- completion window by shifting it to the left whenever the completion items
-- are scrolled.
vim.api.nvim_create_autocmd({ 'WinEnter', 'WinLeave' }, {
  group = augroup,
  desc = 'Set relativenumber when entering and leaving windows',
  pattern = { '*' },
  callback = callback,
})

vim.g.loaded_dynamic_relnum = 1
