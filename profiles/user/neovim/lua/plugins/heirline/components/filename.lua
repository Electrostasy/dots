local conditions = require('heirline.conditions')
local utils = require('plugins.heirline.utils')
local kanagawa = require('kanagawa.colors').setup()

local slants = utils.separators.slant
local palette = utils.palette

return {
  static = { devicons = require('nvim-web-devicons') },
  init = function(self)
    -- File name
    self.full_path = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":p:~:.")
    if self.full_path == '' then
      self.file_name = '[No Name]'
    else
      self.file_name = vim.fn.fnamemodify(self.full_path, ":t")
    end
    self.parent_dir = vim.fn.fnamemodify(self.full_path, ":h")

    if not self.devicons.has_loaded() then
      self.devicons.setup()
    end

    -- Filetype icon
    local name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":t")
    local extension = vim.fn.fnamemodify(name, ":e")
    self.icon, self.icon_colour = self.devicons.get_icon_color(name, extension, { default = true })

    -- Status
    self.is_readonly = (not vim.bo.modifiable) or vim.bo.readonly
    self.is_modified = vim.bo.modified

    if self.is_readonly then
      self.fg_colour = kanagawa.autumnRed
      self.bg_colour = kanagawa.winterRed
      self.status_icon = '  '
    elseif self.is_modified then
      self.fg_colour = kanagawa.autumnYellow
      self.bg_colour = kanagawa.winterYellow
      self.status_icon = '  '
    else
      self.fg_colour = self:get_mode_colour()
      self.bg_colour = palette.modules.bg
      self.status_icon = nil -- shouldn't be accessed
    end
  end,

  {
    -- This child component displays the lock/plus symbol block in the beginning
    -- of the filename component, formatted to the modified/readonly kanagawa.
    condition = function(self) return self.is_readonly or self.is_modified end,
    {
      provider = slants.lu,
      hl = function(self)
        return { fg = self.fg_colour, bg = palette.modules.bg }
      end
    },
    {
      provider = function(self) return self.status_icon end,
      hl = function(self)
        return { fg = palette.modules.bg, bg = self.fg_colour }
      end
    },
    {
      provider = slants.rd,
      hl = function(self)
        return { fg = self.fg_colour, bg = self.bg_colour }
      end
    },
  },

  {
    -- This component displays the path, with the filename in bold
    -- and formatted to the mode or modified/readonly kanagawa.
    provider = function(self)
      local path = self.parent_dir
      if not conditions.width_percent_below(#self.full_path, 0.5) then
        path = vim.fn.pathshorten(self.parent_dir)
      end

      return ' ' .. path .. '/'
    end,
    hl = function(self) return { fg = self.fg_colour, bg = self.bg_colour } end,

    {
      provider = function(self) return self.file_name .. ' ' end,
      hl = { bold = true }
    },
    {
      provider = function(self) return self.icon .. ' ' end,
      hl = function(self) return { fg = self.icon_colour, bg = self.bg_colour } end,
    },
    {
      provider = slants.rd,
      hl = function(self) return { fg = self.bg_colour, bg = palette.modules.bg } end
    },
  },
}
