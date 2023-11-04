(list_element_access (
  ("[" @opening)
  ("]" @closing))) @container

(command_substitution (
  ("(" @opening)
  (")" @closing))) @container

; Doesn't work? Invalid node???
; (double_quote_string
;   (command_substitution (
;     ("$(" @opening)
;     (")" @closing))) @container)
