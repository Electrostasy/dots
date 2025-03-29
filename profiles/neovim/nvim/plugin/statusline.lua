local devicons = require('nvim-web-devicons')
if not devicons.has_loaded() then
  devicons.setup()
end

-- Override the default quickfix ftplugin that modifies the statusline.
-- :h ft-qf-plugin
vim.g.qf_disable_statusline = 1

local augroup = vim.api.nvim_create_augroup('StatusLine', { })

local mode_map = {
  ['n'] = { 'Normal', 'User1' },
  ['v'] = { 'Visual', 'User2' },
  ['V'] = { 'V-Line', 'User2' },
  ['\22'] = { 'V-Block', 'User2' },
  ['s'] = { 'Select', 'User3' },
  ['S'] = { 'S-Line', 'User3' },
  ['\19'] = { 'S-Block', 'User3' },
  ['i'] = { 'Insert', 'User4' },
  ['R'] = { 'Replace', 'User5' },
  ['c'] = { 'Command', 'User6' },
  ['r'] = { 'Prompt', 'User7' },
  ['r?'] = { 'Confirm', 'User7' },
  ['!'] = { 'Shell', 'User8' },
  ['t'] = { 'Terminal', 'User9' },
}

-- Pre-fetch colorscheme highlight groups to derive colours from. Update the
-- highlight groups on colorscheme changes automatically.
local hl = {}
do
  local groups = {
    'User1',
    'User2',
    'User3',
    'User4',
    'User5',
    'User6',
    'User7',
    'User8',
    'User9',
    'StatusLine',
    'StatusLineNC',
    'DiagnosticSignError',
    'DiagnosticSignWarn',
    'DiagnosticSignInfo',
    'DiagnosticSignHint',
    'GitSignsAdd',
    'GitSignsDelete',
    'GitSignsChange',
  }

  local function renew_hlgroups()
    local t = {}
    for _, group in ipairs(groups) do
      t[group] = vim.api.nvim_get_hl(0, { name = group, link = false })
    end
    return t
  end

  vim.api.nvim_create_autocmd('ColorScheme', {
    group = augroup,
    pattern = '*',
    callback = function()
      hl = renew_hlgroups()
    end
  })

  hl = renew_hlgroups()

  -- Define highlight groups for the statusline.
  local stl_groups = {
    StatusLineLSPError = { fg = hl.DiagnosticSignError.fg, bg = hl.StatusLine.bg },
    StatusLineLSPWarn = { fg = hl.DiagnosticSignWarn.fg, bg = hl.StatusLine.bg },
    StatusLineLSPInfo = { fg = hl.DiagnosticSignInfo.fg, bg = hl.StatusLine.bg },
    StatusLineLSPHint = { fg = hl.DiagnosticSignHint.fg, bg = hl.StatusLine.bg },
    StatusLineNCLSPError = { fg = hl.DiagnosticSignError.fg, bg = hl.StatusLineNC.bg },
    StatusLineNCLSPWarn = { fg = hl.DiagnosticSignWarn.fg, bg = hl.StatusLineNC.bg },
    StatusLineNCLSPInfo = { fg = hl.DiagnosticSignInfo.fg, bg = hl.StatusLineNC.bg },
    StatusLineNCLSPHint = { fg = hl.DiagnosticSignHint.fg, bg = hl.StatusLineNC.bg },
    StatusLineGitAdd = { fg = hl.GitSignsAdd.fg, bg = hl.StatusLine.bg },
    StatusLineGitDelete = { fg = hl.GitSignsDelete.fg, bg = hl.StatusLine.bg },
    StatusLineGitChange = { fg = hl.GitSignsChange.fg, bg = hl.StatusLine.bg },
    StatusLineNCGitAdd = { fg = hl.GitSignsAdd.fg, bg = hl.StatusLineNC.bg },
    StatusLineNCGitDelete = { fg = hl.GitSignsDelete.fg, bg = hl.StatusLineNC.bg },
    StatusLineNCGitChange = { fg = hl.GitSignsChange.fg, bg = hl.StatusLineNC.bg },
  }
  for group, opts in pairs(stl_groups) do
    vim.api.nvim_set_hl(0, group, opts)
  end
end

local function int_len(int)
  return math.floor(math.log10(int))
end

