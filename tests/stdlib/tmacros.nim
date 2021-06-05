#[
xxx macros tests need to be reorganized to makes sure each API is tested once
See also:
  tests/macros/tdumpast.nim for treeRepr + friends
]#

import std/macros

block: # hasArgOfName
  macro m(u: untyped): untyped =
    for name in ["s","i","j","k","b","xs","ys"]:
      doAssert hasArgOfName(params u,name)
    doAssert not hasArgOfName(params u,"nonexistent")

  proc p(s: string; i,j,k: int; b: bool; xs,ys: seq[int] = @[]) {.m.} = discard

block: # bug #17454
  proc f(v: NimNode): string {.raises: [].} = $v

block: # unpackVarargs
  block:
    proc bar1(a: varargs[int]): string =
      for ai in a: result.add " " & $ai
    proc bar2(a: varargs[int]) =
      let s1 = bar1(a)
      let s2 = unpackVarargs(bar1, a) # `unpackVarargs` makes no difference here
      doAssert s1 == s2
    bar2(1, 2, 3)
    bar2(1)
    bar2()

  block:
    template call1(fun: typed; args: varargs[untyped]): untyped =
      unpackVarargs(fun, args)
    template call2(fun: typed; args: varargs[untyped]): untyped =
      # fun(args) # works except for last case with empty `args`, pending bug #9996
      when varargsLen(args) > 0: fun(args)
      else: fun()

    proc fn1(a = 0, b = 1) = discard (a, b)

    call1(fn1)
    call1(fn1, 10)
    call1(fn1, 10, 11)

    call2(fn1)
    call2(fn1, 10)
    call2(fn1, 10, 11)

  block:
    template call1(fun: typed; args: varargs[typed]): untyped =
      unpackVarargs(fun, args)
    template call2(fun: typed; args: varargs[typed]): untyped =
      # xxx this would give a confusing error message:
      # required type for a: varargs[typed] [varargs] but expression '[10]' is of type: varargs[typed] [varargs]
      when varargsLen(args) > 0: fun(args)
      else: fun()
    macro toString(a: varargs[typed, `$`]): string =
      var msg = genSym(nskVar, "msg")
      result = newStmtList()
      result.add quote do:
        var `msg` = ""
      for ai in a:
        result.add quote do: `msg`.add $`ai`
      result.add quote do: `msg`
    doAssert call1(toString) == ""
    doAssert call1(toString, 10) == "10"
    doAssert call1(toString, 10, 11) == "1011"
