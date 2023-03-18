(parenthesized_expression (
  ("(" @opening)
  (")" @closing))) @container

(inherit_from (
  ("(" @opening)
  (")" @closing))) @container

(interpolation (
  ("${" @opening)
  ("}" @closing))) @container

(attrset_expression (
  ("{" @opening)
  ("}" @closing))) @container

(formals (
  ("{" @opening)
  ("}" @closing))) @container

(list_expression (
  ("[" @opening)
  ("]" @closing))) @container
