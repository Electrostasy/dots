local devicons = require('nvim-web-devicons')
if not devicons.has_loaded() then
  devicons.setup()
end

-- Override the default quickfix ftplugin, that modifies the statusline.
-- :h ft-qf-plugin
vim.g.qf_disable_statusline = 1

vim.api.nvim_create_augroup('StatusLine', { clear = true })

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
      t[group] = vim.api.nvim_get_hl(0, { name = group })
    end
    return t
  end

  vim.api.nvim_create_autocmd('ColorScheme', {
    group = 'StatusLine',
    pattern = '*',
    callback = function()
      hl = renew_hlgroups()
    end
  })

  hl = renew_hlgroups()

  -- Define highlight groups for the statusline.
  local stl_groups = {
    -- StatusLineUser1 = { fg = hl.StatusLine.foreground, bg = blend(hl.User1.background, hl.StatusLine.background, 0.1) },
    -- StatusLineUser2 = { fg = hl.StatusLine.foreground, bg = blend(hl.User2.background, hl.StatusLine.background, 0.1) },
    -- StatusLineUser3 = { fg = hl.StatusLine.foreground, bg = blend(hl.User3.background, hl.StatusLine.background, 0.1) },
    -- StatusLineUser4 = { fg = hl.StatusLine.foreground, bg = blend(hl.User4.background, hl.StatusLine.background, 0.1) },
    -- StatusLineUser5 = { fg = hl.StatusLine.foreground, bg = blend(hl.User5.background, hl.StatusLine.background, 0.1) },
    -- StatusLineUser6 = { fg = hl.StatusLine.foreground, bg = blend(hl.User6.background, hl.StatusLine.background, 0.1) },
    -- StatusLineUser7 = { fg = hl.StatusLine.foreground, bg = blend(hl.User7.background, hl.StatusLine.background, 0.1) },
    -- StatusLineUser8 = { fg = hl.StatusLine.foreground, bg = blend(hl.User8.background, hl.StatusLine.background, 0.1) },
    -- StatusLineUser9 = { fg = hl.StatusLine.foreground, bg = blend(hl.User9.background, hl.StatusLine.background, 0.1) },
    StatusLineLSPError = { fg = hl.DiagnosticSignError.foreground, bg = hl.StatusLine.background },
    StatusLineLSPWarn = { fg = hl.DiagnosticSignWarn.foreground, bg = hl.StatusLine.background },
    StatusLineLSPInfo = { fg = hl.DiagnosticSignInfo.foreground, bg = hl.StatusLine.background },
    StatusLineLSPHint = { fg = hl.DiagnosticSignHint.foreground, bg = hl.StatusLine.background },
    StatusLineNCLSPError = { fg = hl.DiagnosticSignError.foreground, bg = hl.StatusLineNC.background },
    StatusLineNCLSPWarn = { fg = hl.DiagnosticSignWarn.foreground, bg = hl.StatusLineNC.background },
    StatusLineNCLSPInfo = { fg = hl.DiagnosticSignInfo.foreground, bg = hl.StatusLineNC.background },
    StatusLineNCLSPHint = { fg = hl.DiagnosticSignHint.foreground, bg = hl.StatusLineNC.background },
    StatusLineGitAdd = { fg = hl.GitSignsAdd.foreground, bg = hl.StatusLine.background },
    StatusLineGitDelete = { fg = hl.GitSignsDelete.foreground, bg = hl.StatusLine.background },
    StatusLineGitChange = { fg = hl.GitSignsChange.foreground, bg = hl.StatusLine.background },
    StatusLineNCGitAdd = { fg = hl.GitSignsAdd.foreground, bg = hl.StatusLineNC.background },
    StatusLineNCGitDelete = { fg = hl.GitSignsDelete.foreground, bg = hl.StatusLineNC.background },
    StatusLineNCGitChange = { fg = hl.GitSignsChange.foreground, bg = hl.StatusLineNC.background },
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
  pattern = { 'begin', 'report', 'end' },
  group = 'StatusLine',
  callback = function(event)
    if timer:get_due_in() == 0 then
      timer:start(0, 80, function()
        for _, client in pairs(vim.lsp.get_clients({ id = event.data.client_id })) do
          if client.progress:peek() then
            -- Cycle through frames.
            vim.b[event.buf].lsp_progress_idx = (vim.b[event.buf].lsp_progress_idx or 1) % #progress_frames + 1
            timer:again()
          else
            -- Reset cycle index for next run.
            vim.b[event.buf].lsp_progress_idx = 1
            timer:stop()
          end

          -- Redraw statusline on next tick.
          vim.schedule(function()
            vim.api.nvim_command('redrawstatus')
          end)
        end
      end)
    end
  end
})

