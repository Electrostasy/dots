(parenthesized_expression (
  ("(" @opening)
  (")" @closing)))

(inherit_from (
  ("(" @opening)
  (")" @closing)))

(interpolation (
  ("${" @opening)
  ("}" @closing)))

(attrset_expression (
  ("{" @opening)
  ("}" @closing)))

(formals (
  ("{" @opening)
  ("}" @closing)))

(list_expression (
  ("[" @opening)
  ("]" @closing)))
