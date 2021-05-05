from std/strutils import cmpIgnoreStyle
import std/macros
import ast
from idents import PIdent, IdentCache
from lineinfos import TLineInfo

template elementType*(T: typedesc): typedesc =
  typeof(block:
    var a: T
    for ai in a: ai)

proc fromLit*(a: PNode, T: typedesc): auto =
  ## generic PNode => type
  ## see also reverse operation `toLit`
  when T is set:
    result = default(T)
    type Ti = elementType(T)
    for ai in a:
      result.incl Ti(ai.intVal)
  else:
    static: doAssert false, "not yet supported: " & $T # add as needed

proc toLit*[T](a: T): PNode =
  ## generic type => PNode
  ## see also reverse operation `fromLit`
  # xxx also allow an optional `info` param
  when false: discard
  elif T is string: newStrNode(nkStrLit, a)
  elif T is PIdent:
    result = newNode(nkIdent)
    result.ident = a
  elif T is Ordinal: newIntNode(nkIntLit, a.ord)
  elif T is (proc): newNode(nkNilLit)
  elif T is ref:
    if a == nil: newNode(nkNilLit)
    else: toLit(a[])
  elif T is tuple:
    result = newTree(nkTupleConstr)
    for ai in fields(a): result.add toLit(ai)
  elif T is seq | array:
    result = newNode(nkBracket)
    for ai in a:
      result.add toLit(ai)
  elif T is object:
    result = newTree(nkObjConstr)
    result.add(newNode(nkEmpty))
    for k, ai in fieldPairs(a):
      let reti = newNode(nkExprColonExpr)
      reti.add k.toLit
      reti.add ai.toLit
      result.add reti
  else:
    static: doAssert false, "not yet supported: " & $T # add as needed

type
  GenContext* = object
    cache*: IdentCache
    info*: TLineInfo
  ContextVars = seq[tuple[name: string, val: NimNode]]

proc genPNodeImpl(c: NimNode, code: var NimNode, vals: ContextVars, n: NimNode): NimNode =
  if n.kind == nnkIdent:
    for v in vals:
      if n.strVal.cmpIgnoreStyle(v.name) == 0:
        return v.val
  result = genSym(nskVar, "ret")
  let kind2 = n.kind.ord.TNodeKind.newLit
  code.add quote do:
    # alternatively, get `info` from `n.info`, which requires exposing this in macros.
    var `result` = newNodeI(`kind2`, `c`.info)
  # keep in sync with `ast.TNode`
  case n.kind
  of nnkCharLit..nnkUInt64Lit:
    let val = n.intVal.newLit
    code.add quote do:
      `result`.intVal = `val`
  of nnkFloatLit..nnkFloat128Lit:
    let val = n.floatVal.newLit
    code.add quote do:
      `result`.floatVal = `val`
    let tmp = quote do:
      `result`.floatVal = `val`
  of nnkStrLit..nnkTripleStrLit:
    let val = n.strVal.newLit
    code.add quote do:
      `result`.strVal = `val`
  of nnkIdent:
    let val = n.strVal.newLit
    code.add quote do:
      `result`.ident = getIdent(`c`.cache, `val`)
  of nnkSym: doAssert false # not implemented, but shouldn't be needed
  else:
    for ni in n:
      let reti = genPNodeImpl(c, code, vals, ni)
      code.add quote do:
        `result`.add `reti`

macro genPNode*(c: GenContext, args: varargs[untyped]): PNode =
  ## Converts an AST into a PNode, and works similarly to std/genasts.
  ## This can simplify writing compiler code, avoiding to manually write `PNode` ASTs.
  runnableExamples:
    import idents, renderer
    let cache = newIdentCache()
    let a = [1,2]
    let b = cache.getIdent("foo")
    var c = GenContext(cache: cache)
    let node = genPNode(c, a, b):
      for i in 0..<3:
        let b = @[i, 1]
        echo (a, b, i, "abc")
    let s = node.renderTree
    assert s == """

for i in 0 ..< 3:
  let foo = @[i, 1]
  echo ([1, 2], foo, i, "abc")""", s

  result = newStmtList()
  let m = args.len - 1
  var vals: ContextVars
  vals.setLen m
  for i in 0..<m:
    let ai = args[i]
    assert ai.kind == nnkIdent, $ai.kind
    vals[i].name = ai.repr
    let ni = genSym(nskVar, vals[i].name)
    vals[i].val = ni
    result.add quote do:
      var `ni` = toLit(`ai`)
  let ret = genPNodeImpl(c, result, vals, args[^1])
  result.add ret