-- Set a variable containing the file size.
-- Based on the implementation in lualine filesize.lua component.
vim.api.nvim_create_autocmd({ 'BufWinEnter', 'BufWrite' }, {
  pattern = '*',
  group = 'StatusLine',
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

  -- Fold level.
  -- local show_foldlevel = vim.opt.foldcolumn:get() ~= 0
  -- if show_foldlevel then
  --   local foldlevel = vim.fn.foldlevel(cline)
  --   if foldlevel > 0 then
  --     table.insert(groups, foldlevel)
  --     gutter_width = gutter_width - int_len(foldlevel)
  --   end
  -- end

  -- Max line number in gutter.
  ---@diagnostic disable-next-line: undefined-field
  local show_linenr = vim.opt.number:get() or vim.opt.relativenumber:get()
  if show_linenr then
    local buf_length_digits = int_len(vim.api.nvim_buf_line_count(buf))
    table.insert(groups, ('%s%s '):format(string.rep(' ', gutter_width - buf_length_digits - 2), '%L'))
  end

  -- Mode indicator.
  local mode, mode_hl = unpack(mode_map[vim.api.nvim_get_mode().mode:sub(1, 1)])
  ---@diagnostic disable-next-line: undefined-field
  if current == 0 and not vim.opt.showmode:get() then
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
  local ruler = vim.opt.ruler:get()
  if ruler then
    local format = vim.opt.rulerformat:get()
    if format == '' then
      format = '%l:%c'
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
  if vim.opt.shortmess:get().S and vim.v.hlsearch == 1 then
    local ok, count = pcall(vim.fn.searchcount, { recompute = true })
    if ok and count.current ~= nil and count.total ~= 0 then
      local search_icon = '  '
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

  -- TODO: Show multiple LSP clients instead of first attached one.
  for _, client in pairs(vim.lsp.get_clients({ bufnr = buf })) do
    if client.progress:peek() ~= nil then
      local progress = client.progress:pop()
      if progress.value ~= nil and progress.value.title ~= nil then
        table.insert(groups, (' %s %s'):format(progress.value.title, progress_frames[vim.b[buf].lsp_progress_idx]))
      end
    end

    local nc = current == 0 and '' or 'NC'

    local function diagnostic_format(kind)
      local diagnostics = #vim.diagnostic.get(buf, { severity = vim.diagnostic.severity[kind:upper()] })
      local group = ('StatusLine%sLSP%s'):format(nc, kind)
      local _, sign = next(vim.fn.sign_getdefined('DiagnosticSign' .. kind))
      if diagnostics > 0 then
        return ('%%#%s# %d %s'):format(group, diagnostics, sign.text)
      end
    end

    for _, kind in pairs({ 'Error', 'Warn', 'Info', 'Hint' }) do
      local format = diagnostic_format(kind)
      if error then
        table.insert(groups, format)
      end
    end

    table.insert(groups, ('%%* %s'):format(client.config.name))
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
      table.insert(groups, (' %s %%#%s#  '):format(branch, branch_hl))
    end
  end

  return table.concat(groups)
end

vim.api.nvim_create_autocmd({ 'WinEnter', 'BufEnter' }, {
  group = 'StatusLine',
  pattern = '*',
  callback = function()
    vim.opt_local.statusline = [[%{%v:lua.__StatusLine(0)%}]]
  end
})

vim.api.nvim_create_autocmd({ 'WinLeave', 'BufLeave' }, {
  group = 'StatusLine',
  pattern = '*',
  callback = function()
    vim.opt_local.statusline = [[%{%v:lua.__StatusLine(1)%}]]
  end
})
