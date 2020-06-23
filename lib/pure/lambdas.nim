##[
This module defines lambdas, or anonymous aliases that can be passed to routines.
]##

type aliassym* {.magic: AliasSym.} # RENAME
  ## type of symbol aliases
  # this does not require `experimental:"alias"`; doing so would
  # prevent `{.push experimental:"alias".}` from working with `alias2`. However,
  # it's harmless as `aliassym` can only be used with `alias2`, which itself
  # requires `experimental:"alias"`.

proc alias2*[T](s: T): aliassym {.magic: "Alias2", compileTime.} # TODO: RENAME
  ## Declares `name` as alias of `s`, which must resolve to a symbol.
  ## Works with any symbol, e.g. iterator, template, macro, module, proc etc.
  ## Requires {.push experimental:"alias".}

import std/macros

{.push experimental:"alias".}

template lambdaIter*(a: untyped): untyped =
  ## returns a lambda for an iterator call
  runnableExamples "--experimental:alias":
    iterator iota(n: int): auto =
      for i in 0..<n: yield i
    proc sum(a: aliassym): int =
      for ai in a: result += ai
    doAssert sum(lambdaIter iota(3)) == 0+1+2
  block:
    template lambdaIterImpl(): untyped = a
    alias2(lambdaIterImpl)

template lambdaIt*(a: untyped): untyped =
  ## returns a lambda for an `it` expression, allowing its use inside procs or
  ## other routines.
  runnableExamples "--experimental:alias":
    proc callFun[T](a: aliassym, b: T): auto = a(b)
    doAssert callFun(lambdaIt it*2, 3) == 3*2
  block:
    template lambdaItImpl(a0): untyped =
      block:
        var it {.inject.} = a0
        a
    alias2(lambdaItImpl)

proc replaceSym(body: NimNode, sym: NimNode): NimNode =
  ## replaces all occurrences of symbol `sym` by identifier `ident(sym.strVal)`
  # xxx expose in macros.nim
  case body.kind
  of nnkSym:
    if body == sym:
      return ident(sym.strVal)
  else:
    for i in 0..<len(body):
      body[i] = replaceSym(body[i], sym)
  return body

macro `~>`*(lhs, rhs: untyped): untyped =
  ## returns a lambda mapping `lhs` to `rhs`. This is side effect safe:
  ## arguments will be evaluated just once. `lhs` is either 1 identifier or a
  ## tuple of 0 or more identifiers.
  runnableExamples "--experimental:alias":
    proc callFun[T](a: aliassym, b: T): auto = a(b)
    let b = 2
    doAssert callFun(x~>x*b, 3) == 3*b
    var count = 0
    template identity(a): untyped =
      count.inc
      a
    var a  = "foo" # distractor: does not confuse lambda expression.
    const fn = (a,b)~>a*b
    doAssert fn(identity(2), 3) == 2*3
    doAssert count == 1 # side effect safe
    # this works outside `runnableExamples` (pending #13491)
    # const doNothing = () ~> (discard)
    # doNothing()

  # xxx future work could allow param constraints, eg: `(a, b: int, c) ~> a*b+c`
  var rhs = rhs
  let name = genSym(nskTemplate, "lambdaArrow")
  let formatParams2 = nnkFormalParams.newTree()
  formatParams2.add ident("untyped")
  var body2 = newStmtList()

  template addArg(argInject) =
    # this doesn't work since new gensym, see #12020
    # let arg = genSym(nskParam, argInject.strVal)
    # so using this workaround instead:
    var count {.threadvar.}: int
    count.inc
    let arg = newIdentNode(argInject.strVal & "_fakegensym_" & $count)

    formatParams2.add newTree(nnkIdentDefs, arg, ident("untyped"), newEmptyNode())
    # CHECKME: let or var?, eg var could be needed?
    var argInject2 = argInject
    if argInject2.kind == nnkSym:
      # needed, see `testArrowWrongSym`, `testArrowWrongSym2`
      rhs = replaceSym(rhs, argInject)
      argInject2 = ident(argInject2.strVal)
    body2.add newLetStmt(argInject2, arg)

  let kind = lhs.kind
  case kind
  of nnkPar: # (a, b) ~> expr
    for i in 0..<lhs.len:
      addArg(lhs[i])
  of nnkIdent, nnkSym: # a ~> expr
    addArg(lhs)
  else:
    # TODO: (a,b,) tuple?
    # see D20181129T193310
    error("expected " & ${nnkPar,nnkIdent,nnkSym} & " got `" & $kind & "`")

  body2.add rhs
  body2 = quote do: # TODO: option whether to use a block?
    block: `body2`

  result = newStmtList()
  result.add nnkTemplateDef.newTree(
    name,
    newEmptyNode(),
    newEmptyNode(),
    formatParams2,
    newEmptyNode(),
    newEmptyNode(),
    body2
  )
  result.add newCall(bindSym"alias2", name)

template lambdaStatic*(a: untyped): untyped =
  ## returns a lambda for a const expression, which can be passed to a routine.
  ## This works more reliably than `static[T]`.
  runnableExamples "--experimental:alias":
    type Foo[T] = object
      a: T
    proc fn[T1, T2](a: T1, b: T2) = # would not work with `b: static[T2]`
      const b2 = b.a
    fn("foo", lambdaStatic Foo[int](a: 1))

  block:
    const a2 = a
    template lambdaStaticImpl(): untyped = a2
    alias2(lambdaStaticImpl)

template lambdaType*(t: typedesc): untyped =
  ## returns a lambda for a type expression, which can be passed to a routine,
  ## similarly to `typedesc[T]`
  runnableExamples "--experimental:alias":
    proc fn(t1, t2: aliassym): string =
      doAssert t1 is float32
      result = $(t1.default, $t1, $t2)
    doAssert fn(lambdaType float32, lambdaType type(1u8+2u8)) == """(0.0, "float32", "uint8")"""
  type T = typeof(block: (var a: t; a))
  # type T = t
    # this would create a visible abstraction, eg `$` would give  "T`gensym37245237"
  alias2(T)
