;; extends

; Every instance of function application, such as lib.genAttrs [],
; lib.nixosSystem {} etc. will have the last identifier in the select expression
; highlighted as a function. If there are multiple identifiers, only the last
; identifier is targetted.
(apply_expression
  function: (select_expression
    (attrpath
      (identifier) @function .)))
