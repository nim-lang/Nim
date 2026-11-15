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
    template foo(expr) =
      expr
    proc fun1()=
      let a {.foo.} = 1
    template fun2()=
      let a {.foo.} = 1
    fun1() # ok
    fun2() # WAS bug

  template foo2() = discard # distractor (template or other symbol kind)
  block:
    template foo2(expr) =
      expr
    proc fun1()=
      let a {.foo2.} = 1
    template fun2()=
      let a {.foo2.} = 1
    fun1() # ok
    fun2() # bug: Error: invalid pragma: foo2

  block: # template pragmas don't work for templates, #18212
    # adapted from $nim/lib/std/private/since.nim
    # case without overload
    template since3(version: (int, int), body: untyped) {.dirty.} =
      when (NimMajor, NimMinor) >= version:
        body
    when true: # bug
      template fun3(): int {.since3: (1, 3).} = 12

  block: # ditto, w
    # case with overload
    template since2(version: (int, int), body: untyped) {.dirty.} =
      when (NimMajor, NimMinor) >= version:
        body
    template since2(version: (int, int, int), body: untyped) {.dirty.} =
      when (NimMajor, NimMinor, NimPatch) >= version:
        body
    when true: # bug
      template fun3(): int {.since2: (1, 3).} = 12

when true: # D20210801T100514:here
  from macros import genSym
  block:
    template fn() =
      var ret {.gensym.}: int # must special case template pragmas so it doesn't get confused
      discard ret
    fn()
    static: discard genSym()

block: # issue #10994
  macro foo(x): untyped = x
  template bar {.pragma.}

  proc a {.bar.} = discard # works
  proc b {.bar, foo.} = discard # doesn't

block: # issue #22525
  macro catch(x: typed) = x
  proc thing {.catch.} = discard
  thing()

block: # `localPassC` inside a routine is passed for the C file of its module
  proc answer(): cint =
    {.localPassC: "-DTPRAGMAS_MISC_LOCALPASSC_IN_PROC=7".}
    {.emit: "`result` = TPRAGMAS_MISC_LOCALPASSC_IN_PROC;".}

  let other = proc (): cint =
    {.localPassC: "-DTPRAGMAS_MISC_LOCALPASSC_IN_LAMBDA=8".}
    {.emit: "`result` = TPRAGMAS_MISC_LOCALPASSC_IN_LAMBDA;".}

  iterator once(): int =
    {.localPassC: "-DTPRAGMAS_MISC_LOCALPASSC_IN_ITER=9".}
    yield 1

  proc fromIterator(): cint =
    {.emit: "`result` = TPRAGMAS_MISC_LOCALPASSC_IN_ITER;".}

  doAssert answer() == 7
  doAssert other() == 8
  var n = 0
  for x in once(): n += x
  doAssert n == 1
  doAssert fromIterator() == 9
