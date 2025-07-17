if vim.g.loaded_dynamic_listchars then
  return
end

-- Visible outside of Insert mode.
local normal_listchars = {
  extends = '»',
  precedes = '«',
  tab = '  ',
  trail = '∙',
}

-- Visible only in Insert mode.
local insert_listchars = {
  eol = '¶',
  lead = '·',
  nbsp = '¤',
  space = '·',
  tab = '··',
}

vim.opt.listchars = normal_listchars

vim.api.nvim_create_autocmd({ 'InsertEnter', 'InsertLeavePre' }, {
  group = vim.api.nvim_create_augroup('InsertModeListChars', { }),
  desc = 'Show full listchars only in Insert mode',
  pattern = '*',
  callback = function(args)
    if vim.tbl_contains({ 'quickfix', 'prompt' }, args.match) then
      return
    end

    if args.event == 'InsertEnter' then
      vim.opt_local.listchars = insert_listchars
    else
      vim.opt_local.listchars = normal_listchars
    end

    -- Execute `OptionSet` autocmds manually instead of running this nested.
    vim.api.nvim_exec_autocmds('OptionSet', {
      group = 'IndentBlankline',
      pattern = 'listchars',
    })
  end
})

vim.g.loaded_dynamic_listchars = 1
