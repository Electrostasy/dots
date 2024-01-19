{
  vimUtils,
  fetchFromGitHub,
}:

vimUtils.buildVimPlugin {
  pname = "hlargs-nvim";
  version = "unstable-2023-07-05";

  src = fetchFromGitHub {
    owner = "m-demare";
    repo = "hlargs.nvim";
    rev = "cfc9beab4e176a13311efe03e38e6b6fed5df4f6";
    hash = "sha256-Mw5HArqBL6Uc1D3TVOSwgG0l2vh0Xq3bO170dkrJbwI=";
  };
}
