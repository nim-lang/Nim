import std/[tables, options, macros]

import jsontree

proc `%`*(s: string): JsonNode =
  ## Generic constructor for JSON data. Creates a new `JString JsonNode`.
  result = JsonNode(kind: JString, str: s)

proc `%`*(n: uint): JsonNode =
  ## Generic constructor for JSON data. Creates a new `JInt JsonNode`.
  if n > cast[uint](int.high):
    result = newJRawNumber($n)
  else:
    result = JsonNode(kind: JInt, num: BiggestInt(n))

proc `%`*(n: int): JsonNode =
  ## Generic constructor for JSON data. Creates a new `JInt JsonNode`.
  result = JsonNode(kind: JInt, num: n)

proc `%`*(n: BiggestUInt): JsonNode =
  ## Generic constructor for JSON data. Creates a new `JInt JsonNode`.
  if n > cast[BiggestUInt](BiggestInt.high):
    result = newJRawNumber($n)
  else:
    result = JsonNode(kind: JInt, num: BiggestInt(n))

proc `%`*(n: BiggestInt): JsonNode =
  ## Generic constructor for JSON data. Creates a new `JInt JsonNode`.
  result = JsonNode(kind: JInt, num: n)

proc `%`*(n: float): JsonNode =
  ## Generic constructor for JSON data. Creates a new `JFloat JsonNode`.
  runnableExamples:
    assert $(%[NaN, Inf, -Inf, 0.0, -0.0, 1.0, 1e-2]) == """["nan","inf","-inf",0.0,-0.0,1.0,0.01]"""
    assert (%NaN).kind == JString
    assert (%0.0).kind == JFloat
  # for those special cases, we could also have used `newJRawNumber` but then
  # it would've been inconsisten with the case of `parseJson` vs `%` for representing them.
  if n != n: newJString("nan")
  elif n == Inf: newJString("inf")
  elif n == -Inf: newJString("-inf")
  else: JsonNode(kind: JFloat, fnum: n)

proc `%`*(b: bool): JsonNode =
  ## Generic constructor for JSON data. Creates a new `JBool JsonNode`.
  result = JsonNode(kind: JBool, bval: b)

proc `%`*(keyVals: openArray[tuple[key: string, val: JsonNode]]): JsonNode =
  ## Generic constructor for JSON data. Creates a new `JObject JsonNode`
  if keyVals.len == 0: return newJArray()
  result = newJObject()
  for key, val in items(keyVals): result.fields[key] = val

template `%`*(j: JsonNode): JsonNode = j

proc `%`*[T](elements: openArray[T]): JsonNode =
  ## Generic constructor for JSON data. Creates a new `JArray JsonNode`
  result = newJArray()
  for elem in elements: result.add(%elem)

proc `%`*[T](table: Table[string, T]|OrderedTable[string, T]): JsonNode =
  ## Generic constructor for JSON data. Creates a new `JObject JsonNode`.
  result = newJObject()
  for k, v in table: result[k] = %v

proc `%`*[T](opt: Option[T]): JsonNode =
  ## Generic constructor for JSON data. Creates a new `JNull JsonNode`
  ## if `opt` is empty, otherwise it delegates to the underlying value.
  if opt.isSome: %opt.get else: newJNull()

when false:
  # For 'consistency' we could do this, but that only pushes people further
  # into that evil comfort zone where they can use Nim without understanding it
  # causing problems later on.
  proc `%`*(elements: set[bool]): JsonNode =
    ## Generic constructor for JSON data. Creates a new `JObject JsonNode`.
    ## This can only be used with the empty set `{}` and is supported
    ## to prevent the gotcha `%*{}` which used to produce an empty
    ## JSON array.
    result = newJObject()
    assert false notin elements, "usage error: only empty sets allowed"
    assert true notin elements, "usage error: only empty sets allowed"

proc `%`*[T: object](o: T): JsonNode =
  ## Construct JsonNode from tuples and objects.
  result = newJObject()
  for k, v in o.fieldPairs: result[k] = %v

proc `%`*(o: ref object): JsonNode =
  ## Generic constructor for JSON data. Creates a new `JObject JsonNode`
  if o.isNil:
    result = newJNull()
  else:
    result = %(o[])

proc `%`*(o: enum): JsonNode =
  ## Construct a JsonNode that represents the specified enum value as a
  ## string. Creates a new `JString JsonNode`.
  result = %($o)

proc toJsonImpl(x: NimNode): NimNode =
  case x.kind
  of nnkBracket: # array
    if x.len == 0: return newCall(bindSym"newJArray")
    result = newNimNode(nnkBracket)
    for i in 0 ..< x.len:
      result.add(toJsonImpl(x[i]))
    result = newCall(bindSym("%", brOpen), result)
  of nnkTableConstr: # object
    if x.len == 0: return newCall(bindSym"newJObject")
    result = newNimNode(nnkTableConstr)
    for i in 0 ..< x.len:
      x[i].expectKind nnkExprColonExpr
      result.add newTree(nnkExprColonExpr, x[i][0], toJsonImpl(x[i][1]))
    result = newCall(bindSym("%", brOpen), result)
  of nnkCurly: # empty object
    x.expectLen(0)
    result = newCall(bindSym"newJObject")
  of nnkNilLit:
    result = newCall(bindSym"newJNull")
  of nnkPar:
    if x.len == 1: result = toJsonImpl(x[0])
    else: result = newCall(bindSym("%", brOpen), x)
  else:
    result = newCall(bindSym("%", brOpen), x)

macro `%*`*(x: untyped): untyped =
  ## Convert an expression to a JsonNode directly, without having to specify
  ## `%` for every element.
  result = toJsonImpl(x)