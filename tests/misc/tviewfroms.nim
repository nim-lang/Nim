discard """
  cmd: "nim $target --staticescapechecks $options $file"
"""

#[
next: fn17
]#

import ./mviewfroms
import std/compilesettings

setCapturedMsgs(captureStart)

block: # simple cases
  var g0: ptr int
  proc bad5(a1: int): auto = a1.unsafeAddr
  checkEscape "'bad5.a1' escapes via 'result'"

  proc bad6(a1: int) = g0 = a1.unsafeAddr
  checkEscape "'bad6.a1' escapes via 'g0'"

block: # shows how to ignore `StackAddrEscapes` in a scope
  proc bad2(): ptr int =
    var l0=0
    var l1=0
    ignoreEscape:
      result = l0.addr # this will be silenced
    result = l1.addr # but not this
    checkEscape "bad2.l1' escapes via 'result"

block: # result.addr escaping
  var g0: ptr int
  proc bad3(): int =
    g0 = result.addr
    checkEscape "'bad3.result' escapes via 'g0'"

  proc bad3b(a1: var ptr int): int =
    a1 = result.addr
    checkEscape "'bad3b.result' escapes via 'a1'"

block: # keep track of multiple escapes
  var g0: ptr int
  proc bad4(a1: int, a2: var int, a3: ptr int): auto =
    var l0 = 10
    var b1 = l0.addr
    b1 = a1.unsafeAddr
    b1 = a3
    var b2 = b1
    result = b2
    checkEscape @["'bad4.a1' escapes via 'result'", "'bad4.l0' escapes via 'result'"]

block: # escap through a global
  var g1: ptr int
  proc bad7(a1: int) = g1 = a1.unsafeAddr
  checkEscape "'bad7.a1' escapes via 'g1'"

block: # nested procs
  proc parent =
    var g0: ptr int
    proc bad8(a1: int) =
      g0 = a1.unsafeAddr
      checkEscape "'bad8.a1' escapes via 'g0'"

block: # escape via `var` param
  proc bad9(a1: var ptr int) =
    var a2 = 0
    a1 = a2.addr
    checkEscape "'bad9.a2' escapes via 'a1'"

block: # escape via `ptr ptr` param
  proc bad10(a1: ptr ptr int) =
    var a2 = 0
    a1[] = a2.addr
    checkEscape "'bad10.a2' escapes via 'a1'"

block: # escape via object ctor
  type Foo = ref object
    f0: int
    f1: ptr int

  proc bad12(a1: var int): auto =
    var a2=0
    var pa2=a2.addr
    Foo(f1: pa2)
  checkEscape "'bad12.a2' escapes via 'result'"

block: # complex example through multiple expressions
  type Foo=object
    f0: int
    f1: ptr int
    f2: seq[ptr int]

  proc bad11(a1: var int): auto =
    var a2=0
    var pa2 = (a2.addr,)
    var pa3 = pa2
    var pa4 = a1.addr
    const i = "ab".len - 2
    Foo(f0: a2, f1: a1.addr, f2: @[pa3[i]])
  checkEscape "'bad11.a2' escapes via 'result'"

block: # D20200710T191727 interprocedure inference: dependency of parameters based on proc implementation
  #[
  TODO: add examples with sfForward, which need {.viewFrom.} inference if non-default
  ]#
  proc fn(a1: ptr int, a2: ptr int): ptr int =
    # result depends on a2, not a1
    result = a2
  proc bad13(b1: var int): ptr int =
    var b2 = 0
    result = fn(b1.addr, b2.addr)
    checkEscape "'bad13.b2' escapes via 'result'"

    # fn.result depends only on `fn.a2`, so only on `b1`, which is legal here
    result = fn(b2.addr, b1.addr)
    checkEscapeOK()

block: # example with generic instantiation
  type Foo2[T] = object
    data: ptr T

  proc bad14(): auto =
    var l2 = 12
    var l1 = Foo2[int](data: l2.addr)
    result = [l1]
    checkEscape "'bad14.l2' escapes via 'result"

