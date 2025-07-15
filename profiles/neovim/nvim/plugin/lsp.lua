if vim.g.loaded_lsp then
  return
end

-- :h diagnostic-signs
vim.diagnostic.config({
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = '',
      [vim.diagnostic.severity.HINT] = '󰞋',
      [vim.diagnostic.severity.INFO] = '',
      [vim.diagnostic.severity.WARN] = '',
    },
  }
})

vim.keymap.set('n', '<Leader>dt', function()
  local virtual_lines = not vim.diagnostic.config().virtual_lines
  vim.diagnostic.config({
    virtual_text = not virtual_lines,
    virtual_lines = virtual_lines,
  })
end, { desc = 'Toggle line diagnostics', silent = true })

vim.api.nvim_create_augroup('LspMappings', { })

vim.api.nvim_create_autocmd('LspAttach', {
  group = 'LspMappings',
  pattern = '*',
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if not client then
      return
    end

    if client:supports_method('textDocument/semanticTokens/full') then
      require('hlargs').disable_buf(args.buf)
    end

    vim.lsp.inlay_hint.enable(true, { bufnr = args.buf })

    -- Inlay hint updates can take a while presumably due to the LSP roundtrip,
    -- so instead of showing them all the time while editing and them getting stuck,
    -- we disable them depending on the active mode.
    vim.api.nvim_create_autocmd('ModeChanged', {
      group = 'LspMappings',
      pattern = { 'n:[^cV]', '[^cV]:n' },
      callback = function(ev)
        if ev.buf ~= args.buf then
          return
        end

        local enable = ev.match:sub(ev.match:len()) == 'n' or ev.match:sub(1, 1) ~= 'n'
        vim.lsp.inlay_hint.enable(enable, { bufnr = args.buf })
      end,
    })
  end
})

vim.iter(vim.api.nvim_get_runtime_file('lsp/*.lua', true))
  :map(function(file)
      return vim.fs.basename(file):sub(1, -(#'.lua' + 1))
  end)
  :each(vim.lsp.enable)

vim.g.loaded_lsp = 1
