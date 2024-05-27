if vim.g.loaded_lsp then
  return
end

-- LSP diagnostics shown as virtual lines.
require('lsp_lines').setup()
vim.diagnostic.config({
  virtual_text = false,
  virtual_lines = { highlight_whole_line = false },
})

vim.keymap.set('n', '<Leader>dt', function()
  local virt_text = vim.diagnostic.config().virtual_text
  vim.diagnostic.config({
    virtual_text = not virt_text,
    virtual_lines = virt_text,
  })
end, { desc = 'Toggle line diagnostics', silent = true })

vim.api.nvim_create_augroup('LspMappings', { clear = true })
vim.api.nvim_create_autocmd({ 'LspAttach', 'LspDetach' }, {
  group = 'LspMappings',
  pattern = '*',
  callback = function(args)
    -- :h lsp-method
    local mappings = {
      ['textDocument/codeAction'] = {
        'n', '<Leader>c', vim.lsp.buf.code_action, {
          desc = 'Select a code action available at the current cursor position',
          buffer = args.buf,
          silent = true,
        }
      },

      ['textDocument/declaration'] = {
        'n', '<Leader>d', vim.lsp.buf.declaration, {
          desc = 'Jump to the declaration of the symbol under the cursor',
          buffer = args.buf,
          silent = true,
        }
      },

      ['textDocument/definition'] = {
        'n', '<Leader>D', vim.lsp.buf.definition, {
          desc = 'Jump to the definition of the symbol under the cursor',
          buffer = args.buf,
          silent = true,
        }
      },

      ['textDocument/hover'] = {
        'n', '<Leader>h', vim.lsp.buf.definition, {
          desc = 'Display information about the symbol under the cursor in a floating window',
          buffer = args.buf,
          silent = true,
        }
      },

      ['textDocument/implementation'] = {
        'n', '<Leader>i', vim.lsp.buf.implementation, {
          desc = 'List all implementations for the symbol under the cursor in the quickfix window',
          buffer = args.buf,
          silent = true,
        }
      },

      ['textDocument/typeDefinition'] = {
        'n', '<Leader>t', vim.lsp.buf.type_definition, {
          desc = 'Jump to the definition of the type of the symbol under the cursor',
          buffer = args.buf,
          silent = true,
        }
      },

      ['textDocument/rename'] = {
        'n', '<Leader>r', vim.lsp.buf.rename, {
          desc = 'Renames all references to the symbol under the cursor',
          buffer = args.buf,
          silent = true,
        }
      },
      ['textDocument/references'] = {
        'n', '<Leader>R', vim.lsp.buf.references, {
          desc = 'List all references to the symbol under the cursor in the quickfix window',
          buffer = args.buf,
          silent = true,
        }
      },
    }

    if args.event == 'LspAttach' then
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      if not client then
        return
      end

      for method, mapping in pairs(mappings) do
        if client.supports_method(method) then
          vim.keymap.set(unpack(mapping))
        end
      end

      if client.supports_method('textDocument/semanticTokens/full') then
        require('hlargs').disable_buf(args.buf)
      end

      if client.supports_method('textDocument/inlayHint') then
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
    else
      for _, mapping in pairs(mappings) do
        local mode, lhs, _, opts = unpack(mapping)
        -- TODO: Skip deleting keymaps that were never made.
        pcall(vim.keymap.del, mode, lhs, { buffer = opts.buffer })
      end

      require('hlargs').enable_buf(args.buf)

      vim.api.nvim_clear_autocmds({
        group = 'LspMappings',
        event = 'ModeChanged',
        pattern = { 'n:[^cV]', '[^cV]:n' },
      })
    end
  end
})

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
vim.g.loaded_lsp = 1
