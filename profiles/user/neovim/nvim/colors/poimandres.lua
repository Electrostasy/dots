-- Edited version of:
-- https://github.com/olivercederborg/poimandres.nvim

local blend = require('util').blend

local palette = {
  yellow = '#FFFAC2',
  teal1 = '#5DE4C7',
  teal2 = '#5FB3A1',
  teal3 = '#42675A',
  blue1 = '#89DDFF',
  blue2 = '#ADD7FF',
  blue3 = '#91B4D5',
  blue4 = '#7390AA',
  pink1 = '#FAE4FC',
  pink2 = '#FCC5E9',
  pink3 = '#D0679D',
  blueGray1 = '#A6ACCD',
  blueGray2 = '#767C9D',
  blueGray3 = '#506477',
  background1 = '#303340',
  background2 = '#1B1E28',
  background3 = '#171922',
  text = '#E4F0FB',
  white = '#FFFFFF',
  none = 'NONE',
}

local groups = {}

--- :h highlight-groups
groups.builtin = {
  ColorColumn = { bg = palette.blueGray1 },
  Conceal = { bg = palette.none },
  CurSearch = { link = 'InkSearch' },
  Cursor = { fg = palette.background3, bg = palette.blueGray1 },
  -- lCurso = {},
  -- CursorIM = {},
  CursorColumn = { bg = blend(palette.background1, palette.background2, 0.5) },
  CursorLine = { link = 'CursorColumn' },
  Directory = { fg = palette.blue3, bg = palette.none },
  DiffAdd = { bg = blend(palette.teal1, palette.background2, 0.1) },
  DiffChange = { bg = blend(palette.yellow, palette.background2, 0.1) },
  DiffDelete = { bg = blend(palette.pink2, palette.background2, 0.1) },
  DiffText = { bg = blend(palette.teal1, palette.background2, 0.1) },
  -- EndOfBuffer = {},
  -- TermCursor = {},
  -- TermCursorNC = {},
  ErrorMsg = { fg = palette.pink3, bold = true },
  -- WinSeparator = {},
  Folded = { fg = palette.text, bg = palette.background3 },
  FoldColumn = { fg = palette.blueGray2 },
  SignColumn = { fg = palette.text, bg = palette.none },
  IncSearch = { fg = palette.background3, bg = palette.blue2 },
  -- Substitute = {},
  LineNr = { fg = palette.blueGray3 },
  -- LineNrAbove = {},
  -- LineNrBelow = {},
  CursorLineNr = { fg = palette.text, bg = blend(palette.background1, palette.background2, 0.5) },
  CursorLineFold = { link = 'CursorLine' },
  CursorLineSign = { link = 'CursorLine' },
  MatchParen = { bg = blend(palette.blueGray1, palette.background2, 0.25) },
  ModeMsg = { fg = palette.blue3 },
  MsgArea = { fg = palette.blue2, bg = palette.background2 },
  -- MsgSeparator = {},
  MoreMsg = { fg = palette.blue3 },
  NonText = { fg = palette.blueGray3 },
  Normal = { fg = palette.text, bg = palette.background2 },
  NormalFloat = { fg = palette.text, bg = palette.background3 },
  FloatBorder = { fg = palette.background3 },
  FloatTitle = { fg = palette.blueGray2 },
  NormalNC = { fg = palette.text, bg = palette.background3 },
  Pmenu = { fg = palette.blueGray1, bg = palette.background3 },
  PmenuSel = { fg = palette.text, bg = palette.background1 },
  -- PmenuKind = {},
  -- PmenuKindSel = {},
  -- PmenuExtra = {},
  -- PmenuExtraSel = {},
  PmenuSbar = { bg = palette.blueGray2 },
  PmenuThumb = { bg = palette.blueGray3 },
  Question = { fg = palette.yellow },
  -- QuickFixLine = {},
  Search = { fg = palette.white, bg = palette.blueGray3 },
  SpecialKey = { fg = palette.teal1 },
  SpellBad = { sp = palette.pink3, undercurl = true },
  SpellCap = { sp = palette.blue1, undercurl = true },
  SpellLocal = { sp = palette.yellow, undercurl = true },
  SpellRare = { sp = palette.blue1, undercurl = true },
  StatusLine = { fg = palette.blue3, bg = palette.background3 },
  StatusLineNC = { fg = palette.blue3, bg = palette.background2 },
  TabLine = { link = 'StatusLine' },
  TabLineFill = { bg = palette.background3 },
  TabLineSel = { fg = palette.text, bg = palette.background1 },
  Title = { fg = palette.text },
  Visual = { bg = blend(palette.blue2, palette.background2, 0.15) },
  -- VisualNOS = {},
  WarningMsg = { fg = palette.yellow },
  Whitespace = { fg = palette.blueGray3 },
  WildMenu = { link = 'InkSearch' },
  -- WinBar = {},
  -- WinBarNC = {},
}

