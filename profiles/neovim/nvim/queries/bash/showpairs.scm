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

(test_command (
  ("[" @opening)
  ("]" @closing)))

(compound_statement (
  ("{" @opening)
  ("}" @closing)))

(function_definition (
  ("(" @opening)
  (")" @closing)))
