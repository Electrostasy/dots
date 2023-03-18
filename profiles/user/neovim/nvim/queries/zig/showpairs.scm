(FnCallArguments (
  ("(" @opening)
  (")" @closing))) @container

(ParamDeclList (
  ("(" @opening)
  (")" @closing))) @container

(Block (
  ("{" @opening)
  ("}" @closing))) @container

(InitList (
  ("{" @opening)
  ("}" @closing))) @container

(ErrorSetDecl (
  ("{" @opening)
  ("}" @closing))) @container

(PtrTypeStart (
  ("[" @opening)
  ("]" @closing))) @container

(SuffixOp (
  ("[" @opening)
  ("]" @closing))) @container
