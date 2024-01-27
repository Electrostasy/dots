(list_element_access (
  ("[" @opening)
  ("]" @closing)))

(command_substitution (
  ("(" @opening)
  (")" @closing)))

; Doesn't work? Invalid node???
; (double_quote_string
;   (command_substitution (
;     ("$(" @opening)
;     (")" @closing))))
