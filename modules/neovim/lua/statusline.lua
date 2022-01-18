local conditions = require('heirline.conditions')
local utils = require('heirline.utils')
local colours = require('kanagawa.colors').setup()

local separators = {
  block = '█',
  slant_left_up = '',
  slant_left_down = '',
  slant_right_up = '',
  slant_right_down = ''
}

local mode = {
  init = function(self)
    self.mode = vim.fn.mode()
  end,

  static = {
    names = {
      n = "Normal",
      no = "Normal?",
      nov = "Normal?",
      noV = "Normal?",
      ["no^V"] = "Normal?",
      niI = "Normal Insert",
      niR = "Normal Replace",
      niV = "Normal V-Replace",
      nt = "Normal",
      v = "Visual",
      vs = "Visual",
      V = "V-Line",
      Vs = "V-Line",
      [""] = "V-Block",
      ["s"] = "V-Block",
      s = "Select",
      S = "Select Line",
      [""] = "Select Block",
      i = "Insert",
      ic = "Insert Complete",
      ix = "Insert Complete",
      R = "Replace",
      Rc = "Replace Complete",
      Rx = "Replace Complete",
      Rv = "V-Replace",
      Rvc = "V-Replace Complete",
      Rvx = "V-Replace Complete",
      c = "Command",
      cv = "Ex-Command",
      r = "Prompt",
      rm = "More Prompt",
      ["r?"] = "Confirm",
      ["!"] = "Shell",
      t = "Terminal",
    },
    colours = {
      n = colours.oniViolet,
      i = colours.autumnYellow,
      v = colours.springBlue,
      V = colours.springBlue,
      [""] = colours.springBlue,
      c = colours.peachRed,
      s = colours.springBlue,
      S = colours.springBlue,
      [""] = colours.springBlue,
      r = colours.springGreen,
      R = colours.springGreen,
      ["!"] = colours.peachRed,
      t = colours.katanaGray
    },
  },

  { -- Mode text
    provider = function(self) return ' ' .. self.names[self.mode] .. ' ' end,
    hl = function(self)
      return { fg = colours.sumiInk0, bg = self.colours[self.mode], style = 'bold' }
    end
  },
  { -- End separator
    provider = separators.slant_right_down,
    hl = function(self) return { fg = self.colours[self.mode], bg = colours.sumiInk0 } end
  }
}

local statusline_colours = {
  git = {
    additions = { fg = colours.autumnGreen, bg = colours.winterGreen },
    removals = { fg = colours.autumnRed, bg = colours.winterRed },
    changes = { fg = colours.autumnYellow, bg = colours.winterYellow },
    branch = { fg = colours.sumiInk0, bg = colours.autumnGreen },
  },
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
    self.is_modified = self.has_additions or self.has_removals or self.has_changes
  end,

  -- Before and after every component is a separator.
  -- If it's the last component, put the last separator after it
  -- Otherwise, continue with the other components
  { -- Additions separator
    condition = function(self) return self.is_modified and self.has_additions end,
    provider = separators.slant_left_down,
    hl = { fg = statusline_colours.git.additions.bg, bg = colours.sumiInk0 }
  },
  { -- Additions
    provider = function(self)
      local count = self.status_dict.added or 0
      return count > 0 and '+' .. count
    end,
    hl = { fg = statusline_colours.git.additions.fg, bg = statusline_colours.git.additions.bg },
  },
  { -- Additions/branch separator
    condition = function(self) return self.is_modified and self.has_additions and not self.has_removals and not self.has_changes end,
    provider = separators.slant_right_up,
    hl = { fg = statusline_colours.git.additions.bg, bg = statusline_colours.git.branch.bg }
  },
  { -- Additions/removals separator
    condition = function(self) return self.is_modified and self.has_additions and self.has_removals end,
    provider = separators.slant_right_up,
    hl = { fg = statusline_colours.git.additions.bg, bg = statusline_colours.git.removals.bg }
  },
  { -- Additions/changes separator
    condition = function(self) return self.is_modified and self.has_additions and (not self.has_removals) and self.has_changes end,
    provider = separators.slant_right_up,
    hl = { fg = statusline_colours.git.additions.bg, bg = statusline_colours.git.changes.bg }
  },
  { -- Removals separator
    condition = function(self) return self.is_modified and self.has_removals and not self.has_additions end,
    provider = separators.slant_left_down,
    hl = { fg = statusline_colours.git.removals.bg, bg = colours.sumiInk0 }
  },
  { -- Removals
    provider = function(self)
      local count = self.status_dict.removed or 0
      return count > 0 and '-' .. count
    end,
    hl = { fg = statusline_colours.git.removals.fg, bg = statusline_colours.git.removals.bg },
  },
  { -- Removals/end separator
    condition = function(self)
      return self.is_modified and self.has_removals and not self.has_changes
    end,
    provider = separators.slant_left_down,
    hl = { fg = statusline_colours.git.branch.bg, bg = statusline_colours.git.removals.bg }
  },
  { -- Removals/changes separator
    condition = function(self)
      return self.is_modified and self.has_removals and self.has_changes
    end,
    provider = separators.slant_right_up,
    hl = { fg = statusline_colours.git.removals.bg, bg = statusline_colours.git.changes.bg }
  },
  { -- Changes separator
    condition = function(self)
      return self.is_modified and self.has_changes and (not self.has_removals) and (not self.has_additions)
    end,
    provider = separators.slant_left_down,
    hl = { fg = statusline_colours.git.changes.bg, bg = colours.sumiInk0 }
  },
  { -- Changes
    provider = function(self)
      local count = self.status_dict.changed or 0
      return count > 0 and '~' .. count
    end,
    hl = { fg = statusline_colours.git.changes.fg, bg = statusline_colours.git.changes.bg },
  },
  { -- Changes/end separator
    condition = function(self)
      return self.is_modified and self.has_changes
    end,
    provider = separators.slant_left_down,
    hl = { fg = statusline_colours.git.branch.bg, bg = statusline_colours.git.changes.bg }
  },
  { -- Branch name separator if no changes whatsoever
    condition = function(self)
      return (not self.has_additions) and (not self.has_removals) and (not self.has_changes)
    end,
    provider = separators.slant_left_down,
    hl = { fg = statusline_colours.git.branch.bg, bg = colours.sumiInk0 }
  },
  { -- Branch name
    provider = function(self)
      return '  ' .. self.status_dict.head .. ' '
    end,
    hl = { fg = statusline_colours.git.branch.fg, bg = statusline_colours.git.branch.bg, style = 'bold' }
  },
}

