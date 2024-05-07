function fish_right_prompt -d "Print the right-side prompt"
  set_color $fish_color_autosuggestion; date '+%H:%M:%S'
  if test $CMD_DURATION && test $CMD_DURATION -ne 0
    set_color $fish_color_quote; echo " $(math "$CMD_DURATION/1000")s"
  end
end