--- Statusline highlights. :h hl-User1..9
groups.user = {
  User1 = { fg = palette.background2, bg = palette.blueGray1, bold = true }, -- Normal
  User2 = { fg = palette.background2, bg = palette.blue2, bold = true }, -- Visual
  User3 = { fg = palette.background2, bg = palette.blueGray2, bold = true }, -- Select
  User4 = { fg = palette.background2, bg = palette.yellow, bold = true }, -- Insert
  User5 = { fg = palette.background2, bg = palette.yellow, bold = true }, -- Replace
  User6 = { fg = palette.background2, bg = palette.teal1, bold = true }, -- Command
  User7 = { fg = palette.background2, bg = palette.text, bold = true }, -- Prompt/Confirm
  User8 = { fg = palette.background2, bg = palette.blue1, bold = true }, -- Shell
  User9 = { fg = palette.background2, bg = palette.blue1, bold = true }, -- Terminal
}

--- :h group-name
groups.common_syntax = {
  Comment = { fg = blend(palette.background1, palette.text, 0.85) },

  Constant = { fg = palette.blue3, bold = true },
  String = { fg = palette.yellow },
  Character = { fg = palette.pink3 },
  Number = { fg = palette.teal1 },
  Boolean = { fg = palette.teal1 },
  Float = { fg = palette.teal1 },
  Identifier = { fg = palette.blueGray1 },
  Function = { fg = palette.blue1 },

  Statement = { fg = palette.text },
  Conditional = { fg = palette.blueGray1 },
  Repeat = { fg = palette.blue3 },
  Label = { fg = palette.pink2, italic = true },
  Operator = { fg = palette.blue2 },
  Keyword = { fg = palette.blue3 },
  Exception = { fg = palette.blue3 },

  PreProc = { fg = palette.text },
  Include = { fg = palette.blueGray1 },
  -- Define = {},
  -- Macro = {},
  -- PreCondit = {},

  Type = { fg = palette.blue4 },
  -- StorageClass = {},
  -- Structure = {},
  -- Typedef = {},

  Special = { fg = palette.teal2 },
  -- SpecialChar = {},
  Tag = { fg = palette.text },
  Delimiter = { fg = palette.blue4 },
  SpecialComment = { fg = palette.bluegray1 },
  -- Debug = {},

  Underlined = { underline = true },

  -- Ignore = {},

  Error = { fg = palette.pink3 },

  Todo = { fg = palette.background3, bg = palette.yellow },
}

--- :h treesitter-highlight-groups
groups.treesitter = {
  -- ['@text.literal'] = { link = 'Comment' },
  -- ['@text.reference'] = { link = 'Identifier' },
  -- ['@text.title'] = { link = 'Title' },
  -- ['@text.uri'] = { link = 'Underlined' },
  -- ['@text.underline'] = { link = 'Underlined' },
  -- ['@text.todo'] = { link = 'Todo' },

  -- ['@comment'] = { link = 'Comment' },
  -- ['@punctuation'] = { link = 'Delimiter' },

  -- ['@constant'] = { link = 'Constant' },
  ['@constant.builtin'] = { fg = groups.common_syntax.Constant.fg, bold = true },
  -- ['@constant.macro'] = { link = 'Define' },
  -- ['@define'] = { link = 'Define' },
  -- ['@macro'] = { link = 'Macro' },
  -- ['@string'] = { link = 'String' },
  -- ['@string.escape'] = { link = 'SpecialChar' },
  -- ['@string.special'] = { link = 'SpecialChar' },
  -- ['@character'] = { link = 'Character' },
  -- ['@character.special'] = { link = 'SpecialChar' },
  -- ['@number'] = { link = 'Number' },
  -- ['@boolean'] = { link = 'Boolean' },
  -- ['@float'] = { link = 'Float' },

  -- ['@function'] = { link = 'Function' },
  -- ['@function.builtin'] = { link = 'Special' },
  -- ['@function.macro'] = { link = 'Macro' },
  ['@parameter'] = { fg = palette.text },
  -- ['@method'] = { link = 'Function' },
  -- ['@field'] = { link = 'Identifier' },
  -- ['@property'] = { link = 'Identifier' },
  ['@constructor'] = { fg = palette.blue2 },

  -- ['@conditional'] = { link = 'Conditional' },
  -- ['@repeat'] = { link = 'Repeat' },
  -- ['@label'] = { link = 'Label' },
  -- ['@operator'] = { link = 'Operator' },
  -- ['@keyword'] = { link = 'Keyword' },
  -- ['@exception'] = { link = 'Exception' },

  ['@variable'] = { fg = blend(palette.text, palette.blueGray1, 0.5) },
  -- ['@type'] = { link = 'Type' },
  -- ['@type.definition'] = { link = 'Typedef' },
  -- ['@storageclass'] = { link = 'StorageClass' },
  -- ['@structure'] = { link = 'Structure' },
  -- ['@namespace'] = { link = 'Identifier' },
  -- ['@include'] = { link = 'Include' },
  -- ['@preproc'] = { link = 'PreProc' },
  -- ['@debug'] = { link = 'Debug' },
  -- ['@tag'] = { link = 'Tag' },

  --- Other treesitter highlight groups.
  ['@type.qualifier'] = { link = 'Keyword' },
  ['@punctuation.special'] = { fg = palette.teal2 },
  ['@string.documentation'] = { link = 'Comment' },
}

