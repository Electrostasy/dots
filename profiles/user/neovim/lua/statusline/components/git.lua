local conditions = require('heirline.conditions')
local utils = require('statusline.utils')

local slants = utils.separators.slant
local palette = utils.palette

return {
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

  {
    -- This component displays the number of additions tracked by git.
    condition = function(self) return self.has_additions end,

    {
      provider = slants.ld,
      hl = { fg = palette.git.additions.bg, bg = palette.modules.bg },
    },
    {
      provider = function(self)
        local count = self.status_dict.added or 0
        return count > 0 and ' +' .. count .. ' '
      end,
      hl = { fg = palette.git.additions.fg, bg = palette.git.additions.bg },
    },
    {
      condition = function(self)
        return not (self.has_changes or self.has_removals)
      end,
      provider = slants.ru,
      hl = { fg = palette.git.additions.bg, bg = palette.modules.bg },
    },
  },

  {
    -- This component displays the number of removals tracked by git.
    condition = function(self) return self.has_removals end,
    init = function(self)
      self.front_bg = palette.modules.bg
      if self.has_additions then
        self.front_bg = palette.git.additions.bg
      end
    end,

    {
      provider = slants.ru,
      hl = function(self) return { fg = self.front_bg, bg = palette.git.removals.bg } end,
    },
    {
      provider = function(self)
        local count = self.status_dict.removed or 0
        return count > 0 and ' -' .. count .. ' '
      end,
      hl = { fg = palette.git.removals.fg, bg = palette.git.removals.bg },
    },
    {
      condition = function(self)
        return not self.has_changes
      end,
      provider = slants.ru,
      hl = { fg = palette.git.removals.bg, bg = palette.modules.bg },
    },
  },

  {
    -- This component displays the number of changes tracked by git.
    condition = function(self) return self.has_changes end,
    init = function(self)
      self.front_bg = palette.modules.bg
      if self.has_removals then
        self.front_bg = palette.git.removals.bg
      elseif self.has_additions then
        self.front_bg = palette.git.additions.bg
      end
    end,

    {
      provider = slants.ru,
      hl = function(self) return { fg = self.front_bg, bg = palette.git.changes.bg } end,
    },
    {
      provider = function(self)
        local count = self.status_dict.changed or 0
        return count > 0 and ' ~' .. count .. ' '
      end,
      hl = { fg = palette.git.changes.fg, bg = palette.git.changes.bg },
    },
    {
      provider = slants.ru,
      hl = { fg = palette.git.changes.bg, bg = palette.modules.bg },
    },
  },

  {
    -- This component displays the currently active git branch.
    {
      provider = slants.ru,
      hl = function(self) return { fg = palette.modules.bg, bg = self.mode_colour } end
    },
    {
      provider = function(self)
        return ' ' .. self.status_dict.head .. '  '
      end,
      hl = function(self) return { fg = palette.git.branch.fg, bg = self.mode_colour, bold = true } end
    },
  },
}
