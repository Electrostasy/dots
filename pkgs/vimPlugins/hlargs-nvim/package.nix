{ vimUtils
, fetchFromGitHub
, lib
}:

vimUtils.buildVimPlugin {
  pname = "hlargs-nvim";
  version = "0-unstable-2024-09-06";

  src = fetchFromGitHub {
    owner = "m-demare";
    repo = "hlargs.nvim";
    rev = "53ec5d8ca6ed012de5545ba83ea1eb3d636b09fb";
    hash = "sha256-K4hoTSYtriCNOz43Xl3KPeR3K9MNw8euY8QLYwBGQE4=";
  };

  meta = {
    website = "https://github.com/m-demare/hlargs.nvim";
    description = "Highlight arguments' definitions and usages, using Treesitter";
    license = lib.licenses.gpl3;
  };
}
