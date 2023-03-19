-- Modified Lua port of the tranquil-vim colorscheme found here:
-- https://github.com/KoBruhh/tranquil-vim

local shade = {
  "#222027",
  "#333343",
  "#45475e",
  "#565a7a",
  "#676e95",
  "#7881b1",
  "#8a95cc",
  "#9ba8e8",
}

local accent = {
  "#8e86fe",
  "#9bcbe8",
  "#9be8b9",
  "#d4e89b",
  "#f5a38e",
  "#f78d8d",
  "#e66b6b",
  "#ef4d4d"
}

local groups = {
  Normal = { fg = shade[7], bg = shade[1] },

  -- Syntax groups.
  Comment = { fg = shade[3], italic = true },
  Constant = { fg = accent[4] },
  String = { link = 'Constant' },
  Character = { link = 'Constant' },
  SpecialChar = { fg = accent[5] },
  Identifier = { fg = shade[7] },
  Statement = { fg = accent[6] },
  PreProc = { fg = accent[7] },
  Type = { fg = accent[8] },
  Special = { fg = accent[5] },
  Underlined = { sp = accent[5], underline = true },
  Error = { fg = accent[1], bg = shade[2] },
  Todo = { fg = accent[1], bg = shade[2] },
  Function = { fg = accent[2] },
  Number = { link = 'Constant' },
  Boolean = { fg = accent[4], bold = true },
  Float = { link = 'Number' },
  Label = { link = 'Statement' },
  Operator = { fg = accent[5] },
  Keyword = { link = 'Statement' },
  Conditional = { link = 'Statement' },
  Exception = { link = 'Statement' },
  Repeat = { link = 'Statement' },
  Include = { link = 'PreProc' },
  Define = { link = 'PreProc' },
  Macro = { link = 'PreProc' },
  PreCondit = { link = 'PreProc' },
  StorageClass = { fg = accent[7] },
  Typedef = { link = 'Type' },
  Tag = { link = 'Special' },

  -- Highlighting groups.
  ColorColumn = { bg = shade[2] },
  Conceal = { bg = shade[3] },
  Cursor = { bg = shade[1] },
  CursorColumn = { bg = shade[2] },
  CursorLine = { bg = shade[2] },
  Directory = { bg = accent[6] },
  DiffAdd = { fg = accent[4], bg = shade[2] },
  DiffChange = { fg = accent[3], bg = shade[2] },
  DiffDelete = { fg = accent[1], bg = shade[2] },
  DiffText = { fg = accent[3], bg = shade[3] },
  ErrorMsg = { fg = shade[8], bg = accent[1] },
  VertSplit = { fg = shade[4], bg = shade[1] },
  WinSeparator = { link = 'VertSplit' },
  Folded = { fg = shade[5], bg = shade[2] },
  FoldColumn = { fg = shade[5], bg = shade[2] },
  SignColumn = { bg = shade[1] },
  IncSearch = { bg = shade[3] },
  LineNr = { fg = shade[3], bg = shade[1] },
  CursorLineNr = { fg = shade[4], bg = shade[2] },
  CursorLineFold = { bg = shade[2] },
  CursorLineSign = { bg = shade[2] },
  MatchParen = { bg = shade[3] },
  MoreMsg = { fg = shade[1], bg = accent[5] },
  NonText = { fg = shade[2] },
  Pmenu = { fg = shade[8], bg = shade[2] },
  PmenuSel = { fg = accent[5], bg = shade[3] },
  PmenuSbar = { fg = accent[4], bg = shade[3] },
  PmenuThumb = { fg = accent[1], bg = shade[4] },
  Question = { fg = shade[8], bg = shade[2] },
  Search = { fg = shade[1], bg = accent[3] },
  SpecialKey = { fg = accent[8], bg = shade[1] },
  SpellBad = { sp = accent[1], undercurl = true },
  SpellCap = { sp = accent[3], undercurl = true },
  SpellLocal = { sp = accent[5], undercurl = true },
  SpellRare = { sp = accent[2], undercurl = true },
  StatusLine = { fg = shade[5], bg = shade[2] },
  StatusLineNC = { fg = shade[4], bg = shade[2] },
  TabLine = { link = 'StatusLine' },
  TabLineFill = { fg = shade[2] },
  TabLineSel = { fg = shade[7], bg = shade[1] },
  Title = { fg = accent[6] },
  Visual = { bg = shade[2] },
  VisualNOS = { fg = accent[1], bg = shade[2] },
  WarningMsg = { fg = accent[1] },
  WildMenu = { fg = accent[5], bg = shade[2] },

  -- Depends on the cmp completion item kinds configuration for the highlights
  -- to make sense.
  CmpItemAbbr = { fg = shade[7] },
  CmpItemAbbrDeprecated = { link = 'Comment', strikethrough = true },
  CmpItemAbbrMatch = { fg = accent[3] },
  CmpItemAbbrMatchFuzzy = { fg = accent[4], italic = true },
  CmpItemKind = { fg = shade[1], bg = accent[6] },
  CmpItemKindClass = { fg = shade[1], bg = accent[8] },
  CmpItemKindColor = { fg = shade[1], bg = shade[7] },
  CmpItemKindConstant = { fg = shade[1], bg = accent[4] },
  CmpItemKindConstructor = { link = 'CmpItemKindFunction' },
  CmpItemKindEnum = { link = 'CmpItemKindConstant' },
  CmpItemKindEnumMember = { fg = shade[1], bg = shade[7] },
  CmpItemKindEvent = { link = 'CmpItemKindEvent' },
  CmpItemKindField = { fg = shade[1], bg = shade[7] },
  CmpItemKindFile = { fg = shade[1], bg = shade[7] },
  CmpItemKindFolder = { link = 'CmpItemKindFile' },
  CmpItemKindFunction = { fg = shade[1], bg = accent[2] },
  CmpItemKindInterface = { link = 'CmpItemKindClass' },
  CmpItemKindKeyword = { fg = shade[1], bg = accent[7] },
  CmpItemKindMethod = { link = 'CmpItemKindFunction' },
  CmpItemKindModule = { link = 'CmpItemKindConstant' },
  CmpItemKindOperator = { fg = shade[1], bg = accent[6] },
  CmpItemKindProperty = { link = 'CmpItemKindField' },
  CmpItemKindReference = { link = 'CmpItemKindTypeParameter' },
  CmpItemKindSnippet = { fg = shade[1], bg = accent[1] },
  CmpItemKindStruct = { link = 'CmpItemKindClass' },
  CmpItemKindText = { link = 'CmpItemKindValue' },
  CmpItemKindTypeParameter = { fg = shade[1], bg = accent[8] },
  CmpItemKindUnit = { fg = shade[1], bg = accent[3] },
  CmpItemKindValue = { fg = shade[1], bg = accent[4] },
  CmpItemKindVariable = { fg = shade[1], bg = shade[7] },
  CmpItemMenu = { fg = shade[6] },

  Hlargs = { fg = accent[6] },

  DiagnosticUnderlineError = { sp = accent[7], undercurl = true },
  DiagnosticUnderlineWarn = { sp = accent[5], underline = true },
  DiagnosticUnderlineInfo = { sp = accent[4], underdotted = true },
  DiagnosticUnderlineHint = { sp = accent[3], underdashed = true },
  DiagnosticError = { fg = accent[7] },
  DiagnosticWarn = { fg = accent[5] },
  DiagnosticInfo = { fg = accent[4] },
  DiagnosticHint = { fg = accent[3] },

  -- Depends on the telescope configuration borders for the border highlights
  -- to make sense.
  TelescopeBorder = { fg = shade[5], bg = shade[2] },
  TelescopePreviewBorder = { fg = shade[5], bg = shade[1] },
  TelescopeMatching = { fg = accent[3] },
  TelescopeNormal = { fg = shade[8], bg = shade[2] },
  TelescopePreviewNormal = { link = 'Normal' },
  TelescopePromptCounter = { fg = shade[7], },
  TelescopeSelection = { bg = shade[3] },
  TelescopeTitle = { fg = shade[1], bg = shade[5] },

  GitSignsAdd = { fg = accent[3], bg = shade[1] },
  GitSignsChange = { fg = accent[5], bg = shade[1] },
  GitSignsDelete = { fg = accent[7], bg = shade[1] },

  IndentBlanklineChar = { link = 'NonText' },
  IndentBlanklineContextChar = { fg = accent[7] },
  IndentBlanklineSpaceChar = { link = 'NonText' },

  ['@constant.builtin'] = { fg = accent[7], bold = true },
  ['@function.builtin'] = { link = '@constant.builtin'},
  ['@type.qualifier'] = { link = 'StorageClass' },
  ['@namespace'] = { link = 'StorageClass' },
  ['@attribute'] = { link = 'PreProc' },
  ['@property'] = { fg = shade[6] },
  ['@field'] = { link = '@property' },
  ['@string.documentation.python'] = { link = 'Comment' },
  ['@constant.bash'] = { link = '@variable' },
  ['@parent.cpp'] = { fg = accent[3] },
}

vim.cmd.highlight('clear')
vim.g.colors_name = 'tranquil'
for group, opts in pairs(groups) do
  vim.api.nvim_set_hl(0, group, opts)
end
