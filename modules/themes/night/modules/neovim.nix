{ pkgs, lib, colors, ... }:

let
  highlights = with colors; {
    # general
    CursorColumn.bg = dark2; # Screen-column at the cursor; when 'cursorcolumn' is set.
    CursorLine.bg = dark2; # Screen-line at the cursor; when 'cursorline' is set.  Low-priority if foreground (ctermfg OR guifg) is not set.
    LineNr = { fg = pale1; bg = dark1; }; # Line number for ":number" and ":#" commands; and when 'number' or 'relativenumber' option is set.
    CursorLineNr = { fg = bright1; bg = dark2; }; # Like LineNr when 'cursorline' or 'relativenumber' is set for the cursor line.
    Visual = { bg = dark2; }; # Visual mode selection
    MatchParen = { style = "underline"; }; # The character under the cursor or just before it; if it is a paired bracket; and its match. |pi_paren.txt|
    Normal = { fg = bright1; bg = dark1; }; # normal text
    NormalFloat = { fg = bright1; bg = dark0; }; # Normal text in floating windows.
    NormalNC = { fg = bright1; bg = dark1; }; # normal text in non-current windows
    Whitespace = { fg = dark2; }; # "nbsp"; "space"; "tab" and "trail" in 'listchars'
    IndentBlanklineChar.fg = dark2;
    IndentBlanklineSpaceChar.fg = dark2;
    IndentBlanklineSpaceCharBlankline.fg = dark2;
    IndentBlanklineContextChar.fg = pale0;
    IndentBlanklineContextStart = { spell = pale0; style = "underline"; };
    GitSignsAdd.fg = green;
    GitSignsChange.fg = blue;
    GitSignsDelete.fg = red;
    LspDiagnosticsVirtualTextError = { fg = red; style = "italic"; };
    LspDiagnosticsVirtualTextWarning = { fg = yellow1; style = "italic"; };
    LspDiagnosticsVirtualTextInformation = { fg = blue; style = "italic"; };
    LspDiagnosticsVirtualTextHint = { fg = purple; style = "italic"; };
    LspDiagnosticsUnderlineError = { style = "undercurl"; spell = red; };
    LspDiagnosticsUnderlineWarning = { style = "undercurl"; spell = yellow1; };
    LspDiagnosticsUnderlineInformation = { style = "underline"; spell = blue; };
    LspDiagnosticsUnderlineHint = { style = "underline"; spell = purple; };
    LspDiagnosticsSignError = { fg = red; style = "bold"; };
    LspDiagnosticsSignWarning = { fg = yellow1; style = "bold"; };
    LspDiagnosticsSignInformation = { fg = blue; style = "bold"; };
    LspDiagnosticsSignHint = { fg = purple; style = "bold"; };
    # Syntax
    Comment = { fg = pale0; style = "italic"; }; # any comment

    Constant.fg = orange; # any constant
    String.fg = green; # a string constant: "this is a string"
    Character.fg = green; # a character constant: 'c', '\n'
    Number.fg = orange; # a number constant: 234, 0xff
    Boolean.fg = purple; # a boolean constant: TRUE, false
    Float.fg = orange; # a floating point constant: 2.3e10

    Identifier.fg = bright0; # any variable name
    Function.fg = yellow1; # function name (also: methods for classes)

    Statement.fg = yellow1; # any statement
    Conditional.fg = orange; # if, then, else, endif, switch, etc.
    Repeat.fg = orange; # for, do, while, etc.
    Label.fg = purple; # case, default, etc.
    Operator.fg = orange; # "sizeof", "+", "*", etc.
    Keyword.fg = purple; # any other keyword
    Exception.fg = orange; # try, catch, throw

    PreProc.fg = blue; # generic Preprocessor
    Include.fg = blue; # preprocessor #include
    Define.fg = blue; # preprocessor #define
    Macro.fg = blue; # same as Define
    PreCondit.fg = blue; # preprocessor #if, #else, #endif, etc.

    Type.fg = blue; # int, long, char, etc.
    StorageClass.fg = purple; # static, register, volatile, etc.
    Structure.fg = blue; # struct, union, enum, etc.
    Typedef.fg = blue; # A typedef

    Special.fg = purple; # any special symbol
    SpecialChar.fg = purple; # special character in a constant
    Tag.fg = purple; # you can use CTRL-] on this
    Delimiter.fg = yellow1; # character that needs attention
    SpecialComment.fg = pale0; # special things inside a comment
    Debug.fg = red; # debugging statements

    # nvim-cmp
    Pmenu = { fg = bright1; bg = dark0; };
    PmenuSel = { bg = dark2; };
    CmpDocumentation = { fg = bright1; bg = dark0; };
    CmpDocumentationBorder = { fg = yellow0; };
    CmpItemAbbr = { fg = pale1; }; # Abbr field
    CmpItemAbbrDeprecated = { fg = yellow0; }; # Deprecated item's abbr field
    CmpItemAbbrMatch = { fg = orange; }; # Matched characters highlight
    CmpItemAbbrMatchFuzzy = { fg = yellow0; }; # Fuzzy matched characters highlight
    CmpItemKind = { fg = blue; }; # Kind field
    CmpItemMenu = { fg = green; }; # Menu field
    CmpItemKindText = { fg = green; };
    CmpItemKindMethod = { fg = yellow1; };
    CmpItemKindFunction = { fg = yellow1; };
    CmpItemKindConstructor = { fg = orange; };
    CmpItemKindField = { fg = yellow1; };
    CmpItemKindVariable = { fg = bright1; };
    CmpItemKindClass = { fg = blue; };
    CmpItemKindInterface = { fg = blue; };
    CmpItemKindModule = { fg = blue; };
    CmpItemKindProperty = { fg = bright1; };
    CmpItemKindUnit = { fg = blue; };
    CmpItemKindValue = { fg = orange; };
    CmpItemKindEnum = { fg = blue; };
    CmpItemKindKeyword = { fg = purple; };
    CmpItemKindSnippet = { fg = red; };
    CmpItemKindColor = { fg = bright0; };
    CmpItemKindFile = { fg = yellow1; };
    CmpItemKindReference = { fg = red; };
    CmpItemKindFolder = { fg = orange; };
    CmpItemKindEnumMember = { fg = blue; };
    CmpItemKindConstant = { fg = orange; };
    CmpItemKindStruct = { fg = blue; };
    CmpItemKindEvent = { fg = blue; };
    CmpItemKindOperator = { fg = orange; };
    CmpItemKindTypeParameter = { fg = purple; };
    # # Builtin highlighting groups (:h highlight-groups)
    # # ColorColumn = { bg = ""; }; # used for the columns set with 'colorcolumn'
    # # Conceal = { fg = gray6; }; # placeholder characters substituted for concealed text (see 'conceallevel')
    Cursor = { fg = dark1; bg = blue; }; # character under the cursor
    # # lCursor = { fg = ""; bg = ""; }; # the character under the cursor when |language-mapping| is used (see 'guicursor')
    # # CursorIM = { fg = ""; bg = ""; }; # like Cursor; but used when in IME mode |CursorIM|
    # # Directory = { fg = blue; }; # directory names (and other special names in listings)
    DiffAdd = { bg = green; }; # diff mode: Added line |diff.txt|
    DiffChange = { bg = blue; }; # diff mode: Changed line |diff.txt|
    DiffDelete = { bg = red; }; # diff mode: Deleted line |diff.txt|
    DiffText = { fg = bright1; }; # diff mode: Changed text within a changed line |diff.txt|
    EndOfBuffer = { fg = pale0; }; # filler lines (~) after the end of the buffer.  By default; this is highlighted like |hl-NonText|.
    # # TermCursor = {}; # cursor in a focused terminal
    # # TermCursorNC = {}; # cursor in an unfocused terminal
    ErrorMsg = { fg = bright1; bg = red; }; # error messages on the command line
    VertSplit = { fg = pale0; bg = dark1; }; # the column separating vertically split windows
    # # Folded = { fg = ""; bg = ""; }; # line used for closed folds
    # # FoldColumn = { bg = ""; }; # 'foldcolumn'
    SignColumn = { fg = pale0; bg = dark1; }; # column where |signs| are displayed
    # # Substitute = { inherit (diagnostics.info) fg bg; }; # |:substitute| replacement text highlighting
    # # ModeMsg = { fg = fg; style = "bold"; }; # 'showmode' message (e.g.; "# INSERT # ")
    # MsgArea = { fg = ""; bg = ""; }; # Area for messages and cmdline
    # # MsgSeparator = {}; # Separator for scrolled messages; `msgsep` flag of 'display'
    # # MoreMsg = { fg = teal; }; # |more-prompt|
    NonText = { fg = pale0; }; # '@' at the end of the window; characters from 'showbreak' and other characters that do not really exist in the text (e.g.; ">" displayed when a double-wide character doesn't fit at the end of the line). See also |hl-EndOfBuffer|.
    # PmenuSbar = { bg = ""; }; # Popup menu: scrollbar.
    # PmenuThumb = { bg = ""; }; # Popup menu: Thumb of the scrollbar.
    # # Question = { fg = blue; }; # |hit-enter| prompt and yes/no questions
    # # QuickFixLine = { bg = ""; }; # Current |quickfix| item in the quickfix window. Combined with |hl-CursorLine| when the cursor is there.
    # Search = { fg = ""; bg = ""; }; # Last search pattern highlighting (see 'hlsearch').  Also used for similar items that need to stand out.
    # # SpecialKey = { fg = gray3; }; # Unprintable characters: text displayed differently from what it really is.  But not 'listchars' whitespace. |hl-Whitespace|
    # # SpellBad = { sp = c.error; style = "undercurl"; }; # Word that is not recognized by the spellchecker. |spell| Combined with the highlighting used otherwise.
    # # SpellCap = { sp = c.warning; style = "undercurl"; }; # Word that should start with a capital. |spell| Combined with the highlighting used otherwise.
    # # SpellLocal = { sp = c.info; style = "undercurl"; }; # Word that is recognized by the spellchecker as one that is used in another region. |spell| Combined with the highlighting used otherwise.
    # # SpellRare = { sp = c.hint; style = "undercurl"; }; # Word that is recognized by the spellchecker as one that is hardly ever used.  |spell| Combined with the highlighting used otherwise.
    # StatusLine = { fg = ""; bg = ""; }; # status line of current window
    # StatusLineNC = { fg = ""; bg = ""; }; # status lines of not-current windows Note: if this is equal to "StatusLine" Vim will use "^^^" in the status line of the current window.
    # # TabLine = { bg = ""; }; # tab pages line; not active tab page label
    # # TabLineFill = { bg = ""; }; # tab pages line; where there are no labels
    # # TabLineSel = { fg = ""; bg; }; # tab pages line; active tab page label
    # # Title = { fg = blue; style = "bold"; }; # titles for output from ":set all"; ":autocmd" etc.
    # # VisualNOS = { bg = ""; }; # Visual mode selection when vim is "Not Owning the Selection".
    # # WarningMsg = { fg = diagnostics.warning.fg; }; # warning messages
    # # WildMenu = { bg = ""; }; # current match in 'wildmenu' completion=


    # Underlined.fg = ""; # text that stands out, HTML links

    # Ignore.fg = ""; # left blank, hidden  |hl-Ignore|

    # Error = { fg = ""; bg = ""; }; # any erroneous construct

    # # anything that needs extra attention; mostly the keywords TODO FIXME
    # Todo = { fg = ""; bg = ""; };

    ## nvim-treesitter
    # TSAnnotation
    TSAttribute.fg = blue;
    # TSBoolean
    # TSCharacter
    TSComment = { fg = pale0; style = "italic"; };
    TSConditional = { fg = orange; style = "bold"; };
    # TSConstant
    TSConstBuiltin = { fg = blue; style = "bold"; };
    # TSConstMacro
    # TSError
    # TSException
    TSField.fg = yellow1;
    # TSFloat
    # TSFunction
    # TSFuncBuiltin
    # TSFuncMacro
    # TSInclude
    TSKeyword = { fg = purple; style = "bold"; };
    # TSKeywordFunction
    # TSKeywordOperator
    # TSKeywordReturn
    # TSLabel
    # TSMethod
    TSNamespace.fg = purple;
    # TSNone
    # TSNumber
    TSOperator.fg = orange;
    # TSParameter
    # TSParameterReference
    # TSProperty
    TSPunctDelimiter.fg = orange;
    TSPunctBracket.fg = bright1;
    TSConstructor.fg = orange;
    # TSPunctSpecial
    # TSRepeat
    TSString.fg = green;
    TSStringRegex.fg = purple;
    TSStringEscape.fg = yellow1;
    TSStringSpecial = { fg = purple; };
    # TSSymbol
    # TSTag
    # TSTagAttribute
    # TSTagDelimiter
    # TSText
    # TSStrong
    # TSEmphasis
    # TSUnderline
    # TSStrike
    # TSTitle
    # TSLiteral
    # TSURI
    # TSMath
    # TSTextReference
    # TSEnvironment
    # TSEnvironmentName
    # TSNote
    # TSWarning
    # TSDanger
    # TSType
    # TSTypeBuiltin
    TSVariable.fg = bright1;
    TSVariableBuiltin = { fg = blue; style = "bold"; };


    # # Plugin highlighting groups

    # # FloatBorder = { fg = gray3; };
    # IncSearch = { bg = ""; fg = ""; style = "bold"; }; # 'incsearch' highlighting; also used for the text replaced with ":s///c"
  };
  lualine = with colors; {};
  /*
    lib.mapAttrs
      (name: value: lib.nameValuePair name (value // {
        c = { bg = background.frontHi; fg = foreground.secondary; };
        y = { bg = background.frontHi; fg = foreground.secondary; };
        z = { bg = background.frontHi; fg = foreground.secondary; };
      }))
      {
        normal = {
          a = { bg = blue.normal; fg = background.back; gui = "bold"; };
          b = { bg = blue.light; fg = background.back; };
        };
        insert = {
          a = { bg = orange.normal; fg = background.back; gui = "bold"; };
          b = { bg = orange.light; fg = background.back; };
        };
        command = {
          a = { bg = red.normal; fg = background.back; gui = "bold"; };
          b = { bg = red.light; fg = background.back; };
        };
        visual = {
          a = { bg = purple.normal; fg = background.back; gui = "bold"; };
          b = { bg = purple.light; fg = background.back; };
        };
        replace = {
          a = { bg = yellow.normal; fg = foreground.primary; gui = "bold"; };
          b = { bg = yellow.light; fg = gray.normal; };
        };
        terminal = {
          a = { bg = cyan.dark; fg = background.back; gui = "bold"; };
          b = { bg = cyan.normal; fg = background.back; };
        };
        inactive = {
          a = { bg = gray.light; fg = background.back; gui = "bold"; };
          b = { bg = background.backHi; fg = background.back; };
        };
      };
      */