local file_name = {
  init = function(self)
    self.full_path = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":p:~:.")
    if self.full_path == '' then
      self.file_name = '[No Name]'
    else
      self.file_name = vim.fn.fnamemodify(self.full_path, ":t")
    end
    self.parent_dir = vim.fn.fnamemodify(self.full_path, ":h")
    self.shortened_path = vim.fn.pathshorten(self.parent_dir)
  end,

  { -- Readonly indicator
    condition = function() return (not vim.bo.modifiable) or vim.bo.readonly end,
    {
      provider = separators.slant_left_up,
      hl = { fg = colours.autumnRed, bg = colours.sumiInk0 }
    },
    {
      provider = '  ',
      hl = { fg = colours.sumiInk0, bg = colours.autumnRed, style = 'bold' }
    },
    {
      provider = separators.slant_right_down,
      hl = { fg = colours.autumnRed, bg = colours.winterRed }
    },
    { -- Path (modified)
      provider = function(self) return ' ' .. self.shortened_path .. '/' end,
      hl = { fg = colours.autumnRed, bg = colours.winterRed }
    },
    { -- Filename (modified)
      provider = function(self) return self.file_name .. ' ' end,
      hl = { fg = colours.autumnRed, bg = colours.winterRed, style = 'bold' }
    },
    {
      provider = separators.slant_right_down,
      hl = { fg = colours.winterRed, bg = colours.sumiInk0 }
    },
  },
  { -- Modified indicator
    condition = function() return vim.bo.modified end,
    {
      provider = separators.slant_left_up,
      hl = { fg = colours.autumnYellow, bg = colours.sumiInk0 }
    },
    {
      provider = '[+]',
      hl = { fg = colours.sumiInk0, bg = colours.autumnYellow, style = 'bold' }
    },
    {
      provider = separators.slant_left_up,
      hl = { fg = colours.winterYellow, bg = colours.autumnYellow }
    },
    { -- Path (modified)
      provider = function(self) return ' ' .. self.shortened_path .. '/' end,
      hl = { fg = colours.autumnYellow, bg = colours.winterYellow }
    },
    { -- Filename (modified)
      provider = function(self) return self.file_name .. ' ' end,
      hl = { fg = colours.autumnYellow, bg = colours.winterYellow, style = 'bold' }
    },
    {
      provider = separators.slant_right_down,
      hl = { fg = colours.winterYellow, bg = colours.sumiInk0 }
    },
  },
  { -- Unmodified indicator
    condition = function()
      local is_modified = vim.bo.modified
      local is_readonly = (not vim.bo.modifiable) or vim.bo.readonly
      return (not is_readonly) and (not is_modified)
    end,

    {
      provider = separators.slant_left_up,
      hl = { fg = colours.sumiInk2, bg = colours.sumiInk0 }
    },
    { -- Path (modified)
      provider = function(self) return ' ' .. self.shortened_path .. '/' end,
      hl = { fg = colours.fujiWhite, bg = colours.sumiInk2 }
    },
    { -- Filename (modified)
      provider = function(self) return self.file_name .. ' ' end,
      hl = { fg = colours.fujiWhite, bg = colours.sumiInk2, style = 'bold' }
    },
    {
      provider = separators.slant_right_down,
      hl = { fg = colours.sumiInk2, bg = colours.sumiInk0 }
    },
  },
}

local lsp_status = {
  condition = conditions.lsp_attached,

  {
    provider = separators.slant_left_down,
    hl = { fg = colours.sumiInk2, bg = colours.sumiInk0 }
  },
  {
    provider = function()
      local names = {}
      for _, server in ipairs(vim.lsp.buf_get_clients(0)) do
        table.insert(names, server.name)
      end
      return ' ' .. table.concat(names, ' ') .. ' '
    end,
    hl = { fg = colours.sumiInk0, bg = colours.sumiInk2 }
  },
  {
    provider = separators.slant_right_up,
    hl = { fg = colours.sumiInk2, bg = colours.sumiInk0 }
  },
}

local encoding = {
  provider = function()
    local enc = (vim.bo.fenc ~= '' and vim.bo.fenc) or vim.o.enc
    return enc ~= 'utf-8' and enc
  end,
  hl = { fg = colours.sumiInk3, bg = colours.sumiInk0 }
}

local ruler = {
  provider = ' %l:%c/%L ',
  hl = { fg = colours.sumiInk3, bg = colours.sumiInk0 }
}

local right_align = { provider = '%=' }

local active_status = {
  mode, file_name,
  right_align, encoding, ruler, lsp_status, git
}

local inactive_status = {
  condition = function() return not conditions.is_active() end,

  { provider = '[' .. vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":p:~:.") .. ']' },
  right_align, lsp_status
}

require('heirline').setup({
  stop_at_first = true,

  inactive_status,
  active_status
})

