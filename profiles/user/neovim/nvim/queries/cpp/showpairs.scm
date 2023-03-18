(field_declaration_list (
  ("{" @opening)
  ("}" @closing))) @container

(template_argument_list (
  ("<" @opening)
  (">" @closing))) @container

(argument_list (
  ("(" @opening)
  (")" @closing))) @container

(parameter_list (
  ("(" @opening)
  (")" @closing))) @container

(condition_clause (
  ("(" @opening)
  (")" @closing))) @container

(for_statement (
  ("(" @opening)
  (")" @closing))) @container

(compound_statement (
  ("{" @opening)
  ("}" @closing))) @container

(subscript_expression (
  ("[" @opening)
  ("]" @closing))) @container

(lambda_capture_specifier (
  ("[" @opening)
  ("]" @closing))) @container

(array_declarator (
  ("[" @opening)
  ("]" @closing))) @container

(attribute_declaration (
  ("[[" @opening)
  ("]]" @closing))) @container

(initializer_list (
  ("{" @opening)
  ("}" @closing))) @container
