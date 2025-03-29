return {
  cmd = { 'clangd' },
  filetypes = { 'c', 'cpp' },
  root_markers = {
    '.clangd',
    'compile_commands.json',
    'compile_flags.txt',
    'configure.ac',
    '.git',
  },
}
