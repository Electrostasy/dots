(field_declaration_list (
  ("{" @opening)
  ("}" @closing)))

(template_argument_list (
  ("<" @opening)
  (">" @closing)))

(argument_list (
  ("(" @opening)
  (")" @closing)))

(parameter_list (
  ("(" @opening)
  (")" @closing)))

(condition_clause (
  ("(" @opening)
  (")" @closing)))

(for_statement (
  ("(" @opening)
  (")" @closing)))

(compound_statement (
  ("{" @opening)
  ("}" @closing)))

(subscript_expression (
  ("[" @opening)
  ("]" @closing)))

(lambda_capture_specifier (
  ("[" @opening)
  ("]" @closing)))

(array_declarator (
  ("[" @opening)
  ("]" @closing)))

(attribute_declaration (
  ("[[" @opening)
  ("]]" @closing)))

(initializer_list (
  ("{" @opening)
  ("}" @closing)))
