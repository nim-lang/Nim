discard """
  targets: "c cpp js"
"""

template main() =
  block: # bug #17589
    #[
    # all those gave some variation of the same bug:
    'intVal' is not accessible using discriminant 'kind' of type 'TFullReg'
    'floatVal' is not accessible using discriminant 'kind' of type 'TFullReg'
    ]#
    block:
      proc f(a: static uint64): uint64 =
        a
      const x = 3'u64
      static: doAssert f(x) == 3'u64
      doAssert f(x) == 3'u64

    block:
      proc f(a: static uint64): uint64 =
        a
      const x = 3'u64
      static: doAssert f(x) == 3'u64
      doAssert f(x) == 3'u64

    block:
      proc foo(x: uint8): uint8 = x
      proc f(a: static uint8): auto = foo(a)
      const x = 3'u8
      static: doAssert f(x) == 3'u8
      doAssert f(x) == 3'u8

    block:
      template foo2(x: float) =
        let b = x == 0
      proc foo(x: float) = foo2(x)
      proc f(a: static float) = foo(a)
      const x = 1.0
      static: f(x)

    block:
      proc foo(x: int32) =
        let b = x == 0
      proc f(a: static int32) = foo(a)
      static: f(32767) # was working
      static: f(32768) # was failing because >= int16.high (see isInt16Lit)

  block: # bug #14585
    const foo_m0ninv = 0x1234'u64
    proc foo(m0ninv: static uint64) =
      let b = $m0ninv
    static:
      foo(foo_m0ninv)

static: main()
main()