groups.lsp = {
  --- :h lsp-semantic-highlight
  -- ['@lsp.type.class'] = { link = 'Structure' },
  -- ['@lsp.type.decorator'] = { link = 'Function' },
  -- ['@lsp.type.enum'] = { link = 'Structure' },
  -- ['@lsp.type.enumMember'] = { link = 'Constant' },
  -- ['@lsp.type.function'] = { link = 'Function' },
  -- ['@lsp.type.interface'] = { link = 'Structure' },
  -- ['@lsp.type.macro'] = { link = 'Macro' },
  -- ['@lsp.type.method'] = { link = 'Function' },
  -- ['@lsp.type.namespace'] = { link = 'Structure' },
  -- ['@lsp.type.parameter'] = { link = 'Identifier' },
  -- ['@lsp.type.property'] = { link = 'Identifier' },
  -- ['@lsp.type.struct'] = { link = 'Structure' },
  -- ['@lsp.type.type'] = { link = 'Type' },
  ['@lsp.type.typeParameter'] = { link = '@parameter' },
  -- ['@lsp.type.variable'] = { link = 'Identifier' },

  --- Other LSP semantic highlight groups.
  ['@lsp.type.comment'] = { link = 'Comment' },
  ['@lsp.type.parameter'] = { link = '@parameter' },
  ['@lsp.typemod.function.defaultLibrary'] = { fg = palette.teal2 },
  ['@lsp.typemod.function.global'] = { fg = palette.blue1, bold = true },
  ['@lsp.typemod.variable.defaultLibrary'] = { fg = palette.teal3 },
  ['@lsp.typemod.variable.global'] = { fg = palette.blueGray1, bold = true },
  ['@lsp.type.keyword'] = { link = 'Keyword' },

  --- :h diagnostic-highlights
  DiagnosticError = { fg = palette.pink3 },
  DiagnosticWarn = { fg = palette.yellow },
  DiagnosticInfo = { fg = palette.blue3 },
  DiagnosticHint = { fg = palette.blue1 },
  -- DiagnosticOk = {},
  DiagnosticVirtualTextError = { fg = palette.pink3, bg = blend(palette.pink3, palette.background2, 0.15), italic = true },
  DiagnosticVirtualTextWarn = { fg = palette.yellow, bg = blend(palette.yellow, palette.background2, 0.15), italic = true },
  DiagnosticVirtualTextInfo = { fg = palette.blue3, bg = blend(palette.blue3, palette.background2, 0.15), italic = true },
  DiagnosticVirtualTextHint = { fg = palette.blue1, bg = blend(palette.blue1, palette.background2, 0.15), italic = true },
  -- DiagnosticVirtualTextOk = {},
  DiagnosticUnderlineError = { sp = palette.pink3, undercurl = true },
  DiagnosticUnderlineWarn = { sp = palette.yellow, underline = true },
  DiagnosticUnderlineInfo = { sp = palette.blue3, underdotted = true },
  DiagnosticUnderlineHint = { sp = palette.blue1, underdotted = true },
  -- DiagnosticUnderlineOk = {},
  -- DiagnosticFloatingError = {},
  -- DiagnosticFloatingWarn = {},
  -- DiagnosticFloatingInfo = {},
  -- DiagnosticFloatingHint = {},
  -- DiagnosticFloatingOk = {},
  -- DiagnosticSignError = {},
  -- DiagnosticSignWarn = {},
  -- DiagnosticSignInfo = {},
  -- DiagnosticSignHint = {},
  -- DiagnosticSignOk = {},
  -- DiagnosticDeprecated = {},
  -- DiagnosticUnnecessary = {},
}

