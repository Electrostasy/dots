-- Global statusline
vim.opt.laststatus = 3
vim.opt.fillchars:append({
  -- NOTE: Horizontal window separator should be removed when/if #20492 gets
  -- implemented, until then there's two horizontal separators (winbar)
  horiz = '━',
  horizup = '┻',
  horizdown = '┳',
  vert = '┃',
  vertleft = '┨',
  vertright = '┣',
  verthoriz = '╋',
})

-- Prefer showing search count in statusline component
vim.opt.shortmess:append('S')

-- Hide the command line
vim.opt.cmdheight = 0

-- Includes
local colours = require('kanagawa.colors').setup()
local theme = require('kanagawa.themes').default(colours)
local conditions = require('heirline.conditions')
local hutils = require('heirline.utils')
local utils = require('plugins.heirline.utils')

local palette = utils.palette

local highlights = {
  StatusLine = { fg = colours.sumiInk4, bg = colours.sumiInk0 },
  WinBar = { link = 'StatusLine' },
  WinBarNC = { link = 'StatusLine' },
}
for name, opts in pairs(highlights) do
  vim.api.nvim_set_hl(0, name, opts)
end

-- Components
local Alignment_Component = { provider = '%=' }

local Spacer_Component = { provider = ' ' }

local Mode_Component = {
  static = {
    mode_names = {
      n = 'Normal',
      no = 'Normal',
      nov = 'Normal',
      noV = 'Normal',
      ['no\22'] = 'Normal',
      niI = 'Normal',
      niR = 'Normal',
      niV = 'Normal',
      nt = 'Normal',
      v = 'Visual',
      vs = 'Visual',
      V = 'V-Line',
      Vs = 'V-Line',
      ['\22'] = 'V-Block',
      ['\22ss'] = 'V-Block',
      s = 'Select',
      S = 'Select',
      ['\19'] = 'Select',
      i = 'Insert',
      ic = 'Insert',
      ix = 'Insert',
      R = 'Replace',
      Rc = 'Replace',
      Rx = 'Replace',
      Rv = 'V-Replace',
      Rvc = 'V-Replace',
      Rvx = 'V-Replace',
      c = 'Command',
      cv = 'Ex-Command',
      r = 'Prompt',
      rm = 'More Prompt',
      ['r?'] = 'Confirm',
      ['!'] = 'Shell',
      t = 'Terminal',
    },
  },

  init = function(self)
    self.mode_name = self.mode_names[vim.api.nvim_get_mode().mode]
  end,
  provider = function(self) return ' ' .. self.mode_name .. ' ' end,
  hl = function(self)
    return { fg = palette.modules.bg, bg = self:get_mode_colour() }
  end
}

local Additions_Component = {
  condition = function()
    return vim.b.gitsigns_status_dict.added ~= 0
  end,
  provider = function()
    local count = vim.b.gitsigns_status_dict.added or 0
    return count > 0 and ' +' .. count .. ' '
  end,
  hl = { fg = palette.git.additions.fg, bg = palette.git.additions.bg },
}

local Removals_Component = {
  condition = function()
    return vim.b.gitsigns_status_dict.removed ~= 0
  end,
  provider = function()
    local count = vim.b.gitsigns_status_dict.removed or 0
    return count > 0 and ' +' .. count .. ' '
  end,
  hl = { fg = palette.git.removals.fg, bg = palette.git.removals.bg },
}

local Changes_Component = {
  condition = function()
    return vim.b.gitsigns_status_dict.changed ~= 0
  end,
  provider = function()
    local count = vim.b.gitsigns_status_dict.changed or 0
    return count > 0 and ' +' .. count .. ' '
  end,
  hl = { fg = palette.git.changes.fg, bg = palette.git.changes.bg },
}

local Branch_Component = {
  provider = function()
    return vim.b.gitsigns_status_dict.head ~= '' and vim.b.gitsigns_status_dict.head
  end,
  hl = function(self)
    return { fg = self:get_mode_colour(), bg = palette.git.branch.fg }
  end,
}

local Git_Component = {
  condition = conditions.is_git_repo,
  static = { status = vim.b.gitsigns_status_dict },
  hl = { bg = palette.modules.bg },

  Additions_Component,
  Removals_Component,
  Changes_Component,
  Spacer_Component,
  Branch_Component,
  Spacer_Component,
  {
    provider = '  ',
    hl = function(self)
      return { fg = palette.git.branch.fg, bg = self:get_mode_colour() }
    end
  },
  Spacer_Component,
}

