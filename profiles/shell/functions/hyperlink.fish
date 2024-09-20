function hyperlink -a uri text
  # TODO: Ideally, we should probe for hyperlink support and print full URL in TTY.
  # Example implementation: https://github.com/zkat/supports-hyperlinks/tree/main
  printf '\e]8;;%s\e\\\%s\e]8;;\e\\' $uri $text
end
