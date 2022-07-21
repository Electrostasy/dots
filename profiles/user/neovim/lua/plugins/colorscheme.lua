local kanagawa = require('kanagawa')

local colours = require('kanagawa.colors').setup()
local theme = require('kanagawa.themes').default(colours)
local groups = require('kanagawa.hlgroups').setup(colours)

kanagawa.setup({
  globalStatus = true,
  dimInactive = true,

  overrides = {
    StatusLine = { bg = colours.sumiInk0 },
    StatusLineNC = { bg = colours.sumiInk0 },
    Whitespace = { fg = colours.sumiInk2 },
    NonText = { fg = colours.sumiInk2 },
    DiagnosticVirtualTextError = { fg = colours.samuraiRed, bg = colours.winterRed },
    DiagnosticVirtualTextWarn = { fg = colours.roninYellow, bg = colours.winterYellow },
    DiagnosticVirtualTextInfo = { fg = colours.waveAqua1, bg = colours.winterBlue },
    DiagnosticVirtualTextHint = { fg = colours.dragonBlue, bg = colours.winterBlue },
    TelescopeMatching = { fg = colours.roninYellow, bold = true },

    CursorLineNr = { bg = groups.CursorLine.bg },
    CursorLineFold = { bg = groups.CursorLine.bg },
    CursorLineSign = { bg = groups.CursorLine.bg },

    -- https://github.com/hrsh7th/nvim-cmp/pull/901
    CmpItemKindVariable = { fg = groups.Pmenu.bg, bg = colours.fujiWhite },
    CmpItemKindFunction = { fg = groups.Pmenu.bg, bg = groups.Function.fg },
    CmpItemKindMethod = { fg = groups.Pmenu.bg, bg = groups.Function.fg },
    CmpItemKindConstructor = { fg = groups.Pmenu.bg, bg = colours.oniViolet },
    CmpItemKindClass = { fg = groups.Pmenu.bg, bg = groups.Type.fg },
    CmpItemKindInterface = { fg = groups.Pmenu.bg, bg = groups.Type.fg },
    CmpItemKindStruct = { fg = groups.Pmenu.bg, bg = groups.Type.fg },
    CmpItemKindProperty = { fg = groups.Pmenu.bg, bg = groups.Identifier.fg },
    CmpItemKindField = { fg = groups.Pmenu.bg, bg = groups.Identifier.fg },
    CmpItemKindEnum = { fg = groups.Pmenu.bg, bg = groups.Identifier.fg },
    CmpItemKindSnippet = { fg = groups.Pmenu.bg, bg = colours.springBlue },
    CmpItemKindText = { fg = groups.Pmenu.bg, bg = colours.oldWhite },
    CmpItemKindModule = { fg = groups.Pmenu.bg, bg = colours.surimiOrange },
    CmpItemKindFile = { fg = groups.Pmenu.bg, bg = groups.Directory.fg },
    CmpItemKindFolder = { fg = groups.Pmenu.bg, bg = groups.Directory.fg },
    CmpItemKindKeyword = { fg = groups.Pmenu.bg, bg = groups.Keyword.fg },
    CmpItemKindTypeParameter = { fg = groups.Pmenu.bg, bg = groups.Identifier.fg },
    CmpItemKindConstant = { fg = groups.Pmenu.bg, bg = groups.Constant.fg },
    CmpItemKindOperator = { fg = groups.Pmenu.bg, bg = groups.Operator.fg },
    CmpItemKindReference = { fg = groups.Pmenu.bg, bg = groups.Identifier.fg },
    CmpItemKindEnumMember = { fg = groups.Pmenu.bg, bg = groups.Identifier.fg },
    CmpItemKindValue = { fg = groups.Pmenu.bg, bg = groups.String.fg },
  }
})

kanagawa.load()
