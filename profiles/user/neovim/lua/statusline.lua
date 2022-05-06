local conditions = require('heirline.conditions')
local utils = require('heirline.utils')
local colours = require('kanagawa.colors').setup()

-- Global statusline
vim.opt.laststatus = 3
vim.opt.fillchars:append({
  horiz = '━',
  horizup = '┻',
  horizdown = '┳',
  vert = '┃',
  vertleft = '┨',
  vertright = '┣',
  verthoriz = '╋',
})

local statusline_colours = {
  modules = {
    fg = colours.fujiWhite, bg = colours.sumiInk0
  },
  git = {
    additions = { fg = colours.autumnGreen, bg = colours.winterGreen },
    removals = { fg = colours.autumnRed, bg = colours.winterRed },
    changes = { fg = colours.autumnYellow, bg = colours.winterYellow },
    branch = { fg = colours.sumiInk0, bg = colours.autumnGreen },
  },
}

local separators = {
  block = '█',
  slant_left_up = '',
  slant_left_down = '',
  slant_right_up = '',
  slant_right_down = ''
}

local mode = {
  static = {
    mode_names = {
      n = "Normal",
      no = "Normal",
      nov = "Normal",
      noV = "Normal",
      ["no\22"] = "Normal",
      niI = "Normal",
      niR = "Normal",
      niV = "Normal",
      nt = "Normal",
      v = "Visual",
      vs = "Visual",
      V = "V-Line",
      Vs = "V-Line",
      ["\22"] = "V-Block",
      ["\22ss"] = "V-Block",
      s = "Select",
      S = "Select",
      ["\19"] = "Select",
      i = "Insert",
      ic = "Insert",
      ix = "Insert",
      R = "Replace",
      Rc = "Replace",
      Rx = "Replace",
      Rv = "V-Replace",
      Rvc = "V-Replace",
      Rvx = "V-Replace",
      c = "Command",
      cv = "Ex-Command",
      r = "Prompt",
      rm = "More Prompt",
      ["r?"] = "Confirm",
      ["!"] = "Shell",
      t = "Terminal",
    },
    mode_colours = {
      n = colours.fujiWhite,
      i = colours.autumnYellow,
      v = colours.springBlue,
      V = colours.springBlue,
      ["\22"] = colours.springBlue,
      c = colours.surimiOrange,
      s = colours.waveBlue2,
      S = colours.waveBlue2,
      ["\19"] = colours.springBlue,
      r = colours.springGreen,
      R = colours.springGreen,
      ["!"] = colours.peachRed,
      t = colours.peachRed
    }
  },

  init = function(self)
    self.mode = vim.fn.mode()
    self.mode_name = self.mode_names[self.mode]
    self.mode_colour = self.mode_colours[self.mode]
  end,

  utils.surround(
    { '', separators.slant_right_down },
    function(self) return self.mode_colour end,
    {
      provider = function(self)
        return ' ' .. self.mode_name .. ' '
      end,
      hl = { fg = statusline_colours.modules.bg, bold = true }
    }
  )
}

