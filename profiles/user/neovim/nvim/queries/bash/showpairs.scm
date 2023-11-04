(command_substitution (
  ("$(" @opening)
  (")" @closing))) @container

(expansion (
  ("${" @opening)
  ("}" @closing))) @container

(arithmetic_expansion (
  ("$((" @opening)
  ("))" @closing))) @container

(test_command (
  ("[[" @opening)
  ("]]" @closing))) @container
