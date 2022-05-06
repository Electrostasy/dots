local kanagawa = require('kanagawa')
local colours = require('kanagawa.colors').setup()

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
    TelescopeMatching = { fg = colours.roninYellow, style = 'bold' }
  }
})

kanagawa.load()
