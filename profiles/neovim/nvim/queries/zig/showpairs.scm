(FnCallArguments (
  ("(" @opening)
  (")" @closing)))

(ParamDeclList (
  ("(" @opening)
  (")" @closing)))

(Block (
  ("{" @opening)
  ("}" @closing)))

(InitList (
  ("{" @opening)
  ("}" @closing)))

(ErrorSetDecl (
  ("{" @opening)
  ("}" @closing)))

(PtrTypeStart (
  ("[" @opening)
  ("]" @closing)))

(SuffixOp (
  ("[" @opening)
  ("]" @closing)))