block: # example showing a simplified view implementation
  type Foo[T] = object
    n: int
    data: ptr T

  proc bar[T](a: T): T =
    result = a

  template initFoo1[T](a: openArray[T]): auto =
    Foo[T](n: a.len, data: a[0].unsafeAddr)

  proc initFoo2[T](a: var T): auto =
    result = Foo[int](n: a.len, data: a[0].addr)

  proc bad15[T](a: T, b: var Foo[int]): auto =
    var l0=[10,11]

    b = initFoo2(l0)
    checkEscape "'bad15.l0' escapes via 'b'"

    var local = initFoo2(l0)
    checkEscapeOK()

    when false: # BUG: unrelated cgen error
      #[
      @mtviewfroms.nim.c:587:38: error: use of undeclared identifier 'l0'
          g2__2U2wonDQdfsl4T1ZMOGZvQ.data = (&l0[(((NI) 0))- 0]);
      ]#
      var g2 {.global.} = initFoo1(l0)
      checkEscape "'bad15.l0' escapes via 'g2'"

    # complex example
    var l1 = initFoo2(l0)
    var l2 = l1
    var l3 = [l2.bar]
    result = bar(l3[0])
    checkEscape "'bad15.l0' escapes via 'result'"

    var g1 = initFoo1(l0)
    checkEscapeOK()

    let l0b = [1,2]
    g1 = initFoo1(l0b)
    checkEscapeOK()

    b = initFoo1(l0)
    checkEscape "'bad15.l0' escapes via 'b'"

    let l4 = @[10,11] # no escape since allocated on the heap
    b = initFoo1(l4)
    checkEscapeOK()

  var a, b: Foo[int]
  discard bad15(a, b)

block:
  var g0 = 0
  proc bad16: auto =
    var l0 = 0
    var l1 = l0.addr
    result = (g0.addr,)
    result[0] = l1
    checkEscape "'bad16.l0' escapes via 'result'"

block:
  var g0 = 0
  type Foo = object
    f0: ptr int
  proc bad17: auto =
    var l0 = 0
    var l1 = l0.addr
    result = Foo(f0: g0.addr)
    result.f0 = l1
    checkEscape "'bad17.l0' escapes via 'result'"

block:
  var g0 = 0
  type Foo = object
    f0: ptr int
  var g1: typeof([@[Foo()]])
  proc bad18: auto =
    var l0 = 0
    var l1 = l0.addr
    g1 = [@[Foo(f0: g0.addr)]]
    g1[0][0].f0 = l1
    checkEscape "'bad18.l0' escapes via 'g1'"

block:
  proc bad19(a1: int, a2: var int, a3: ptr int): auto =
    var l0 = 10
    var b1 = l0.addr
    b1 = a1.unsafeAddr
    b1 = a3
    var b2 = b1
    result = b2
    checkEscape @["'bad19.l0' escapes via 'result'", "'bad19.a1' escapes via 'result'"]

block:
  var g1: array[1, ptr int]
  var g2: seq[ptr int]
  var g3: ptr int
  var g4: ptr int
  var g5: ptr ptr int
  var g6: ptr ptr int
  proc bad20() =
    var l0 = 10
    var l1 = [l0.addr]
    var l2 = @[l0.addr]
    g1 = l1
    checkEscape "'bad20.l0' escapes via 'g1'"
    g2 = l2
    checkEscape "'bad20.l0' escapes via 'g2'"
    g3 = l1[0]
    checkEscape "'bad20.l0' escapes via 'g3'"
    g4 = l2[0] # escape
    g5 = l1[0].addr
    checkEscape "'bad20.l1' escapes via 'g5'"
    g6 = l2[0].addr
    checkEscape "'bad20.l0' escapes via 'g6'"

block: # escape semantics for array, seq: elements for seq are on heap
  proc bad21: auto =
    var a = [10]
    a[0].addr
  checkEscape "'bad21.a' escapes via 'result'"

  var g1: ptr seq[int]
  var g1a: ptr int
  var g2: ptr array[2,int]
  var g2a: ptr int
  var g3: seq[ptr int]
  proc bad21b: auto =
    var a1 = @[10,11]
    g1 = a1.addr
    checkEscape "'bad21b.a1' escapes via 'g1'"
    g1a = a1[0].addr
    checkEscapeOK() # because elements are heap allocated

    var a2 = [12,13]
    g2 = a2.addr
    checkEscape "'bad21b.a2' escapes via 'g2'"
    g2a = a2[0].addr
    checkEscape "'bad21b.a2' escapes via 'g2a'"

    var a3 = @[a2[0].addr]
    g3 = a3
    checkEscape "'bad21b.a2' escapes via 'g3'"

