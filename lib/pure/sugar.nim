#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Dominik Picheta
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements nice syntactic sugar based on Nim's
## macro system.

import std/private/since
import macros, typetraits

proc checkPragma(ex, prag: var NimNode) =
  since (1, 3):
    if ex.kind == nnkPragmaExpr:
      prag = ex[1]
      if ex[0].kind == nnkPar and ex[0].len == 1:
        ex = ex[0][0]
      else:
        ex = ex[0]

proc createProcType(p, b: NimNode): NimNode {.compileTime.} =
  result = newNimNode(nnkProcTy)
  var
    formalParams = newNimNode(nnkFormalParams).add(b)
    p = p
    prag = newEmptyNode()

  checkPragma(p, prag)

  case p.kind
  of nnkPar, nnkTupleConstr:
    for i in 0 ..< p.len:
      let ident = p[i]
      var identDefs = newNimNode(nnkIdentDefs)
      case ident.kind
      of nnkExprColonExpr:
        identDefs.add ident[0]
        identDefs.add ident[1]
      else:
        identDefs.add newIdentNode("i" & $i)
        identDefs.add(ident)
      identDefs.add newEmptyNode()
      formalParams.add identDefs
  else:
    var identDefs = newNimNode(nnkIdentDefs)
    identDefs.add newIdentNode("i0")
    identDefs.add(p)
    identDefs.add newEmptyNode()
    formalParams.add identDefs

  result.add formalParams
  result.add prag

macro `=>`*(p, b: untyped): untyped =
  ## Syntax sugar for anonymous procedures.
  ##
  ## .. code-block:: nim
  ##
  ##   proc passTwoAndTwo(f: (int, int) -> int): int =
  ##     f(2, 2)
  ##
  ##   passTwoAndTwo((x, y) => x + y) # 4

  var
    params = @[ident"auto"]
    name = newEmptyNode()
    kind = nnkLambda
    pragma = newEmptyNode()
    p = p

  checkPragma(p, pragma)

  if p.kind == nnkInfix and p[0].kind == nnkIdent and p[0].eqIdent"->":
    params[0] = p[2]
    p = p[1]

  checkPragma(p, pragma) # check again after -> transform

  since (1, 3):
    if p.kind == nnkCall:
      # foo(x, y) => x + y
      kind = nnkProcDef
      name = p[0]
      let newP = newNimNode(nnkPar)
      for i in 1..<p.len:
        newP.add(p[i])
      p = newP

  case p.kind
  of nnkPar, nnkTupleConstr:
    var untypedBeforeColon = 0
    for i, c in p:
      var identDefs = newNimNode(nnkIdentDefs)
      case c.kind
      of nnkExprColonExpr:
        let t = c[1]
        since (1, 3):
          # + 1 here because of return type in params
          for j in (i - untypedBeforeColon + 1) .. i:
            params[j][1] = t
        untypedBeforeColon = 0
        identDefs.add(c[0])
        identDefs.add(t)
        identDefs.add(newEmptyNode())
      of nnkIdent:
        identDefs.add(c)
        identDefs.add(newIdentNode("auto"))
        identDefs.add(newEmptyNode())
        inc untypedBeforeColon
      of nnkInfix:
        if c[0].kind == nnkIdent and c[0].eqIdent"->":
          var procTy = createProcType(c[1], c[2])
          params[0] = procTy[0][0]
          for i in 1 ..< procTy[0].len:
            params.add(procTy[0][i])
        else:
          error("Expected proc type (->) got (" & c[0].strVal & ").", c)
        break
      else:
        error("Incorrect procedure parameter list.", c)
      params.add(identDefs)
  of nnkIdent:
    var identDefs = newNimNode(nnkIdentDefs)
    identDefs.add(p)
    identDefs.add(ident"auto")
    identDefs.add(newEmptyNode())
    params.add(identDefs)
  else:
    error("Incorrect procedure parameter list.", p)
  result = newProc(body = b, params = params,
                   pragmas = pragma, name = name,
                   procType = kind)

macro `->`*(p, b: untyped): untyped =
  ## Syntax sugar for procedure types.
  ##
  ## .. code-block:: nim
  ##
  ##   proc pass2(f: (float, float) -> float): float =
  ##     f(2, 2)
  ##
  ##   # is the same as:
  ##
  ##   proc pass2(f: proc (x, y: float): float): float =
  ##     f(2, 2)

  result = createProcType(p, b)

macro dump*(x: untyped): untyped =
  ## Dumps the content of an expression, useful for debugging.
  ## It accepts any expression and prints a textual representation
  ## of the tree representing the expression - as it would appear in
  ## source code - together with the value of the expression.
  ##
  ## As an example,
  ##
  ## .. code-block:: nim
  ##   let
  ##     x = 10
  ##     y = 20
  ##   dump(x + y)
  ##
  ## will print ``x + y = 30``.
  let s = x.toStrLit
  let r = quote do:
    debugEcho `s`, " = ", `x`
  return r