local function buffer_name()
  local buf = vim.api.nvim_get_current_buf()
  local name = vim.api.nvim_buf_get_name(buf)

  if name == '' then
    return '[Scratch]'
  end

  local tail = vim.fn.fnamemodify(name, ':t')
  local windows = vim.api.nvim_list_wins()
  if #windows == 1 then
    return tail
  end

  -- Split the current buffer name by path separator and note groups count.
  local self_elements = vim.split(name, '/')
  if self_elements[1] == '' then
    self_elements = vim.list_slice(self_elements, 2, #self_elements - 1)
  end
  local self_elems_count = #self_elements

  for _, win in ipairs(windows) do
    local other_buf = vim.api.nvim_win_get_buf(win)
    if other_buf ~= buf then
      local other_buf_name = vim.api.nvim_buf_get_name(other_buf)
      local other_name_tail = vim.fn.fnamemodify(other_buf_name, ':t')

      if tail ~= other_name_tail then
        return tail
      end

      -- Split the window buffer name by path separator and note groups count.
      local buf_elements = vim.split(name, '/')
      if buf_elements[1] == '' then
        buf_elements = vim.list_slice(buf_elements, 2, #buf_elements - 1)
      end
      local buf_elems_count = #buf_elements

      -- Iterate through paths backwards until a match is found.
      for i, _ in ipairs(self_elements) do
        local self_elem = self_elements[self_elems_count + 1 - i]

        for j, _ in ipairs(buf_elements) do
          local buf_elem = buf_elements[buf_elems_count + 1 - j]

          if i == j and self_elem == buf_elem then
            table.insert(self_elements, tail)

            local final_tail = vim.list_slice(
              self_elements,
              math.min(self_elems_count, buf_elems_count),
              self_elems_count + 1
            )

            return table.concat(final_tail, '/')
          end
        end
      end
    end
  end
end

-- LSP progress timer for statusline, based on:
-- https://gist.github.com/runiq/2e81265c1c2a7587fbe9c184ceaa94c6
local progress_frames = { '⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏' }
local timer = vim.uv.new_timer()
vim.api.nvim_create_autocmd('LspProgress', {
  pattern = '*',
  group = augroup,
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if not client then
      return
    end

    if not vim.iter(pairs(client.attached_buffers)):find(args.buf) then
      return
    end

    if timer:get_due_in() == 0 then
      timer:start(0, 80, function()
        if client.progress:peek() then
          -- Cycle through frames.
          vim.b[args.buf].lsp_progress_idx = (vim.b[args.buf].lsp_progress_idx or 1) % #progress_frames + 1
          timer:again()
        else
          -- Reset cycle index for next run.
          vim.b[args.buf].lsp_progress_idx = 1
          timer:stop()
        end

        -- Redraw statusline on next tick.
        vim.schedule(function()
          vim.api.nvim_command('redrawstatus')
        end)
      end)
    end
  end
})

-- Set a variable containing the file size.
-- Based on the implementation in lualine filesize.lua component.
vim.api.nvim_create_autocmd({ 'BufWinEnter', 'BufWrite' }, {
  pattern = '*',
  group = augroup,
  callback = function()
    local file = vim.api.nvim_buf_get_name(0)
    if file == nil or #file == 0 then
      return
    end

    local size = vim.fn.getfsize(file)
    if size <= 0 then
      return
    end

    local suffixes = { 'B', 'KB', 'MB', 'GB', 'TB' }

    local i = 1
    while size > 1000 and i < #suffixes do
      size = size / 1000
      i = i + 1
    end

    vim.b.stl_filesize = { number = size, units = suffixes[i] }
  end
})

function __StatusLine(current)
  local win = vim.api.nvim_get_current_win()
  local win_nr = vim.api.nvim_win_get_number(win)
  local buf = vim.api.nvim_win_get_buf(win)
  local gutter_width = vim.fn.getwininfo()[win_nr].textoff

  local groups = {}

  -- Max line number in gutter.
  ---@diagnostic disable-next-line: undefined-field
  if vim.wo.number or vim.wo.relativenumber then
    local buf_length_digits = int_len(vim.api.nvim_buf_line_count(buf))
    table.insert(groups, ('%s%s '):format(string.rep(' ', gutter_width - buf_length_digits - 2), '%L'))
  end

  -- Mode indicator.
  local mode, mode_hl = unpack(mode_map[vim.api.nvim_get_mode().mode:sub(1, 1)])
  ---@diagnostic disable-next-line: undefined-field
  if current == 0 and not vim.o.showmode then
    table.insert(groups, ('%%#%s# %s %%*'):format(mode_hl, mode))
  end

  local buftype = vim.bo[buf].buftype
  if buftype == '' then
    -- Show the file name/path.
    local bufname = buffer_name()
    local bufext = vim.fn.fnamemodify(bufname, ':e')
    local icon, icon_group = devicons.get_icon(bufname, bufext, { default = true })
    table.insert(groups, ('%%#Normal# %s %%#%s#%s %%*'):format(bufname, icon_group, icon))
  elseif buftype == 'quickfix' then
    -- Display the command that produced the quickfix list.
    table.insert(groups, ('%%#Normal# %s %%*'):format(vim.w.quickfix_title))
  end

  local modifiable = vim.bo.modifiable
  local modified = vim.bo.modified
  if modifiable and modified then
    table.insert(groups, (' %s'):format('󰽂'))
  elseif not modifiable then
    table.insert(groups, (' %s'):format('󰦝'))
  end

  ---@diagnostic disable-next-line: undefined-field
  local ruler = vim.o.ruler
  if ruler then
    local format = vim.o.rulerformat
    if format == '' then
      format = '󰳂 %l:%c'
    end
    table.insert(groups, (' %s'):format(format))
  end

  local size = vim.b.stl_filesize
  if size then
    table.insert(groups, (' %.2f %s'):format(size.number, size.units))
  end

  local encoding = (vim.bo.fenc ~= '' and vim.bo.fenc) or vim.o.enc
  if encoding ~= 'utf-8' then
    table.insert(groups, (' %s'):format(encoding))
  end

  -- Indentation.
  local spaces = vim.o.expandtab
  local tab_size = vim.o.softtabstop ~= 0 and vim.o.softtabstop or vim.o.tabstop
  local indent = (' %s%s'):format(spaces and vim.o.shiftwidth or tab_size, spaces and ' spaces' or '-wide tabs')
  table.insert(groups, indent)

  -- Show incremental search count.
  if vim.o.shortmess:find('S') and vim.v.hlsearch == 1 then
    local ok, count = pcall(vim.fn.searchcount, { recompute = true })
    if ok and count.current ~= nil and count.total ~= 0 then
      local search_icon = '  '
      if count.incomplete == 1 then
        table.insert(groups, (' %s ?/?'):format(search_icon))
      else
        local too_many = ('>%d'):format(count.maxcount)
        local current_count = count.current > count.maxcount and too_many or count.current
        local total_count = count.total > count.maxcount and too_many or count.total
        table.insert(groups, (search_icon .. '%s/%s'):format(current_count, total_count))
      end
    end
  end

  table.insert(groups, '%=')

  do
    local diagnostics_map = {
      [vim.diagnostic.severity.ERROR] = 'Error',
      [vim.diagnostic.severity.WARN] = 'Warn',
      [vim.diagnostic.severity.INFO] = 'Info',
      [vim.diagnostic.severity.HINT] = 'Hint',
    }

    local signs = vim.diagnostic.config().signs
    if signs == nil or signs == true then
      signs = vim.iter(diagnostics_map):map(function(s) s:sub(1, 1) end):totable()
    elseif signs.text then
      signs = signs.text
    end

    -- TODO: Show multiple LSP clients instead of first attached one.
    for _, client in pairs(vim.lsp.get_clients({ bufnr = buf })) do
      if client.progress:peek() ~= nil then
        local progress = client.progress:pop()
        if progress.value ~= nil and progress.value.title ~= nil then
          table.insert(groups, (' %s %s'):format(progress.value.title, progress_frames[vim.b[buf].lsp_progress_idx]))
        end
      end

      for severity_id, severity_pretty in pairs(diagnostics_map) do
        local diagnostics = #vim.diagnostic.get(buf, { severity = severity_id })
        if diagnostics > 0 then
          local group = ('StatusLine%sLSP%s'):format(current == 0 and '' or 'NC', severity_pretty)
          table.insert(groups, ('%%#%s# %d %s '):format(group, diagnostics, signs[severity_id]))
        end
      end

      table.insert(groups, ('%%* %s'):format(client.config.name))
    end
  end

  -- Git components.
  local git = vim.b.gitsigns_status_dict
  if git then
    local nc = current == 0 and '' or 'NC'

    local additions_count = git.added or 0
    if additions_count > 0 then
      table.insert(groups, (' %%#StatusLine%sGitAdd#+%d%%*'):format(nc, additions_count))
    end

    local removals_count = git.removed or 0
    if removals_count > 0 then
      table.insert(groups, (' %%#StatusLine%sGitDelete#-%d%%*'):format(nc, removals_count))
    end

    local changes_count = git.changed or 0
    if changes_count > 0 then
      table.insert(groups, (' %%#StatusLine%sGitChange#~%d%%*'):format(nc, changes_count))
    end

    local branch = git.head
    if branch ~= '' then
      local branch_hl = mode_hl
      if current == 1 then
        branch_hl = 'Normal'
      end
      table.insert(groups, (' %s %%#%s#  '):format(branch, branch_hl))
    end
  end

  return table.concat(groups)
end

vim.api.nvim_create_autocmd({ 'WinEnter', 'BufEnter' }, {
  group = augroup,
  pattern = '*',
  callback = function()
    vim.wo.statusline = [[%{%v:lua.__StatusLine(0)%}]]
  end
})

vim.api.nvim_create_autocmd({ 'WinLeave', 'BufLeave' }, {
  group = augroup,
  pattern = '*',
  callback = function()
    vim.wo.statusline = [[%{%v:lua.__StatusLine(1)%}]]
  end
})
