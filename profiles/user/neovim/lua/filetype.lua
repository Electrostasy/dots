-- Add/override filetype highlighting
local filetypes = {
  by_extension = {
    ['jq'] = 'jq',
    ['nix'] = 'nix',
    ['yuck'] = 'clojure',
  },
  by_filename = {
    ['cargo.lock'] = 'toml',
    ['flake.lock'] = 'json',
  }
}
