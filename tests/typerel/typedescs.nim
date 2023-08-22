# bug #1774
proc p(T: typedesc) = discard

p(type((5, 6)))       # Compiles
(type((5, 6))).p      # Doesn't compile (SIGSEGV: Illegal storage access.)
type T = type((5, 6)) # Doesn't compile (SIGSEGV: Illegal storage access.)

block: # issue #21677
  type
    Uints = uint16|uint32

  template constructor(name: untyped, typ: typedesc[Uints], typ2: typedesc[Uints]) =
    type
      name = object
        data: typ
        data2: typ2

    proc `init name`(data: typ, data2: typ2): name =
      result.data = data
      result.data2 = data2

  constructor(Test, uint32, uint16)
