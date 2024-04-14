(command_substitution (
  ("$(" @opening)
  (")" @closing)))

(expansion (
  ("${" @opening)
  ("}" @closing)))

(arithmetic_expansion (
  ("$((" @opening)
  ("))" @closing)))

(test_command (
  ("[[" @opening)
  ("]]" @closing)))
