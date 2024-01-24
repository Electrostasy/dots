;; extends

; Function application will have the last identifier in the function call
; expression highlighted as a function.

; Priority must be higher than LSP semantic tokens (125) or else in most cases
; these will not take priority.

(apply_expression
  function: [
    ; Function application instances, such as `lib.nixosSystem`, `lib.genAttrs`
    ; etc., where the function is part of an attrset.
    (select_expression
      attrpath: (attrpath
        ; If there are multiple identifiers, only the last identifier is an
        ; an instance of function application.
        attr: ((identifier) @function.call (#set! "priority" 150)) .))

    ; Function application instances such as `let f = {}; in f args` etc., where
    ; the function is bound to a variable.
    (variable_expression
      ; This one is already detected by default, so we do not need to explicitly
      ; write a query for it, but LSP semantic tokens override it unless we set
      ; a higher priority.
      name: (identifier) @function.call (#set! "priority" 150))
  ])
