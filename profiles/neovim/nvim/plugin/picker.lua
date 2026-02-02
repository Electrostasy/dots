table.clear = package.preload['table.clear']()

if vim.g.loaded_picker then
  return
end

-- TODO: Buffer preselect is not working due to some funkiness with TextChanged/I.
-- TODO: Live grep API like with Telescope (match_item?).
-- TODO: Better window resizing logic.
-- TODO: Removing buffers with the buffer picker.
-- TODO: Better empty preview window.
-- TODO: Move out of plugin/ and into lua/?

local augroup = vim.api.nvim_create_augroup('PickerTest', { clear = true })
local ns = vim.api.nvim_create_namespace('PickerTest')

local ns_devicons = vim.api.nvim_create_namespace('PickerDevIcons')
local ns_linenrs = vim.api.nvim_create_namespace('PickerLineNrs')
local ns_matches = vim.api.nvim_create_namespace('PickerMatches')
local ns_selection = vim.api.nvim_create_namespace('PickerSelection')

local format_item_default = tostring

local preview_item_default = function(_item)
  return -1
end

local state = {
  prompt_bufnr = vim.api.nvim_create_buf(false, true),
  list_bufnr = vim.api.nvim_create_buf(false, true),
  preview_bufnr = vim.api.nvim_create_buf(false, true),
  prompt_winid = -1,
  list_winid = -1,
  preview_winid = -1,

  items = {},
  matches = {},
  format_item = format_item_default,
  preview_item = preview_item_default,
  previewed_buffers = {},
}

vim.api.nvim_set_option_value('buftype', 'prompt', { buf = state.prompt_bufnr })
vim.api.nvim_set_option_value('filetype', 'picker_prompt', { buf = state.prompt_bufnr })
vim.api.nvim_set_option_value('filetype', 'picker_list', { buf = state.prompt_bufnr })
vim.api.nvim_set_option_value('filetype', 'picker_preview', { buf = state.prompt_bufnr })

-- If the preview window is under 40 characters in width, it is hidden.
local preview_hidden_threshold = 40

local update_preview = function()
  if vim.api.nvim_win_get_config(state.preview_winid).hide then
    return
  end

  local row = vim.api.nvim_win_get_cursor(state.list_winid)[1]
  if row == nil then
    return
  end

  local item = (state.matches[1] or state.items)[row]
  if item ~= nil then
    item = item.value
  end

  local bufnr
  if state.previewed_buffers[item] == nil then
    bufnr = state.preview_item(item)
    if vim.api.nvim_buf_is_valid(bufnr) then
      vim.api.nvim_set_option_value('modified', false, { buf = bufnr })
      state.previewed_buffers[item] = bufnr
    else
      bufnr = state.preview_bufnr
    end
  else
    bufnr = state.previewed_buffers[item]
  end

  vim.api.nvim_win_set_buf(state.preview_winid, bufnr)
  vim.api.nvim_win_set_config(state.preview_winid, {
    title = (' %s '):format(state.format_item(item)),
    title_pos = 'center',
  })

  vim.api.nvim_set_option_value('cursorline', false, { win = state.preview_winid })
end

local select_item = function(row)
  vim.api.nvim_win_set_cursor(state.list_winid, { row, 0 })
  vim.api.nvim_buf_set_extmark(state.list_bufnr, ns_selection, row - 1, 0, {
    id = 1,
    sign_text = '▶',
    sign_hl_group = 'CursorLine',
  })

  update_preview()
end

