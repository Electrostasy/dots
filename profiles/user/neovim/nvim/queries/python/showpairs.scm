(tuple (
  ("(" @opening)
  (")" @closing))) @container

(parameters (
  ("(" @opening)
  (")" @closing))) @container

(argument_list (
  ("(" @opening)
  (")" @closing))) @container

(parenthesized_expression (
  ("(" @opening)
  (")" @closing))) @container

(list (
  ("[" @opening)
  ("]" @closing))) @container

(dictionary (
  ("{" @opening)
  ("}" @closing))) @container

(interpolation (
  ("{" @opening)
  ("}" @closing))) @container

(subscript (
  ("[" @opening)
  ("]" @closing))) @container
