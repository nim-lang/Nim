##[
tests for misc pragmas that don't need a separate file
]##

block:
  static: doAssert not defined(tpragmas_misc_def)
  {.undef(tpragmas_misc_def).} # works even if not set
  static: doAssert not defined(tpragmas_misc_def)
  {.define(tpragmas_misc_def).}
  static: doAssert defined(tpragmas_misc_def)
  {.undef(tpragmas_misc_def).}
  static: doAssert not defined(tpragmas_misc_def)

block: # (partial fix) bug #15920
  block: # var template pragmas don't work in templates
    template foo(lhs, typ, expr) =
      let lhs = expr
    proc fun1()=
      let a {.foo.} = 1
    template fun2()=
      let a {.foo.} = 1
    fun1() # ok
    fun2() # WAS bug

  template foo2() = discard # distractor (template or other symbol kind)
  block:
    template foo2(lhs, typ, expr) =
      let lhs = expr
    proc fun1()=
      let a {.foo2.} = 1
    template fun2()=
      let a {.foo2.} = 1
    fun1() # ok
    when false: # bug: Error: invalid pragma: foo2
      fun2()

  block: # proc template pragmas don't work in templates
    # adapted from $nim/lib/std/private/since.nim
    # case without overload
    template since3(version: (int, int), body: untyped) {.dirty.} =
      when (NimMajor, NimMinor) >= version:
        body
    when false: # bug
      template fun3(): int {.since3: (1, 3).} = 12

  block: # ditto, w
    # case with overload
    template since2(version: (int, int), body: untyped) {.dirty.} =
      when (NimMajor, NimMinor) >= version:
        body
    template since2(version: (int, int, int), body: untyped) {.dirty.} =
      when (NimMajor, NimMinor, NimPatch) >= version:
        body
    when false: # bug
      template fun3(): int {.since2: (1, 3).} = 12

when true: # D20210801T100514:here
  from macros import genSym
  block:
    template fn() =
      var ret {.gensym.}: int # must special case template pragmas so it doesn't get confused
      discard ret
    fn()
    static: discard genSym()