local git = {
  condition = conditions.is_git_repo,

  init = function(self)
    self.status_dict = vim.b.gitsigns_status_dict
    if self.status_dict.head == '' then
      self.status_dict.head = 'master'
    end
    self.has_additions = self.status_dict.added ~= 0
    self.has_removals = self.status_dict.removed ~= 0
    self.has_changes = self.status_dict.changed ~= 0
  end,

  { -- Additions
    condition = function(self) return self.has_additions end,

    { -- Separator
      provider = separators.slant_left_down,
      hl = { fg = statusline_colours.git.additions.bg, bg = statusline_colours.modules.bg },
    },
    { -- Text
      provider = function(self)
        local count = self.status_dict.added or 0
        return count > 0 and ' +' .. count .. ' '
      end,
      hl = { fg = statusline_colours.git.additions.fg, bg = statusline_colours.git.additions.bg },
    },
    { -- Separator
      condition = function(self)
        return not (self.has_changes or self.has_removals)
      end,
      provider = separators.slant_right_up,
      hl = { fg = statusline_colours.git.additions.bg, bg = statusline_colours.modules.bg },
    },
  },

  { -- Removals
    condition = function(self) return self.has_removals end,
    init = function(self)
      self.front_bg = statusline_colours.modules.bg
      if self.has_additions then
        self.front_bg = statusline_colours.git.additions.bg
      end
    end,

    { -- Separator
      provider = separators.slant_right_up,
      hl = function(self) return { fg = self.front_bg, bg = statusline_colours.git.removals.bg } end,
    },
    { -- Text
      provider = function(self)
        local count = self.status_dict.removed or 0
        return count > 0 and ' -' .. count .. ' '
      end,
      hl = { fg = statusline_colours.git.removals.fg, bg = statusline_colours.git.removals.bg },
    },
    { -- Separator
      condition = function(self)
        return not self.has_changes
      end,
      provider = separators.slant_right_up,
      hl = { fg = statusline_colours.git.removals.bg, bg = statusline_colours.modules.bg },
    },
  },

  { -- Changes
    condition = function(self) return self.has_changes end,
    init = function(self)
      self.front_bg = statusline_colours.modules.bg
      if self.has_removals then
        self.front_bg = statusline_colours.git.removals.bg
      elseif self.has_additions then
        self.front_bg = statusline_colours.git.additions.bg
      end
    end,

    { -- Separator
      provider = separators.slant_right_up,
      hl = function(self) return { fg = self.front_bg, bg = statusline_colours.git.changes.bg } end,
    },
    { -- Text
      provider = function(self)
        local count = self.status_dict.changed or 0
        return count > 0 and ' ~' .. count .. ' '
      end,
      hl = { fg = statusline_colours.git.changes.fg, bg = statusline_colours.git.changes.bg },
    },
    { -- Separator
      provider = separators.slant_right_up,
      hl = { fg = statusline_colours.git.changes.bg, bg = statusline_colours.modules.bg },
    },
  },

  { -- Branch
    { -- Separator
      provider = separators.slant_right_up,
      hl = function(self) return { fg = statusline_colours.modules.bg, bg = self.mode_colour } end
    },
    { -- Text
      provider = function(self)
        return ' ' .. self.status_dict.head .. '  '
      end,
      hl = function(self) return { fg = statusline_colours.git.branch.fg, bg = self.mode_colour, bold = true } end
    },
  },
}