local update_list = function()
  vim.api.nvim_buf_clear_namespace(state.list_bufnr, ns_devicons, 0, -1)
  vim.api.nvim_buf_clear_namespace(state.list_bufnr, ns_linenrs, 0, -1)
  vim.api.nvim_buf_clear_namespace(state.list_bufnr, ns_matches, 0, -1)

  local text_cb = function(item)
    return state.format_item(item.value)
  end

  local input = vim.api.nvim_buf_get_lines(state.prompt_bufnr, 0, 1, false)[1]
  if #input > 0 then
    state.matches = vim.fn.matchfuzzypos(state.items, input, { text_cb = text_cb })
  else
    table.clear(state.matches)
  end

  local lines = vim.iter(state.matches[1] or state.items):map(text_cb):totable()
  vim.api.nvim_buf_set_lines(state.list_bufnr, 0, -1, true, lines)

  local has_items = #lines > 0
  vim.api.nvim_set_option_value('cursorline', has_items, { win = state.list_winid })
  vim.api.nvim_set_option_value('number', has_items, { win = state.list_winid })
  vim.api.nvim_set_option_value('statuscolumn', has_items and '%l %s' or '', { win = state.list_winid })
end

local resize = function()
  if
    not vim.api.nvim_win_is_valid(state.prompt_winid) or
    not vim.api.nvim_win_is_valid(state.list_winid) or
    not vim.api.nvim_win_is_valid(state.preview_winid)
  then
    return
  end

  local center_row = math.floor(vim.o.lines * 0.5) - vim.o.cmdheight
  local center_col = math.floor(vim.o.columns * 0.5)
  local picker_start_row = math.floor(center_row * 0.25)
  local picker_start_col = math.floor(center_col * 0.5)
  local picker_end_row = math.floor(center_row * 1.5)
  local prompt_width = math.floor(center_col * 0.5)
  local preview_width = math.max(1, center_col - prompt_width)

  local preview_hidden = state.preview_item == preview_item_default or preview_width < preview_hidden_threshold
  if preview_hidden then
    prompt_width = center_col
  end

  vim.api.nvim_win_set_config(state.prompt_winid, {
    relative = 'editor',
    row = picker_start_row,
    col = picker_start_col,
    width = prompt_width,
    height = 1,
  })

  vim.api.nvim_win_set_config(state.list_winid, {
    relative = 'win',
    win = state.prompt_winid,
    row = 2,
    col = -1,
    width = prompt_width,
    height = picker_end_row - 3,
  })

  vim.api.nvim_win_set_config(state.preview_winid, {
    relative = 'win',
    win = state.prompt_winid,
    row = -1,
    col = prompt_width + 1,
    width = preview_width,
    height = picker_end_row,
    hide = preview_hidden,
  })
end

local devicons = require('nvim-web-devicons')
if not devicons.has_loaded() then
  devicons.setup()
end
local default_devicon = devicons.get_default_icon()

local devicon_decorator = function(_winid, bufnr, row)
  local line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, true)[1]
  if #line == 0 then
    return
  end

  local id = row + 1

  if #vim.api.nvim_buf_get_extmark_by_id(bufnr, ns_devicons, id, {}) > 0 then
    return
  end

  local ft = vim.filetype.match({ filename = line })
  local icon = devicons.get_icon_by_filetype(ft) or default_devicon.icon
  local name = devicons.get_icon_name_by_filetype(ft) or default_devicon.name

  vim.api.nvim_buf_set_extmark(bufnr, ns_devicons, row, 0, {
    id = id,
    virt_text = { { icon .. ' ', 'DevIcon' .. name:gsub('^%l', string.upper), } },
    virt_text_pos = 'inline',
  })
end

