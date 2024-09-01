{ fetchFromSourcehut
, haskell
}:

let
  src = fetchFromSourcehut {
    owner = "~rycee";
    repo = "mozilla-addons-to-nix";
    rev = "v0.12.0";
    hash = "sha256-+3IaEnhhefaj5zoNPkvAx8MM95O930d7sooAmtVuIME=";
  };
in

haskell.packages.ghc94.callCabal2nix "mozilla-addons-to-nix" src { }