local file_name = {
  static = { devicons = require('nvim-web-devicons') },
  init = function(self)
    self.full_path = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":p:~:.")
    if self.full_path == '' then
      self.file_name = '[No Name]'
    else
      self.file_name = vim.fn.fnamemodify(self.full_path, ":t")
    end
    self.parent_dir = vim.fn.fnamemodify(self.full_path, ":h")

    if not self.devicons.has_loaded() then
      self.devicons.setup({})
    end
    local name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":t")
    local extension = vim.fn.fnamemodify(name, ":e")
    self.icon, self.icon_colour = self.devicons.get_icon_color(name, extension, { default = true })
  end,

  { -- Readonly indicator
    condition = function() return (not vim.bo.modifiable) or vim.bo.readonly end,
    {
      provider = separators.slant_left_up,
      hl = { fg = colours.autumnRed, bg = statusline_colours.modules.bg }
    },
    {
      provider = '  ',
      hl = { fg = colours.sumiInk0, bg = colours.autumnRed, bold = true }
    },
    {
      provider = separators.slant_right_down,
      hl = { fg = colours.autumnRed, bg = colours.winterRed }
    },
    { -- Path (modified)
      provider = function(self)
        local shortened_path = (function()
          if not conditions.width_percent_below(#self.full_path, 0.5) then
            return vim.fn.pathshorten(self.parent_dir)
          else
            return self.parent_dir
          end
        end)()
        return ' ' .. shortened_path .. '/'
      end,
      hl = { fg = colours.autumnRed, bg = colours.winterRed }
    },
    { -- Filename (modified)
      provider = function(self) return self.file_name .. ' ' end,
      hl = { fg = colours.autumnRed, bg = colours.winterRed, bold = true }
    },
    { -- Icon (modified)
      provider = function(self) return self.icon .. ' ' end,
      hl = function(self) return { fg = self.icon_colour, bg = colours.winterRed } end,
    },
    {
      provider = separators.slant_right_down,
      hl = { fg = colours.winterRed, bg = statusline_colours.modules.bg }
    },
  },
  { -- Modified indicator
    condition = function() return vim.bo.modified end,
    {
      provider = separators.slant_left_up,
      hl = { fg = colours.autumnYellow, bg = statusline_colours.modules.bg }
    },
    {
      provider = '[+]',
      hl = { fg = colours.sumiInk0, bg = colours.autumnYellow, bold = true }
    },
    {
      provider = separators.slant_left_up,
      hl = { fg = colours.winterYellow, bg = colours.autumnYellow }
    },
    { -- Path (modified)
      provider = function(self)
        local shortened_path = (function()
          if not conditions.width_percent_below(#self.full_path, 0.5) then
            return vim.fn.pathshorten(self.parent_dir)
          else
            return self.parent_dir
          end
        end)()
        return ' ' .. shortened_path .. '/'
      end,
      hl = { fg = colours.autumnYellow, bg = colours.winterYellow }
    },
    { -- Filename (modified)
      provider = function(self) return self.file_name .. ' ' end,
      hl = { fg = colours.autumnYellow, bg = colours.winterYellow, bold = true }
    },
    { -- Icon (modified)
      provider = function(self) return self.icon .. ' ' end,
      hl = function(self) return { fg = self.icon_colour, bg = colours.winterYellow } end,
    },
    {
      provider = separators.slant_right_down,
      hl = { fg = colours.winterYellow, bg = statusline_colours.modules.bg }
    },
  },
  { -- Unmodified indicator
    condition = function()
      return (not vim.bo.modified) and not (vim.bo.readonly or not vim.bo.modifiable)
    end,

    {
      provider = separators.slant_left_up,
      hl = { fg = colours.sumiInk0, bg = statusline_colours.modules.bg }
    },
    { -- Path (modified)
      init = function(self)
        if not conditions.width_percent_below(#self.full_path, 0.5) then
          self.shortened_path = vim.fn.pathshorten(self.parent_dir)
        else
          self.shortened_path = self.parent_dir
        end
      end,

      provider = function(self)
        return ' ' .. self.shortened_path .. '/'
      end,
      hl = function(self) return { fg = self.mode_colour, bg = colours.sumiInk0 } end
    },
    { -- Filename
      provider = function(self) return self.file_name .. ' ' end,
      hl = function(self) return { fg = self.mode_colour, bg = colours.sumiInk0, bold = true } end
    },
    { -- Icon
      provider = function(self) return self.icon .. ' ' end,
      hl = function(self) return { fg = self.icon_colour, bg = colours.sumiInk0 } end,
    },
    {
      provider = separators.slant_right_down,
      hl = { fg = colours.sumiInk0, bg = statusline_colours.modules.bg }
    },

  },
}
-- file_name component depends on the current mode colour, so make it part of
-- mode
table.insert(mode, file_name)

local lsp_diagnostics = {
  condition = conditions.has_diagnostics,

  static = {
    error_icon = '',
    warn_icon = '',
    info_icon = '',
    hint_icon = '',
  },

  init = function(self)
    self.errors = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.ERROR })
    self.warnings = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.WARN })
    self.hints = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.HINT })
    self.info = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.INFO })
  end,

  {
    provider = separators.slant_left_down,
    hl = { fg = colours.sumiInk0, bg = statusline_colours.modules.bg }
  },
  {
    provider = function(self)
      return self.errors > 0 and (' ' .. self.error_icon .. ' ' .. self.errors .. ' ')
    end,
    hl = { fg = colours.autumnRed, bg = colours.sumiInk0 },
  },
  {
    provider = function(self)
      return self.warnings > 0 and (' ' .. self.warn_icon .. ' ' .. self.warnings .. ' ')
    end,
    hl = { fg = colours.autumnYellow, bg = colours.sumiInk0 },
  },
  {
    provider = function(self)
      return self.info > 0 and (' ' .. self.info_icon .. ' ' .. self.info .. ' ')
    end,
    hl = { fg = colours.waveAqua1, bg = colours.sumiInk0 },
  },
  {
    provider = function(self)
      return self.hints > 0 and (' ' .. self.hint_icon .. ' ' .. self.hints .. ' ')
    end,
    hl = { fg = colours.dragonBlue, bg = colours.sumiInk0 },
  },
  {
    provider = separators.slant_right_up,
    hl = { fg = colours.sumiInk0, bg = statusline_colours.modules.bg }
  },
}

local encoding = {
  provider = (vim.bo.fenc ~= '' and vim.bo.fenc) or vim.o.enc,
  hl = { fg = colours.sumiInk4, bg = statusline_colours.modules.bg }
}

local ruler = {
  provider = '%c',
  hl = { fg = colours.sumiInk4, bg = statusline_colours.modules.bg }
}

local right_align = { provider = '%=' }
local space = { provider = ' ' }

local nested_components = {
  space, encoding, right_align, space, ruler, space, lsp_diagnostics
}
for _, component in ipairs(nested_components) do
  table.insert(mode, component)
end
table.insert(mode, git)

require('heirline').setup({
  --stop_at_first = true,

  mode
})

