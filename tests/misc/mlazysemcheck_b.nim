when defined case4:
  const c4* = 123
  proc b3*()=
    static: echo " in b3 ct"
    echo "in b3"
  proc b2*()=b3()
  proc b1*()=b2()
  # proc b1*()=b4()

  # b1() # bug if commented

when defined case_import1:
  # generic
  proc sorted3*[T](a: T): T = a*2
  proc sorted2*[T](a: T): T = sorted3(a)

  # importc
  proc c_isnan2*(x: float): bool {.importc: "isnan", header: "<math.h>".}
  proc c_isnan3*(x: float): bool {.importc: "isnan", header: "<math.h>".} =
    ## with a comment

  # testing a behavior with overloads
  proc hash*[A](x: openArray[A]): int
  proc hash*[A](x: set[A]): int

  proc hash*(x: string): int =
    discard

  proc hash*(x: cstring): int =
    discard

  proc hash*(sBuf: string, sPos, ePos: int): int =
    discard

  proc hashIgnoreStyle*(x: string): int =
    discard

  proc hashIgnoreStyle*(sBuf: string, sPos, ePos: int): int =
    discard

  proc hashIgnoreCase*(x: string): int =
    discard

  proc hashIgnoreCase*(sBuf: string, sPos, ePos: int): int =
    discard

  proc hash*[T: tuple | object | proc](x: T): int =
    discard

  proc hash*[A](x: openArray[A]): int = 123

  proc hash*[A](x: set[A]): int =
    discard

  # callback
  proc fn2*(f: proc (time: int): int): int = 123
  proc fn3(t: int): int = discard
  proc testCallback*(): auto = fn2(fn3)

  type A = object
    a0: int

  proc testFieldAccessible*[T]() =
    # makes sure the friend module works correctly
    var a = A(a0: 1)
    doAssert a.a0 == 1

  # fwd decls in various forms
  proc fn4*(a: int)
  proc fn4(a: int) = discard

  proc fn5*(a: int)
  proc fn5*(a: int) = discard

  proc fn6*(a: int)
  proc fn6(a: int, b: float) = discard
  proc fn6(a: int) = discard

  proc fn7*(a: auto)
  proc fn7(a: auto) = discard

  proc fn8*(a: auto)
  fn8(1)
  proc fn8(a: auto) = discard

  proc fn9*(a: int)
  fn9(1)
  proc fn9(a: int) = discard

when defined case_cyclic:
  import mlazysemcheck
  proc fn2*(s: var string, a: int) =
    s.add $("fn2", a)
    if a>0:
      fn1(s, a-1)

  proc fn4*(s: var string, a: int): auto =
    s.add $("fn2", a, $typeof(fn3(s, 1)))
    a

  import mlazysemcheck
  import mlazysemcheck_c

  proc hb*(a: int): int =
    if a>0:
      ha(a-1)*3 + hc(a-1)*4
    else: 7

  proc gbImpl1() = discard
  proc gbImpl2()
  proc gbImpl3()
  proc gbImpl3() = discard
  proc gbImpl4[T]() = discard
  proc gbImpl5[T]()

  proc someOverload*(a: int16): string = "int16"

  proc gb*[T](a: T): T =
    # also tests fwd decls
    gbImpl1()
    gbImpl2()
    gbImpl3()
    gbImpl4[int]()
    gbImpl5[int]()
    if a>0:
      ga(a-1)*3 + gc(a-1)*4
    else: 7
  proc gbImpl2() = discard
  proc gbImpl5[T]() = discard

## scratch below

when defined case26:
  #[
  ]#
  proc fn*(a: int)=
    echo a # ok
    echo (a,) # hits bug with compiles

when defined case27d:
  proc fnAux(): int
  type TLLRepl = proc(): int
  proc llStreamOpenStdIn*(r: TLLRepl = fnAux) = # SIGSEGV
  # proc llStreamOpenStdIn*(r = fnAux) = # Error: invalid type: 'None' in this context: 'proc (r: None)' for proc
    discard
  proc fnAux(): int = discard
  # let z = fnAux
  # discard fnAux()
  # discard fnAux
  # let z = fnAux # see D20210831T180635
