-- Linting without plugins (kind of redundant atm)
-- TODO: Filter out LSP diagnostics
-- TODO: Separate into wrapper

-- local ns_name = 'diagnostic'
-- local ns = vim.api.nvim_get_namespaces()[ns_name]
-- if ns == nil then
--   ns = vim.api.nvim_create_namespace(ns_name)
-- end

-- local severity_map = {
--   Error = vim.diagnostic.severity.ERROR,
--   Warning = vim.diagnostic.severity.WARNING
-- }

-- local parse_diagnostic = function(decoded, bufnr)
--   return {
--     bufnr = bufnr,
--     lnum = decoded.primary_label.span.start_line,
--     end_lnum = decoded.primary_label.span.end_line,
--     col = decoded.primary_label.span.start_column,
--     end_col = decoded.primary_label.span.end_column,
--     severity = severity_map[decoded.severity],
--     message = decoded.message,
--     code = decoded.code,
--     source = 'Lua linter.',
--   }
-- end

-- local bufnr = vim.api.nvim_get_current_buf()

-- local lint = function()
--   local bufname = vim.api.nvim_buf_get_name(bufnr)

--   local selene_cfg = vim.fs.find('selene.toml', {
--     path = vim.fs.dirname(bufname),
--     upward = true,
--   })[1]

--   local stdin = vim.loop.new_pipe()
--   local stdout = vim.loop.new_pipe()
--   local stderr = vim.loop.new_pipe()

--   local handle
--   handle = vim.loop.spawn('selene', {
--       args = {
--         bufname,
--         '--no-summary',
--         '--config', selene_cfg,
--         '--display-style', 'json'
--       },
--       stdio = { stdin, stdout, stderr },
--     },
--     function(code, signal)
--       stdin:shutdown(function()
--         stdin:close()
--       end)
--       stdout:shutdown(function()
--         stdout:close()
--       end)
--       stderr:shutdown(function()
--         stderr:close()
--       end)
--       handle:close()
--     end
--   )

--   local chunks = {}
--   stdout:read_start(function(err, chunk)
--     assert(not err, err)
--     if chunk then
--       chunks[#chunks + 1] = chunk
--     else
--       vim.schedule(function()
--         local diagnostics = {}

--         local lines = vim.split(table.concat(chunks), '\n')
--         for _, line in ipairs(lines) do
--           local ok, decoded = pcall(vim.json.decode, line)
--           if ok then
--             local diagnostic = parse_diagnostic(decoded, bufnr)

--             -- If LSP and linter diagnostics overlap, prioritize LSP.
--             for _, lsp_diagnostic in ipairs(vim.diagnostic.get()) do
--               if
--                 (diagnostic.lnum ~= lsp_diagnostic.lnum) and
--                 (diagnostic.end_lnum ~= lsp_diagnostic.end_lnum) and
--                 (diagnostic.col ~= lsp_diagnostic.col) and
--                 (diagnostic.end_col ~= lsp_diagnostic.end_col)
--               then
--                 table.insert(diagnostics, diagnostic)
--               end
--             end
--           end
--         end

--         if vim.api.nvim_buf_is_valid(bufnr) then
--           vim.diagnostic.set(ns, bufnr, diagnostics, { virtual_text = true })
--         end
--       end)
--     end
--   end)
-- end

-- local augroup = vim.api.nvim_create_augroup('Linter', { clear = true })
-- vim.api.nvim_create_autocmd({ 'BufWritePost', 'InsertLeave' }, {
--   group = augroup,
--   buffer = bufnr,
--   callback = lint,
-- })
