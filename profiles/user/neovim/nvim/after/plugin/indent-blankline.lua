local ibl = require('ibl')

-- :h ibl.config
local config = {
  indent = { char = '▏' },
  scope = {
    show_start = false,
    show_end = false
  },
}

ibl.setup(config)

-- When changing colorschemes, the highlight groups used by ibl are not updated.
vim.api.nvim_create_augroup('IblUpdateGroups', { clear = true })
vim.api.nvim_create_autocmd('ColorScheme', {
  group = 'IblUpdateGroups',
  pattern = '*',
  callback = function()
    ibl.update({})
  end
})

-- TODO: Why does this not work?
-- local ibl_config = require('ibl.config')
-- vim.api.nvim_create_autocmd('User', {
--   pattern = 'TelescopePreviewerLoaded',
--   callback = function(args)
--     if not vim.tbl_contains(ibl_config.default_config.exclude.filetypes, args.data.filetype) then
--       ibl.setup_buffer(0, config)
--     end
--   end,
-- })
