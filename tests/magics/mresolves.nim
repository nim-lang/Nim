import std/macros

macro overloadExistsImpl(x: typed): bool = 
  newLit(x != nil)

template overloadExists*(a: untyped): bool =
  overloadExistsImpl(resolveSymbol(a))

type InstantiationInfo = type(instantiationInfo())

proc toStr(info: InstantiationInfo | LineInfo): string =
  const offset = 1
  result = info.filename & ":" & $info.line & ":" & $(info.column + offset)

proc inspectImpl*(s: var string, a: NimNode, resolveLet: bool) =
  var a = a
  if resolveLet:
    a = a.getImpl
    a = a[2]
  case a.kind
  of nnkClosedSymChoice:
    s.add "closedSymChoice:"
    for ai in a:
      s.add "\n  "
      inspectImpl(s, ai, false)
  of nnkSym:
    var a2 = a.getImpl
    const callables = {nnkProcDef, nnkMethodDef, nnkConverterDef, nnkMacroDef, nnkTemplateDef, nnkIteratorDef}
    if a2.kind in callables:
      let a20=a2
      a2 = newTree(a20.kind)
      for i, ai in a20:
        a2.add if i notin [6]: ai else: newEmptyNode()
    s.add a2.lineInfoObj.toStr & " " & a2.repr
  else: error($a.kind, a)

macro inspect*(a: typed, resolveLet: static bool = false): untyped =
  var a = a
  if a.kind == nnkTupleConstr:
    a = a[0]
  var s: string
  s.add a.lineInfoObj.toStr & ": "
  s.add a.repr & " = "
  inspectImpl(s, a, resolveLet)
  when defined(nimTestsResolvesDebug):
    echo s
