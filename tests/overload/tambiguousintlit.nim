block: # issue #4858
  type
    SomeType = object
      field1: uint
  proc namedProc(an: var SomeType, b: SomeUnsignedInt) = discard
  var t = SomeType()
  namedProc(t, 0) #[tt.Error
           ^ type mismatch: got <SomeType, int literal(0)>]#