# TODO: consider exporting this in macros.nim
proc freshIdentNodes(ast: NimNode): NimNode =
  # Replace NimIdent and NimSym by a fresh ident node
  # see also https://github.com/nim-lang/Nim/pull/8531#issuecomment-410436458
  proc inspect(node: NimNode): NimNode =
    case node.kind:
    of nnkIdent, nnkSym:
      result = ident($node)
    of nnkEmpty, nnkLiterals:
      result = node
    else:
      result = node.kind.newTree()
      for child in node:
        result.add inspect(child)
  result = inspect(ast)

template distinctBase*(T: typedesc): typedesc {.deprecated: "use distinctBase from typetraits instead".} =
  ## reverses ``type T = distinct A``; works recursively.
  typetraits.distinctBase(T)

macro capture*(locals: varargs[typed], body: untyped): untyped {.since: (1, 1).} =
  ## Useful when creating a closure in a loop to capture some local loop variables
  ## by their current iteration values. Example:
  ##
  ## .. code-block:: Nim
  ##   import strformat, sequtils, sugar
  ##   var myClosure : proc()
  ##   for i in 5..7:
  ##     for j in 7..9:
  ##       if i * j == 42:
  ##         capture i, j:
  ##           myClosure = proc () = echo fmt"{i} * {j} = 42"
  ##   myClosure() # output: 6 * 7 == 42
  ##   let m = @[proc (s: string): string = "to " & s, proc (s: string): string = "not to " & s]
  ##   var l = m.mapIt(capture(it, proc (s: string): string = it(s)))
  ##   let r = l.mapIt(it("be"))
  ##   echo r[0] & ", or " & r[1] # output: to be, or not to be
  var params = @[newIdentNode("auto")]
  let locals = if locals.len == 1 and locals[0].kind == nnkBracket: locals[0]
               else: locals
  for arg in locals:
    params.add(newIdentDefs(ident(arg.strVal), freshIdentNodes getTypeInst arg))
  result = newNimNode(nnkCall)
  result.add(newProc(newEmptyNode(), params, body, nnkProcDef))
  for arg in locals: result.add(arg)

since (1, 1):
  import std / private / underscored_calls

  macro dup*[T](arg: T, calls: varargs[untyped]): T =
    ## Turns an `in-place`:idx: algorithm into one that works on
    ## a copy and returns this copy.
    ## **Since**: Version 1.2.
    runnableExamples:
      import algorithm

      var a = @[1, 2, 3, 4, 5, 6, 7, 8, 9]
      doAssert a.dup(sort) == sorted(a)
      # Chaining:
      var aCopy = a
      aCopy.insert(10)

      doAssert a.dup(insert(10), sort) == sorted(aCopy)

      var s1 = "abc"
      var s2 = "xyz"
      doAssert s1 & s2 == s1.dup(&= s2)

    result = newNimNode(nnkStmtListExpr, arg)
    let tmp = genSym(nskVar, "dupResult")
    result.add newVarStmt(tmp, arg)
    underscoredCalls(result, calls, tmp)
    result.add tmp


proc transLastStmt(n, res, bracketExpr: NimNode): (NimNode, NimNode, NimNode) {.since: (1, 1).} =
  # Looks for the last statement of the last statement, etc...
  case n.kind
  of nnkIfExpr, nnkIfStmt, nnkTryStmt, nnkCaseStmt:
    result[0] = copyNimTree(n)
    result[1] = copyNimTree(n)
    result[2] = copyNimTree(n)
    for i in ord(n.kind == nnkCaseStmt)..<n.len:
      (result[0][i], result[1][^1], result[2][^1]) = transLastStmt(n[i], res, bracketExpr)
  of nnkStmtList, nnkStmtListExpr, nnkBlockStmt, nnkBlockExpr, nnkWhileStmt,
      nnkForStmt, nnkElifBranch, nnkElse, nnkElifExpr, nnkOfBranch, nnkExceptBranch:
    result[0] = copyNimTree(n)
    result[1] = copyNimTree(n)
    result[2] = copyNimTree(n)
    if n.len >= 1:
      (result[0][^1], result[1][^1], result[2][^1]) = transLastStmt(n[^1], res, bracketExpr)
  of nnkTableConstr:
    result[1] = n[0][0]
    result[2] = n[0][1]
    if bracketExpr.len == 1:
      bracketExpr.add([newCall(bindSym"typeof", newEmptyNode()), newCall(
          bindSym"typeof", newEmptyNode())])
    template adder(res, k, v) = res[k] = v
    result[0] = getAst(adder(res, n[0][0], n[0][1]))
  of nnkCurly:
    result[2] = n[0]
    if bracketExpr.len == 1:
      bracketExpr.add(newCall(bindSym"typeof", newEmptyNode()))
    template adder(res, v) = res.incl(v)
    result[0] = getAst(adder(res, n[0]))
  else:
    result[2] = n
    if bracketExpr.len == 1:
      bracketExpr.add(newCall(bindSym"typeof", newEmptyNode()))
    template adder(res, v) = res.add(v)
    result[0] = getAst(adder(res, n))

