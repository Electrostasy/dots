local free_memory = vim.uv.get_free_memory()

-- If we have more than 2 GB of RAM, then evaluate all flake inputs using up to
-- half of our free memory (to hopefully not trigger OOM conditions). 2 GB is
-- chosen as the minimum amount of memory required to evaluate nixpkgs, according
-- to nil LSP documentation.
local min_memory = 2048
local eval_memory = math.max(min_memory, math.floor(free_memory / 2 * 0.000001))

vim.lsp.start({
  name = 'nil',
  cmd = { 'nil' },
  root_dir = vim.fs.root(0, {
    'flake.nix',
    '.git',
  }),

  settings = {
    ['nil'] = {
      nix = {
        maxMemoryMB = eval_memory,
        flake = {
          autoArchive = true,
          autoEvalInputs = min_memory ~= eval_memory,
        },
      },
    },
  },
})
