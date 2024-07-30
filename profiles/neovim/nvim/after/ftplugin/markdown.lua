-- https://heitorpb.github.io/bla/format-tables-in-vim/
vim.api.nvim_create_user_command('FormatTable', ':\'<,\'>! tr -s " " | column -t -s "|" -o "|"', {
  desc = 'Format a Markdown table',
  bang = true,
  range = true,
})
