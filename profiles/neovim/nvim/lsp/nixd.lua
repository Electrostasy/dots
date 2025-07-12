local root_markers = {
  'flake.nix',
  '.git',
}

local pkgs_expr = [[import <nixpkgs> { }]]
local options_expr = [[(import "${<nixpkgs>}/nixos/lib/eval-config.nix" { modules = []; }).options]]

local make_settings = function(pkgs, options)
  return {
    nixd = {
      nixpkgs = {
        expr = pkgs
      },

      options = {
        nixos = {
          expr = options
        },
      },
    },
  }
end

return {
  cmd = { 'nixd' },
  filetypes = { 'nix' },
  root_markers = root_markers,

  -- Initial configuration without flakes.
  settings = make_settings(pkgs_expr, options_expr),

  -- We do not immediately configure with flakes because they need to be copied
  -- to the Nix store, which can result in a delay of up to a few seconds. If we
  -- also want accurate pkgs and options, we need to evaluate this flake's hosts
  -- for included modules, packages, etc. which can further block Neovim. So we do
  -- all of the above in the on_attach handler asynchronously.
  on_attach = function(client, bufnr)
    local root_dir = vim.fs.root(bufnr, root_markers) or vim.fn.getcwd()

    if not vim.fs.find({ 'flake.nix' }, { path = root_dir, upward = true, type = 'file' }) then
      return
    end

    local bufname = vim.api.nvim_buf_get_name(bufnr)

    local cmd = { 'nix', 'eval', '.#nixosConfigurations', '--apply', 'builtins.attrNames', '--json' }
    local on_exit = function(out)
      local ok, hosts = pcall(vim.json.decode, out.stdout)
      if not ok then
        return
      end

      -- This is a heuristic rather specific to my directory structure, but it
      -- will select the host-specific pkgs and options.
      -- TODO: How to determine host config files generically, check options?
      for parent in vim.fs.parents(bufname .. '/') do
        for _, host in ipairs(hosts) do
          if host == vim.fs.basename(parent) then
            pkgs_expr = ([[(builtins.getFlake "%s").nixosConfigurations."%s".%s]]):format(root_dir, host, 'pkgs')
            options_expr = ([[(builtins.getFlake "%s").nixosConfigurations."%s".%s]]):format(root_dir, host, 'options')

            client.config.settings = make_settings(pkgs_expr, options_expr)
            if not client.notify('workspace/didChangeConfiguration', { settings = nil }) then
              vim.notify('Failed to change nixd LSP config!', vim.log.levels.WARN)
            end

            return
          end
        end
      end

    end

    vim.system(cmd, { cwd = root_dir }, vim.schedule_wrap(on_exit))
  end,
}