local Buffertype_Component = {
  init = function(self)
    self.is_readonly = (not vim.bo.modifiable) or vim.bo.readonly
    self.is_modified = vim.bo.modified

    if self.is_readonly then
      self.fg = colours.winterRed
      self.bg = colours.samuraiRed
      self.buftext = ' RO '
      return
    end

    if self.is_modified then
      self.fg = colours.winterYellow
      self.bg = colours.autumnYellow
      self.buftext = ' MO '
      return
    end

    self.fg = palette.modules.bg
    self.bg = self:get_mode_colour()
    self.buftext = ' RW '
  end,
  provider = function(self) return self.buftext end,
  hl = function(self)
    return { fg = self.fg, bg = self.bg }
  end
}

local Filetype_Component = {
  static = { devicons = require('nvim-web-devicons') },
  init = function(self)
    local name = vim.api.nvim_buf_get_name(0)
    local ext = vim.fn.fnamemodify(name, ':e')

    if not self.devicons.has_loaded() then
      self.devicons.setup()
    end

    self.icon, self.color = self.devicons.get_icon_color(name, ext, { default = true })
  end,
  provider = function(self) return self.icon end,
  hl = function(self) return { fg = self.color } end,
}

local Filename_Component = {
  -- Because I hate vim.fn.pathshorten path representation, in the case that
  -- there are multiple windows open with matching buffer tail names, loop
  -- through all open windows for matches and display either a full path to
  -- the buffer, just the filename, or the path beginning with the closest
  -- shared directory.

  -- In practice, given two windows in four example scenarios, we see the
  -- following buffer names:
  -- 1) Two different windows:
  --    a) init.lua
  --    b) default.nix
  -- 2) Buffer names match, but parent directories don't, for e.g.
  --    system/{audio,common}/default.nix:
  --    a) audio/default.nix
  --    b) common/default.nix
  -- 3) Buffer names and some parent directories match, for e.g.
  --    profiles/{user,system}/.../default.nix:
  --    a) user/zathura/default.nix
  --    b) system/login-manager/default.nix
  -- 4) Buffer names match, but paths don't share a common directory:
  --    a) /etc/nixos/profiles/user/neovim/lua/init.lua
  --    b) /home/electro/.config/nvim/init.lua
  static = { sep = package.config:sub(1,1) },
  init = function(self)
    self.buf = vim.api.nvim_get_current_buf()
  end,
  provider = function(self)
    if self.name == '' then
      return '[No Name]'
    end

    local name_tail = vim.fn.fnamemodify(self.name, ':t')
    local windows = vim.api.nvim_list_wins()
    if #windows == 1 then
      return name_tail
    end

    -- Split the current buffer name by path separator and note groups count
    local self_elements = vim.split(self.name, self.sep)
    if self_elements[1] == '' then
      self_elements = vim.list_slice(self_elements, 2, #self_elements - 1)
    end
    local self_elems_count = #self_elements

    for _, win in ipairs(windows) do
      local buf = vim.api.nvim_win_get_buf(win)
      if buf ~= self.buf then
        local buf_name = vim.api.nvim_buf_get_name(buf)
        local buf_name_tail = vim.fn.fnamemodify(buf_name, ':t')

        if name_tail ~= buf_name_tail then
          return name_tail
        end

        -- Split the window buffer name by path separator and note groups count
        local buf_elements = vim.split(buf_name, self.sep)
        if buf_elements[1] == '' then
          buf_elements = vim.list_slice(buf_elements, 2, #buf_elements - 1)
        end
        local buf_elems_count = #buf_elements

        -- Iterate through paths backwards until a match is found
        for i, _ in ipairs(self_elements) do
          local self_elem = self_elements[self_elems_count + 1 - i]

          for j, _ in ipairs(buf_elements) do
            local buf_elem = buf_elements[buf_elems_count + 1 - j]

            if i == j and self_elem == buf_elem then
              table.insert(self_elements, name_tail)
              return table.concat(
                vim.list_slice(
                  self_elements,
                  self_elems_count + 2 - i,
                  self_elems_count + 1
                ),
                self.sep
              )
            end
          end
        end
      end
    end

    return self.name
  end
}

local File_Component = {
  init = function(self)
    self.name = vim.api.nvim_buf_get_name(0)
  end,
  hl = function(self)
    return { fg = self:get_mode_colour(), bg = palette.modules.bg }
  end,

  Spacer_Component,
  Buffertype_Component,
  Spacer_Component,
  Filename_Component,
  Spacer_Component,
  Filetype_Component,
  Spacer_Component
}

local Diagnosed_Errors_Component = {
  init = function(self)
    self.count = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.ERROR })
  end,
  provider = function(self)
    return self.count > 0 and ('  ' .. self.count .. ' ')
  end,
  hl = hutils.get_highlight('DiagnosticVirtualTextError'),
}

