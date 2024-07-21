;; extends

((binding
  attrpath: (attrpath) @_attr
  expression: [
    (string_expression
      ((string_fragment) @injection.content
        (#set! injection.language "bash")))
    (indented_string_expression
      ((string_fragment) @injection.content
        (#set! injection.language "bash")))
  ])
  (#match? @_attr "(^|\\.)populate(Firmware|Root)Commands$"))

((binding
  attrpath: (attrpath) @_attr
  expression: [
    (string_expression
      ((string_fragment) @injection.content
        (#set! injection.language "devicetree")))
    (indented_string_expression
      ((string_fragment) @injection.content
        (#set! injection.language "devicetree")))
  ])
  (#match? @_attr "(^|\\.)dtsText$"))