in
{
  programs.neovim.plugins = [
    (pkgs.vimUtils.buildVimPluginFrom2Nix rec {
      pname = "nix-colorscheme";
      version = "0.0.1";
      src = null;

      # Skip unpack because src = null
      unpackPhase = ":";
      buildPhase = with lib;
        let
          # Should these ever change, adapt from here
          # https://github.com/NixOS/nixpkgs/blob/9ec1f8f88f7818aacce7df23ad3d775e8d9f8ed8/pkgs/misc/vim-plugins/vim-utils.nix#L185
          # Changed on 2021-09-12: https://github.com/NixOS/nixpkgs/commit/56f823dd5c596ef6374f99a22ca63168ff6f6fb9
          rtpPath = ".";
        in
        ''
          # Install the base colorscheme
          mkdir -p $out/colors
          echo ${
            escapeShellArg ''
              set background=dark
              set termguicolors
              highlight clear
              if exists("syntax_on")
                syntax reset
              endif
              let g:colors_name='nix-colorscheme'
            ''
          } > $out/colors/nix-colorscheme.vim
          echo ${
            escapeShellArg (
              concatStringsSep "\n" (
                mapAttrsFlatten (
                  group: highlight:
                    let get = k: highlight.${k} or "NONE";
                    in "highlight ${group} guifg=${get "fg"} guibg=${get "bg"} gui=${get "style"} guisp=${get "spell"}"
                ) highlights
              )
            )
          } >> $out/colors/nix-colorscheme.vim

          # Install lualine theme
          # mkdir -p $out/lua/lualine/themes
          # echo ${
            # Generating lua from nix is insane and I refuse to bother, so let
            # lib.generators.toPretty do all the heavy lifting
            escapeShellArg (
              "return " + builtins.replaceStrings [ ";" ] [ "," ] (
                generators.toPretty {} lualine
              )
            )
          } > $out/lua/lualine/themes/nix-lualine.lua
        '';
      })
  ];
}