local line_number_decorator = function(_winid, bufnr, row)
  local line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, true)[1]
  local id = row + 1

  if #vim.api.nvim_buf_get_extmark_by_id(bufnr, ns_linenrs, id, {}) > 0 then
    return
  end

  local line_bufnr = vim.fn.bufnr(line)
  if not vim.api.nvim_buf_is_loaded(line_bufnr) then
    return
  end

  -- Using the " mark or getcursorcharpos by themselves is unreliable.
  -- With the " mark, it is not updated after changing cursor position until the picker is closed and opened again.
  -- With getcursorcharpos, sometimes the buffer cursor position resets to (1, 1).
  local cursor_mark = vim.api.nvim_buf_get_mark(line_bufnr, [["]])
  local cursor_charpos = vim.api.nvim_buf_call(line_bufnr, vim.fn.getcursorcharpos)
  local cursor_row = math.max(cursor_mark[1], cursor_charpos[2])
  local cursor_col = math.max(cursor_mark[2], cursor_charpos[3])

  vim.api.nvim_buf_set_extmark(bufnr, ns_linenrs, row, -1, {
    id = id,
    virt_text = { { (':%d:%d'):format(cursor_row, cursor_col), 'NonText' } },
    virt_text_pos = 'inline',
    hl_mode = 'combine',
  })
end

local fuzzy_match_decorator = function(_winid, bufnr, row)
  local id = 1

  if next(state.matches) == nil then
    return
  end

  local matches = state.matches[2][row + 1]
  if matches == nil then
    return
  end

  for _, col in next, matches do
    vim.api.nvim_buf_set_extmark(bufnr, ns_matches, row, col, {
      id = id,
      end_col = col + 1,
      hl_group = 'Special',
    })
    id = id + 1
  end
end

local file_previewer = function(item)
  if type(item) == 'number' then
    item = vim.fn.bufname(item)
  end

  if vim.fn.filereadable(item) == 0 then
    return -1
  end

  if vim.system({ 'file', '--brief', '--mime-encoding', item }):wait().stdout == 'binary\n' then
    return -1
  end

  local bufnr = vim.api.nvim_create_buf(false, false)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, true, vim.fn.readfile(item))

  local ok, lang = pcall(vim.filetype.match, { buf = bufnr, filename = item })
  if ok and lang then
    if vim.treesitter.language.add(lang) then
      vim.treesitter.start(bufnr, lang)
    else
      vim.api.nvim_set_option_value('syntax', lang, { buf = bufnr })
    end
  end

  return bufnr
end

local close_picker = function()
  vim.cmd.stopinsert()

  pcall(vim.api.nvim_win_close, state.prompt_winid, true)
  pcall(vim.api.nvim_win_close, state.list_winid, true)
  pcall(vim.api.nvim_win_close, state.preview_winid, true)

  vim.api.nvim_buf_set_lines(state.prompt_bufnr, 0, -1, true, {})
  vim.api.nvim_set_option_value('modified', false, { buf = state.prompt_bufnr })

  table.clear(state.items)
  table.clear(state.matches)
  state.format_item = format_item_default
  state.preview_item = preview_item_default

  for _, bufnr in next, state.previewed_buffers do
    pcall(vim.api.nvim_buf_delete, bufnr, { force = true })
  end
  table.clear(state.previewed_buffers)
end

local open_picker = function(items, opts, on_choice)
  vim.fn.prompt_setprompt(state.prompt_bufnr, '')
  vim.fn.prompt_setcallback(state.prompt_bufnr, function()
    local row = vim.api.nvim_win_get_cursor(state.list_winid)[1]
    local selection
    if next(state.matches) ~= nil then
      selection = state.matches[1][row].value
    else
      selection = state.items[row].value
    end

    close_picker()

    on_choice(selection)
  end)

  state.items = vim.iter(items)
    :map(function(item)
      return { value = item }
    end)
    :totable()

  local file_hint = opts.kind:find('file')
  local buffer_hint = opts.kind:find('buffer')

  if opts.format_item ~= nil then
    state.format_item = opts.format_item
  end

  if opts.preview_item ~= nil then
    state.preview_item = opts.preview_item
  else
    if file_hint or buffer_hint then
      state.preview_item = file_previewer
    end
  end

  local decorators = {}
  if file_hint or buffer_hint then
    table.insert(decorators, devicon_decorator)
  end

  local preselect = 1
  if buffer_hint then
    table.insert(decorators, line_number_decorator)

    local current_buf = vim.api.nvim_get_current_buf()
    preselect = vim.iter(state.items):enumerate():find(function(_, item)
      return item.value == current_buf
    end)
  end

  table.insert(decorators, fuzzy_match_decorator)

  vim.api.nvim_set_decoration_provider(ns, {
    on_win = function(_, winid, bufnr, _toprow, _botrow)
      if winid ~= state.list_winid or bufnr ~= state.list_bufnr then
        return false
      end
    end,
    on_line = function(_, ...)
      for _, decorator in next, decorators do
        decorator(...)
      end
    end,
  })

  state.prompt_winid = vim.api.nvim_open_win(state.prompt_bufnr, true, {
    relative = 'editor',
    row = 0,
    col = 0,
    width = 1,
    height = 1,

    title = (' %s '):format(opts.prompt or 'Prompt'),
    title_pos = 'center',
    style = 'minimal',
    border = 'single',
    focusable = false,
  })

  state.list_winid = vim.api.nvim_open_win(state.list_bufnr, false, {
    relative = 'win',
    win = state.prompt_winid,
    row = 0,
    col = 0,
    width = 1,
    height = 1,

    style = 'minimal',
    border = 'single',
    focusable = false,
  })

  state.preview_winid = vim.api.nvim_open_win(state.preview_bufnr, false, {
    relative = 'win',
    win = state.prompt_winid,
    row = 0,
    col = 0,
    width = 1,
    height = 1,

    style = 'minimal',
    border = 'single',
    focusable = false,
  })

  vim.api.nvim_set_option_value('winhighlight', 'NormalFloat:Normal', { win = state.prompt_winid })
  vim.api.nvim_set_option_value('winhighlight', 'NormalFloat:Normal', { win = state.list_winid })
  vim.api.nvim_set_option_value('winhighlight', 'NormalFloat:Normal', { win = state.preview_winid })
  vim.api.nvim_set_option_value('scrolloff', 999, { win = state.preview_winid })

  resize()
  update_list()
  select_item(preselect)
  vim.cmd.startinsert()
end

local prev_item = function()
  local row = vim.api.nvim_win_get_cursor(state.list_winid)[1]
  if row == nil then
    return
  end

  if row == 1 then
    row = vim.api.nvim_buf_line_count(state.list_bufnr)
  else
    row = row - 1
  end

  select_item(row)
end

local next_item = function()
  local row = vim.api.nvim_win_get_cursor(state.list_winid)[1]
  if row == nil then
    return
  end

  if row == vim.api.nvim_buf_line_count(state.list_bufnr) then
    row = 1
  else
    row = row + 1
  end

  select_item(row)
end

vim.api.nvim_create_autocmd({ 'TextChanged', 'TextChangedI' }, {
  group = augroup,
  buffer = state.prompt_bufnr,
  desc = 'Update the picker items window whenever there is input on the prompt',
  callback = function()
    update_list()
    select_item(1)
  end,
})

vim.api.nvim_create_autocmd('WinLeave', {
  group = augroup,
  buffer = state.prompt_bufnr,
  desc = 'Close all picker component windows when prompt window is left',
  callback = close_picker,
})

vim.api.nvim_create_autocmd('VimResized', {
  group = augroup,
  buffer = state.prompt_bufnr,
  desc = 'Resize picker component windows when Vim resizes',
  callback = vim.schedule_wrap(resize),
})

vim.keymap.set({ 'i', 'n' }, '<Up>', prev_item, { buffer = state.prompt_bufnr })
vim.keymap.set({ 'i', 'n' }, '<Down>', next_item, { buffer = state.prompt_bufnr })
vim.keymap.set('n', '<Esc>', close_picker, { buffer = state.prompt_bufnr })

vim.ui.select = open_picker

vim.keymap.set('n', '<leader>e', function()
  local result = vim.system({ 'fd', '--type', 'file' }, { text = true }):wait().stdout or ''
  local items = vim.split(result, '\n', { trimempty = true })
  vim.ui.select(
    items,
    {
      prompt = 'Files',
      kind = 'files',
    },
    vim.cmd.edit
  )
end)

vim.keymap.set('n', '<leader>b', function()
  local items = vim.iter(vim.api.nvim_list_bufs()):filter(function(buf) return vim.fn.buflisted(buf) == 1 end):totable()
  vim.ui.select(
    items,
    {
      prompt = 'Buffers',
      kind = 'buffers',
      format_item = vim.fn.bufname,
    },
    vim.api.nvim_set_current_buf
  )
end)

vim.g.loaded_picker = 1
