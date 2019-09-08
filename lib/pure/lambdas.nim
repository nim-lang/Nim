#[
D20190811T003919
]#

type aliassym* {.magic: AliasSym.} # RENAME

proc alias2*[T](x: T): aliassym {.magic: "Alias2", compileTime.} # TODO: RENAME
  # Declares `name` as alias of `expr`, which must resolve to a symbol.
  # Works with any symbol, e.g. iterator, template, macro, module, proc etc.

import std/macros

template lambdaIter*(a: untyped): untyped =
  block:
    template lambdaIterImpl(): untyped = a
    alias2(lambdaIterImpl)

template lambdaIt*(a: untyped): untyped =
  block:
    template lambdaItImpl(a0): untyped =
      block:
        var it {.inject.} = a0
        a
    alias2(lambdaItImpl)

macro `~>`*(lhs, rhs: untyped): untyped =
  #[
  note: side effect safe (ie, arguments will be evaluated just once, unlike templates)
  could also allow param constraints, eg: (a, b: int, c) ~> a*b+c
  ]#
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
    body2.add newLetStmt(argInject, arg)

  let kind = lhs.kind
  case kind
  of nnkPar: # (a, b) ~> expr
    for i in 0..<lhs.len:
      addArg(lhs[i])
  of nnkIdent: # a ~> expr
    addArg(lhs)
  else:
    # TODO: (a,b,) tuple?
    # see D20181129T193310
    error("expected " & ${nnkPar,nnkIdent} & " got `" & $kind & "`")

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
  # echo result.repr

macro elementType2*(a: untyped): untyped =
  ## FACTOR D20190814T001035 elementType
  template fun(b): untyped =
    typeof(block: (for ai in b: ai))
  getAst(fun(a))

