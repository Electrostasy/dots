(parenthesized_expression (
  ("(" @opening)
  (")" @closing)))

(for_statement (
  ("(" @opening)
  (")" @closing)))

(parameter_list (
  ("(" @opening)
  (")" @closing)))

(argument_list (
  ("(" @opening)
  (")" @closing)))

(cast_expression (
  ("(" @opening)
  (")" @closing)))

(initializer_list (
  ("{" @opening)
  ("}" @closing)))

(compound_statement (
  ("{" @opening)
  ("}" @closing)))

(subscript_expression (
  ("[" @opening)
  ("]" @closing)))
