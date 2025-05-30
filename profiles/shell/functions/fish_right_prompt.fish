function fish_right_prompt -d "Print the right-side prompt"
  if test $CMD_DURATION && test $CMD_DURATION -ne 0
    set_color $fish_color_quote; echo "$(math "$CMD_DURATION/1000")s"
  end

  # https://github.com/NixOS/nix/issues/3862#issuecomment-707320241
  if test $SHLVL -gt 1 && string match -q -- '/nix/store/*' $PATH[1]
    set_color 7AB1DB; echo '  '
  end
end
