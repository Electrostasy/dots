local root_markers = {
  'flake.nix',
  '.git',
}

local nixpkgs_expr
local options_expr

local root_dir = vim.fs.root(0, root_markers) or vim.fn.getcwd()
if vim.fs.find({ 'flake.nix' }, { path = root_dir, upward = true, type = 'file' }) then
  nixpkgs_expr = ('(builtins.getFlake \"%s\").inputs.nixpkgs'):format(root_dir)

  local command = vim.system({ 'nix', 'eval', ('%s#nixosConfigurations'):format(root_dir), '--apply', 'builtins.attrNames', '--json' }):wait()
  local ok, hosts = pcall(vim.json.decode, command.stdout)
  if ok then
    for _, host in ipairs(hosts) do
      for parent in vim.fs.parents(vim.api.nvim_buf_get_name(0)) do
        if host == vim.fs.basename(parent) then
          local format_str = ('(builtins.getFlake \"%s\").nixosConfigurations.\"%s\"'):format(root_dir, host)
          nixpkgs_expr = ('%s.pkgs'):format(format_str)
          options_expr = ('%s.options'):format(format_str)
          break
        end
      end
    end
  end
end

if not nixpkgs_expr then
  nixpkgs_expr = 'import <nixpkgs> { }'
end

if not options_expr then
  options_expr = '(import \"${<nixpkgs>}/nixos/lib/eval-config.nix\" { modules = []; }).options'
end

return {
  cmd = { 'nixd' },
  filetypes = { 'nix' },
  root_markers = root_markers,

  settings = {
    nixd = {
      nixpkgs = {
        -- TODO: Sometimes we don't get pkgs completions?
        expr = nixpkgs_expr
      },

      options = {
        -- TODO: Add support for external modules.
        -- TODO: Sometimes options completions aren't loaded?
        nixos = {
          expr = options_expr
        },
      },
    },
  },
}
