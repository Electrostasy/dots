;; extends

; Target assignments such as `local var_name = function() end` and highlight
; the identifier as a function.
; TODO: Avoid targetting other nodes as part of the variable list. Is it even possible?
(variable_declaration
  (assignment_statement
    (variable_list (identifier) @function)
    (expression_list
      value: (function_definition))))