groups.plugins = {
  --- indent-blankline.nvim. :h ibl.highlights
  IblIndent = { fg = palette.background1 },
  -- IblWhitespace = {},
  IblScope = { fg = palette.blue4 },

  --- hlargs.nvim. :h hlargs-customize
  Hlargs = { link = '@parameter' },

  --- gitsigns.nvim. :h gitsigns-highlight-groups
  GitSignsAdd = { fg = palette.teal1, bg = palette.none },
  GitSignsChange = { fg = palette.yellow, bg = palette.none },
  GitSignsDelete = { fg = palette.pink2, bg = palette.none },
  GitSignsChangedelete = { fg = blend(palette.yellow, palette.pink2, 0.5), bg = palette.none },
  -- GitSignsTopdelete = { },
  -- GitSignsUntracked = {},
  -- GitSignsAddNr = {},
  -- GitSignsChangeNr = {},
  -- GitSignsDeleteNr = {},
  -- GitSignsChangedeleteNr = {},
  -- GitSignsTopdeleteNr = {},
  -- GitSignsUntrackedNr = {},
  -- GitSignsAddLn = {},
  -- GitSignsChangeLn = {},
  -- GitSignsChangedeleteLn = {},
  -- GitSignsUntrackedLn = {},
  -- GitSignsAddPreview = {},
  -- GitSignsDeletePreview = {},
  -- GitSignsCurrentLineBlame = {},
  -- GitSignsAddInline = {},
  -- GitSignsDeleteInline = {},
  -- GitSignsChangeInline = {},
  -- GitSignsAddLnInline = {},
  -- GitSignsChangeLnInline = {},
  -- GitSignsDeleteLnInline = {},
  -- GitSignsDeleteVirtLn = {},
  -- GitSignsDeleteVirtLnInLine = {},
  -- GitSignsVirtLnum = {},

  --- nvim-cmp. :h cmp-highlight
  -- CmpItemAbbr = {},
  -- CmpItemAbbrDeprecated = {},
  CmpItemAbbrMatch = { fg = palette.text },
  CmpItemAbbrMatchFuzzy = { fg = palette.teal2 },
  CmpItemKind = { fg = palette.teal1 },
  -- CmpItemMenu = {},
  -- names are taken from `vim.lsp.protocol.CompletionItemKind`.
  CmpItemKindText = { fg = groups.common_syntax.String.fg, bg = palette.background3 },
  CmpItemKindMethod = { fg = groups.common_syntax.Function.fg, bg = palette.background3 },
  CmpItemKindFunction = { link = 'CmpItemKindMethod' },
  CmpItemKindConstructor = { fg = groups.treesitter['@constructor'].fg, bg = palette.background3 },
  CmpItemKindField = { fg = palette.blueGray1, bg = palette.background3 },
  CmpItemKindVariable = { fg = blend(palette.text, palette.blueGray1, 0.5), bg = palette.background3 },
  CmpItemKindClass = { fg = palette.blueGray1, bg = palette.background3 },
  CmpItemKindInterface = { fg = palette.blueGray1, bg = palette.background3 },
  CmpItemKindModule = { fg = palette.blueGray1, bg = palette.background3 },
  CmpItemKindProperty = { fg = palette.blueGray1, bg = palette.background3 },
  CmpItemKindUnit = { fg = groups.common_syntax.Number.fg, bg = palette.background3},
  CmpItemKindValue = { fg = groups.common_syntax.Number.fg, bg = palette.background3 },
  CmpItemKindEnum = { fg = palette.blueGray1, bg = palette.background3 },
  CmpItemKindKeyword = { fg = groups.common_syntax.Keyword.fg, bg = palette.background3 },
  CmpItemKindSnippet = { fg = palette.pink2, bg = palette.background3 },
  CmpItemKindColor = { fg = palette.pink1, bg = palette.background3 },
  CmpItemKindFile = { fg = palette.blue3, bg = palette.background3 },
  CmpItemKindReference = { fg = palette.blueGray1, bg = palette.background3 },
  CmpItemKindFolder = { fg = palette.blue3, bg = palette.background3 },
  CmpItemKindEnumMember = { fg = palette.blueGray1, bg = palette.background3 },
  CmpItemKindConstant = { fg = groups.common_syntax.Constant.fg, bg = palette.background3 },
  CmpItemKindStruct = { fg = palette.blueGray1, bg = palette.background3 },
  CmpItemKindEvent = { fg = palette.blue3, bg = palette.background3 },
  CmpItemKindOperator = { fg = groups.common_syntax.Operator.fg, bg = palette.background3 },
  CmpItemKindTypeParameter = { fg = groups.treesitter['@parameter'].fg, bg = palette.background3 },

  -- telescope.nvim.
  -- TelescopeBorder = { },
  -- TelescopePromptBorder = { },
  -- TelescopePreviewBorder = { },
  -- TelescopeResultsBorder = { },
}

vim.cmd.highlight('clear')
vim.g.colors_name = 'poimandres'

for _, highlights in pairs(groups) do
  for hl_name, opts in pairs(highlights) do
    vim.api.nvim_set_hl(0, hl_name, opts)
  end
end