macro collect*(init, body: untyped): untyped {.since: (1, 1).} =
  ## Comprehension for seq/set/table collections. ``init`` is
  ## the init call, and so custom collections are supported.
  ##
  ## The last statement of ``body`` has special syntax that specifies
  ## the collection's add operation. Use ``{e}`` for set's ``incl``,
  ## ``{k: v}`` for table's ``[]=`` and ``e`` for seq's ``add``.
  ##
  ## The ``init`` proc can be called with any number of arguments,
  ## i.e. ``initTable(initialSize)``.
  runnableExamples:
    import sets, tables
    let data = @["bird", "word"]
    ## seq:
    let k = collect(newSeq):
      for i, d in data.pairs:
        if i mod 2 == 0: d

    assert k == @["bird"]
    ## seq with initialSize:
    let x = collect(newSeqOfCap(4)):
      for i, d in data.pairs:
        if i mod 2 == 0: d

    assert x == @["bird"]
    ## HashSet:
    let y = initHashSet.collect:
      for d in data.items: {d}

    assert y == data.toHashSet
    ## Table:
    let z = collect(initTable(2)):
      for i, d in data.pairs: {i: d}

    assert z == {0: "bird", 1: "word"}.toTable
  # analyse the body, find the deepest expression 'it' and replace it via
  # 'result.add it'
  let res = genSym(nskVar, "collectResult")
  expectKind init, {nnkCall, nnkIdent, nnkSym}
  let bracketExpr = newTree(nnkBracketExpr,
    if init.kind == nnkCall: init[0] else: init)
  let (resBody, keyType, valueType) = transLastStmt(body, res, bracketExpr)
  if bracketExpr.len == 3:
    bracketExpr[1][1] = keyType
    bracketExpr[2][1] = valueType
  else:
    bracketExpr[1][1] = valueType
  let call = newTree(nnkCall, bracketExpr)
  if init.kind == nnkCall:
    for i in 1 ..< init.len:
      call.add init[i]
  result = newTree(nnkStmtListExpr, newVarStmt(res, call), resBody, res)

when isMainModule:
  since (1, 1):
    block dup_with_field:
      type
        Foo = object
          col, pos: int
          name: string

      proc inc_col(foo: var Foo) = inc(foo.col)
      proc inc_pos(foo: var Foo) = inc(foo.pos)
      proc name_append(foo: var Foo, s: string) = foo.name &= s

      let a = Foo(col: 1, pos: 2, name: "foo")
      block:
        let b = a.dup(inc_col, inc_pos):
          _.pos = 3
          name_append("bar")
          inc_pos

        doAssert(b == Foo(col: 2, pos: 4, name: "foobar"))

      block:
        let b = a.dup(inc_col, pos = 3, name = "bar"):
          name_append("bar")
          inc_pos

        doAssert(b == Foo(col: 2, pos: 4, name: "barbar"))

    import algorithm

    var a = @[1, 2, 3, 4, 5, 6, 7, 8, 9]
    doAssert dup(a, sort(_)) == sorted(a)
    doAssert a.dup(sort) == sorted(a)
    #Chaining:
    var aCopy = a
    aCopy.insert(10)
    doAssert a.dup(insert(10)).dup(sort()) == sorted(aCopy)

    import random

    const b = @[0, 1, 2]
    let c = b.dup shuffle()
    doAssert c[0] == 1
    doAssert c[1] == 0

    #test collect
    import sets, tables

    let data = @["bird", "word"] # if this gets stuck in your head, its not my fault
    assert collect(newSeq, for (i, d) in data.pairs: (if i mod 2 == 0: d)) == @["bird"]
    assert collect(initTable(2), for (i, d) in data.pairs: {i: d}) == {0: "bird",
          1: "word"}.toTable
    assert initHashSet.collect(for d in data.items: {d}) == data.toHashSet

    let x = collect(newSeqOfCap(4)):
        for (i, d) in data.pairs:
          if i mod 2 == 0: d
    assert x == @["bird"]

    # bug #12874

    let bug1 = collect(
        newSeq,
        for (i, d) in data.pairs:(
          block:
            if i mod 2 == 0:
              d
            else:
              d & d
          )
    )
    assert bug1 == @["bird", "wordword"]

    import strutils
    let y = collect(newSeq):
      for (i, d) in data.pairs:
        try: parseInt(d) except: 0
    assert y == @[0, 0]

    let z = collect(newSeq):
      for (i, d) in data.pairs:
        case d
        of "bird": "word"
        else: d
    assert z == @["word", "word"]


    proc tforum =
      let ans = collect(newSeq):
        for y in 0..10:
          if y mod 5 == 2:
            for x in 0..y:
              x

    tforum()
