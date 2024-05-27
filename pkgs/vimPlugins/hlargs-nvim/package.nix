{ vimUtils
, fetchFromGitHub
, lib
}:

vimUtils.buildVimPlugin {
  pname = "hlargs-nvim";
  version = "unstable-2024-05-18";

  src = fetchFromGitHub {
    owner = "m-demare";
    repo = "hlargs.nvim";
    rev = "30fe1b3de2b7614f061be4fc9c71984a2b87e50a";
    hash = "sha256-V3XG1SCBz+EvObW7JSNIUxGZLv6zoRXyap7nRETmUA8=";
  };

  meta = {
    website = "https://github.com/m-demare/hlargs.nvim";
    description = "Highlight arguments' definitions and usages, using Treesitter";
    license = lib.licenses.gpl3;
  };
}