block:
  type Foo = ref object
    x1: ptr int
    x2: ref int
    x3: seq[Foo]
    x4: ptr array[2, Foo]
    x5: seq[ptr int]

  proc bad22: auto =
    var l0=0
    var l1=l0.addr
    var g0{.global.}: ptr int
    var s = Foo()
    s.x2 = new int
    s.x3.setLen 1
    s.x3[0].x5.setLen 2
    s.x3[0].x5[1] = l1 # escape here
    s.x5 = @[g0]
    result = s
    checkEscape "'bad22.l0' escapes via 'result'"

block:
  var g0 = 0
  var g1: pointer
  proc bad23: auto =
    var l0 = 0
    var f1: proc(): bool
    var f2 = f1
    var a = cast[pointer](l0.addr) # tyPointer
    var a2 = a
    result = (f2, g0.addr, g1, a2)
    checkEscape "'bad23.l0' escapes via 'result'"

block: # cstring
  var g0, g1: cstring
  proc bad24(): auto =
    var a = ['a', 'b', 'c', '\0']
    g0 = cast[cstring](a[0].addr)
    checkEscape "'bad24.a' escapes via 'g0'"
    g1 = cast[cstring](a.addr)
    checkEscape "'bad24.a' escapes via 'g1'"

block:
  proc bad25: seq[ptr int] =
    # D20200711T180629
    var l0=0
    result = @[l0.addr]
    checkEscape "'bad25.l0' escapes via 'result'"
    result[0] = l0.addr
    checkEscape "'bad25.l0' escapes via 'result'"

block:
  proc bad26(): ptr ptr int =
    # var g0 {.global.}: int # would not escape with that, see `fn12b`
    var g0: int
    g0 = 12
    var a0 = @[g0.addr]
    result = a0[0].addr
    checkEscape "'bad26.g0' escapes via 'result'"

  proc bad26b(): ptr int =
    var g0: int
    g0 = 12
    var a0 = [g0.addr]
    result = a0[0]
    checkEscape "'bad26b.g0' escapes via 'result'"

  proc bad26c(): ptr int =
    var g0 {.threadvar.}: int # no escape thanks to threadvar
    g0 = 13
    var a0 = [g0.addr]
    result = a0[0]
  doAssert bad26c()[] == 13
  checkEscapeOK()

block:
  proc fun2(a: var ptr int): ptr int = result = a
  proc bad27(a: var ptr int) =
    var l0 = 3
    var l1 = l0.addr
    a = fun2(l1)
    checkEscape "'bad27.l0' escapes via 'a'"
  var m0 = 4
  var m1 = m0.addr
  bad27(m1)

block: # case object
  type Foo = object
    case kind: bool
    of false: x0: ptr int
    of true: x1: ptr int

  proc bad28(): Foo =
    var l0 = 0
    var l1 = 1
    result.x0 = l0.addr
    checkEscape "'bad28.l0' escapes via 'result'"
    result = Foo(kind: true, x1: l1.addr)
    checkEscape "'bad28.l1' escapes via 'result'"

block:
  proc fn1a1(a1: int): auto = a1
  proc fn1a2(a1: var int): auto = a1
  proc fn1a3(a1: var int): auto = a1.addr

proc fn1(a1: ptr ptr int, a2: var int) =
  a1[] = a2.addr

proc fn2(a1: var int, a2: var int): auto =
  [a1.addr, a2.addr]

block:
  var g0: ptr int
  var g1 = [g0, g0]
  var g2 = (g0, )
  proc fn3(a1: var int, a2: var int, a3: var int): auto =
    (a1.addr, a2.addr, a1.addr, g0.addr, g1[0], g2[0])

block:
  type Foo=object
    f0: int
    f1: ptr int
    f2: seq[ptr int]

  proc fn3(a1: var int): auto =
    var a2=0
    var pa4 = a1.addr
    Foo(f0: a2, f1: a1.addr, f2: @[pa4])

block:
  type Foo = ref object
    f0: int
    f1: ptr int

  proc fn4(a1: var int): auto =
    var a2=Foo(f0: 1)
    result = a2

block:
  proc fn(a1: ptr int, a2: int): ptr int =
    result = a1

  proc fn5(b1: var int): ptr int =
    var b2 = 0
    result = fn(b1.addr, b2.addr[])
    result = fn(b1.addr, b2)