local Diagnosed_Warnings_Component = {
  init = function(self)
    self.count = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.WARN })
  end,
  provider = function(self)
    return self.count > 0 and ('  ' .. self.count .. ' ')
  end,
  hl = hutils.get_highlight('DiagnosticVirtualTextWarn'),
}

local Diagnosed_Infos_Component = {
  init = function(self)
    self.count = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.INFO })
  end,
  provider = function(self)
    return self.count > 0 and ('  ' .. self.count .. ' ')
  end,
  hl = hutils.get_highlight('DiagnosticVirtualTextInfo'),
}

local Diagnosed_Hints_Component = {
  init = function(self)
    self.count = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.HINT })
  end,
  provider = function(self)
    return self.count > 0 and ('  ' .. self.count .. ' ')
  end,
  hl = hutils.get_highlight('DiagnosticVirtualTextHint'),
}

local Diagnostics_Component = {
  condition = conditions.has_diagnostics,

  Diagnosed_Errors_Component,
  Diagnosed_Hints_Component,
  Diagnosed_Infos_Component,
  Diagnosed_Warnings_Component,
}

local Lsp_Component = {
  condition = conditions.lsp_attached,
  init = function(self)
    local servers = {}
    for _, server in pairs(vim.lsp.buf_get_clients(0)) do
      if server.name ~= 'null-ls' then
        table.insert(servers, server.name)
      end
    end

    self.attached_servers = ' ' .. table.concat(servers, ', ')
  end,
  provider = function(self)
    return self.attached_servers
  end,
  hl = function(self)
    return { fg = self:get_mode_colour(), bg = palette.modules.bg }
  end,

  Spacer_Component,
  {
    provider = '  ',
    hl = function(self)
      return { fg = palette.modules.bg, bg = self:get_mode_colour() }
    end
  },
}

local Format_Component = {
  provider = vim.bo.fileformat,
  hl = { fg = theme.bg_light2, bg = palette.modules.bg }
}

local Ruler_Component = {
  { provider = 'L%l:C%c' },
}

local Encoding_Component = {
  provider = (vim.bo.fenc ~= '' and vim.bo.fenc) or vim.o.enc
}

local Indents_Component = {
  provider = function()
    local indent = vim.o.tabstop
    local indent_by = vim.o.shiftwidth

    local tabs_or_spaces = indent .. ' ' .. (vim.o.expandtab and 'spaces' or 'tabs')
    local indent_increase = indent ~= indent_by and 'sw=' .. indent_by or ''

    return tabs_or_spaces .. ' ' .. indent_increase
  end,
  hl = { fg = theme.bg_light2, bg = palette.modules.bg }
}

local Searchcount_Component = {
  condition = function()
    local highlight_searches = vim.v.hlsearch == 0
    local show_in_cmdline = vim.opt.shortmess:get().S or false
    return not highlight_searches or not show_in_cmdline
  end,
  init = function(self)
    local ok, count = pcall(vim.fn.searchcount, { recompute = true })
    if not ok or count.current == nil or count.total == 0 then
      self.count = ''
    end

    if count.incomplete == 1 then
      self.count = '?/?'
    end

    local too_many = ('>%d'):format(count.maxcount)
    local current = count.current > count.maxcount and too_many or count.current
    local total = count.total > count.maxcount and too_many or count.total
    self.count = ('%s/%s'):format(current, total)
  end,
  provider = function(self)
    return '  ' .. self.count
  end
}

local shared_static = {
  mode_colours = {
    n = theme.sm,
    i = theme.git.changed,
    v = theme.sp,
    V = theme.sp,
    ["\22"] = theme.sp,
    c = theme.sp3,
    s = theme.sp,
    S = theme.sp,
    ["\19"] = theme.sp,
    r = theme.git.changed,
    R = theme.git.changed,
    ["!"] = theme.git.removed,
    t = theme.fg_dark
  },
  get_mode_colour = function(self)
    return self.mode_colours[
      conditions.is_active() and vim.fn.mode() or 'n'
    ]
  end
}

local StatusLine = {
  static = shared_static,

  Spacer_Component,
  Mode_Component,
  Spacer_Component,
  Format_Component,
  Spacer_Component,
  Indents_Component,

  Alignment_Component,
  Diagnostics_Component,
  Lsp_Component,
  Spacer_Component,
}

local WinBar = {
  static = shared_static,

  File_Component,
  Spacer_Component,
  Encoding_Component,
  Spacer_Component,
  Searchcount_Component,

  Alignment_Component,
  Ruler_Component,
  Spacer_Component,
  Git_Component,
}

require('heirline').setup(StatusLine, WinBar)
