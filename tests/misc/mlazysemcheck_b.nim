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

when defined case_cyclic:
  import mlazysemcheck
  proc fn2*(s: var string, a: int) =
    s.add $("fn2", a)
    if a>0:
      fn1(s, a-1)

  proc fn4*(s: var string, a: int): auto =
    s.add $("fn2", a, $typeof(fn3(s, 1)))
    a

## scratch below
when defined case10c:
  proc aux1()=discard
  proc sorted3*(a1: int): int = discard
  proc sorted2*[T2](a2: T2): T2 = sorted3(a2)
  # proc sorted2*(a: int): int = sorted3(a) # would work

when defined case10d:
  # uncmoment sorted3
  proc aux1()=discard
  proc sorted3(a1: int): int = discard
  proc sorted2*[T2](a2: T2): T2 = sorted3(a2)

when defined case10e:
  # uncmoment sorted3
  import mlazysemcheck_c
  proc aux1()=discard
  # proc sorted3b(a1: int): int = discard
  # proc sorted3b(a1: int, a2: int): int = discard
  proc sorted2*[T2](a2: T2): T2 = sorted3b(a2)
  proc sorted2*[T2](a2: T2, b: T2): T2 = sorted3b(a2)

when defined case21:
  proc fn*(a: int)
  proc fn(a: int) = discard
    #[
    the bug: this isn't exported in symbol table even though should
    should be in an overload set with `proc fn*(a: int)` but not some other proc fn*(a: float) ?
    if fn() is requested, it should trigger decl semcheck of fn(a: int)  even though those are not exported?
    ]#

when defined case21b:
  proc fn*(a: int)
  proc fn*(a: int) = discard

when defined case21c:
  proc fn*(a: int)
  fn(2)
  proc fn*(a: int) = echo (a,)

when defined case23:
  type Hash = int64
  proc hash*[A](x: openArray[A]): Hash
  # let b1 = hash(@[1,2])
  proc hash*[A](x: openArray[A]): Hash =
    discard
  let b2 = hash(@[1.4])


when defined case25:
  type A = object
    a0: int
  proc fn*() =
    var a: A
    a.a0 = 1
    echo a

  proc fn2*[T](b: T) =
    var a: A
    # a.a0 = 1
    let b = a.a0

when defined case25b:
  type A = object
    a0: int
  # proc bam(a: int) = echo "in bam2"
  # proc bam(a: float) = echo "in bam3"
  proc fn2*[T](b: T) =
    # mixin bam
    var a: A
    let b = a.a0
    # let b2 = a.a2
    # bam()

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

when defined case30:
  proc fn*()=discard