block:
  proc fn6 =
    var a0: int
    var g0: ptr int
    proc fn(a1: int) =
      g0 = a0.unsafeAddr

block:
  proc fn7: auto =
    var a = @[10]
    a[0].addr

block:
  proc fn8(a: ptr int): auto =
    #[
    D20200710T182818 using `sfAddrTaken` instead of current algorithm would not work
    because `sfAddrTaken` would be set for `a` in an unrelated statement.
    ]#
    let b = a.unsafeAddr
    result = a
    result = b[]

block:
  proc fn9(a: var int): auto =
    var l1 = a.addr
    var l2 = l1.addr
    result = l2[]
    result = l1.addr[]

  proc fn(a1: ptr int, a2: int): ptr int =
    result = a1

  proc fn9b(b1: var int): ptr int =
    var b2 = 0
    result = fn(b1.addr, b2.addr[])

block:
  var g0 = 0
  var g1: pointer
  proc fn10(): auto =
    var l0 = 0
    var f1: proc(): bool
      # tyProc; it's a closure, does not escape.
      # but maybe things might need to be adapted with #14881 (allocate closure env on stack if viable)
    var f2 = f1
    var a = cast[pointer](g0.addr)
    result = (f2, g0.addr, g1, a)

block:
  proc fn11(a1: var ptr int, a2: var int) =
    a1 = a2.addr

  var g0: ptr int
  var g1: ptr int
  proc fn11b(a1: var int, a2: var int): var int =
    result = a1
    g0 = result.addr
    g1 = a1.addr
    a2 = result

block:
  proc fn12(): auto =
    var a = @[10,11]
    var b = a[0].addr
    result = b # no escape, since data is on the heap

  proc fn12b(): ptr ptr int = # more complex example with `ptr int` elements
    var g0 {.global.}: int
    g0 = 12
    var a0 = @[g0.addr]
    result = a0[0].addr
  doAssert fn12b()[][] == 12

block:
  # D20200711T152921 no escape, cstring litterals have their address in static data segment
  proc fn13(): auto =
    var a = "abc".cstring
    result = a
    result = cast[cstring](a[0].addr)
  doAssert fn13() == "abc"

block:
  proc fun1(a: ptr int): int = result = a[]
  proc fun2(a: var int): int = result = a
  proc fn14(a: var int) =
    var l0 = 3
    a = fun1(l0.addr)
    a = fun2(l0)
  var m = 0
  fn14(m)
  doAssert m == 3

  proc fn14b(a: ptr int) =
    var l0 = 4
    var l1 = l0.addr
    a[] = fun1(l1)
  var m1 = m.addr
  fn14b(m1)
  doAssert m1[] == 4

block:
  proc fn15 =
    proc main1(a: var openArray[int]): ptr int =
      result = a[0].addr
    proc main2(a: var openArray[int]): var int =
      result = a[0]
    proc main3(a: openArray[ptr int]): ptr int =
      result = a[0]
    var b1 = [10,11]
    let b2 = main1(b1)
    doAssert b2[] == 10
    main2(b1) = 12
    doAssert b1[0] == 12
    var b3 = @[b1[0].addr]
    var b4 = main3(b3)
    doAssert b4[] == 12
  fn15()

block: # block scope escaping
  type Foo = object
    x: int
  var f: ptr Foo
  block:
    var f1 {.threadvar.}: Foo
    f = f1.addr
    checkEscapeOK()

    when false: # pending bug #14986
      var f2 {.global.}: Foo
      f = f2.addr
      checkEscapeOK()
        # this would hold currently and seems correct but is inconsistent
        # until bug #14986 is resolved

      # nim bug: there's no way to distinguish between 
      # `var f3: Foo` and `var f2 {.global.}: Foo`, which is a problem if
      # destructor is called for f3 but not f2.
      var f3: Foo
      f = f3.addr
      checkEscapeOK() # this would hold currently

  proc fn16()=
    var l5: Foo
    var l6: ptr Foo
    block:
      var l7: Foo
      proc fn16()=
        var l0: ptr Foo
        block:
          var l1 = Foo(x: 1)
          l0 = l1.addr
          checkEscape "'fn16.l1' escapes via 'l0'"
          var g2 {.threadvar.}: Foo
          l0 = g2.addr
          checkEscapeOK()
          var g3 {.global.}: Foo
          l0 = g3.addr
          checkEscapeOK()
        var l4: Foo
        l0 = l4.addr
        checkEscapeOK()
        l0 = l5.addr
        checkEscapeOK()
        l6 = l5.addr # both lhs,rhs in a parent scope
        checkEscapeOK()
        l6 = l7.addr # both lhs,rhs in a parent scope
        checkEscape "'fn16.l7' escapes via 'l6'"

block: # complex example
  type Foo[T] = object
    f0: seq[T]
    f1: T
    f2: int

  proc example1[T](a: T) =
    var f = Foo[T]()
    proc sub() =
      var s0 = 11
      var s1 = a.unsafeAddr
      proc deep()=
        var d1 = s0.addr
        var d2 = [d1.addr]
        var d3 = d2[0]
        f.f2 = d3[][]
        var d4 = f.f2.addr
        f.f1 = d4
        f.f0.setLen 3
        f.f0[0] = f.f1
        f.f0[1] = s1[]
        f.f0[2] = d3[] 
        checkEscape "'sub.s0' escapes via 'f'"

  var g0 = 10
  example1(g0.addr)

block: # complex example showing View and MView simplified from #14869
  type View[T] = object
    len: int
    data: ptr T

  type MView[T] = object
    len: int
    data: ptr T

  template view[T](a: openArray[T]): View[T] =
    let len2 = a.len
    View[T](len: len2, data: if len2 == 0: nil else: a[0].unsafeAddr)

  proc mview[T](a: var openArray[T]): MView[T] =
    result.len = a.len
    result.data = if a.len == 0: nil else: a[0].addr

  proc fn[T](a: T): T = result = a

  var g: array[10,int]

  proc example2(): auto =
    var g2 = g.view
    var a: array[10,int]
    var b = a.view
    var b2 = b.fn
    proc fn2[T](x: T): T = result = x
    proc fn3[T](x: T): auto = ([x], @[x], @[g2])
    let b3 = fn2(b2).fn3

    result = b3[0]
    checkEscape "'example2.a' escapes via 'result'"
    var g3 {.global.}: MView[int]
    g3 = a.mview
    checkEscape "'example2.a' escapes via 'g3'"

## failing tests
when false:
  reject:
    # fails to detect escape
    block:
      #[
      D20200710T184748 capture rhs
      lhs = rhs might capture rhs in lhs; this might be fixable by treating
      `lhs = rhs` via also the implicit: `rhs[] = lhs` ?
      ]#
      proc bugBad1(a: ptr ptr int) =
        var l0=10
        var l1=a
        l1[] = l0.addr
      proc bugBad1b(a: var ptr int) = # similar bug
        var l0=10
        var l1=a.addr
        l1[] = l0.addr

    block:
      #[
      D20200711T133853
      subfield assignment after reference copy
      this should be fixable by tracking that the destiny of `lhs = rhs` is tied when the type is a reference
      ]#
      type Foo = ref object
        x1: ptr int
      proc bugBad2: auto =
        var l0=0
        let s = Foo()
        result = s
        s.x1 = l0.addr # undetected escape after `result = s` assignment

    block:
      #[
      D20200711T130559
      memory tracking currently works through assignments (lhs = rhs) or definitions (var lhs = rhs) but
      not through function calls.

      BackwardsIndex
      ]#
      type Foo = object
        x: ptr int

      proc `[]=`(a: var Foo, index: int, x: ptr int) = a.x = x

      proc bugBad3: Foo =
        var l0=0
        result = Foo()
        result[0] = l0.addr

      # the root cause is the fact when `[]=` is a function call with no result; there is no
      # assignment (but for builtin []= it works fine currently, see D20200711T180629)
      proc fun(a: var Foo, x: ptr int) = a.x = x

      proc bugBad3b: Foo =
        var l0=0
        result = Foo()
        fun(result, l0.addr)

      proc bugBad3c: seq[ptr int] =
        var l0=0
        result.setLen 1
        # result[0] = l0.addr # ok (escape detected)
        result[^1] = l0.addr # bug (escape not detected)

    block: # D20200714T201023
      var g: ptr int
      proc fn(a: var int) =
        g = a.addr # (g=>a:1)
      proc main=
        var l0=3
        fn(l0) # escape

checkEscapeOK()
setCapturedMsgs(captureStop)
