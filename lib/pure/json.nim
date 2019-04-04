#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Andreas Rumpf, Dominik Picheta
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements a simple high performance `JSON`:idx:
## parser. JSON (JavaScript Object Notation) is a lightweight
## data-interchange format that is easy for humans to read and write
## (unlike XML). It is easy for machines to parse and generate.
## JSON is based on a subset of the JavaScript Programming Language,
## Standard ECMA-262 3rd Edition - December 1999.
##
## Overview
## ========
##
## Parsing JSON
## ------------
##
## JSON often arrives into your program (via an API or a file) as a ``string``.
## The first step is to change it from its serialized form into a nested object
## structure called a ``JsonNode``.
##
## The ``parseJson`` procedure takes a string containing JSON and returns a
## ``JsonNode`` object. This is an object variant and it is either a
## ``JObject``, ``JArray``, ``JString``, ``JInt``, ``JFloat``, ``JBool`` or
## ``JNull``. You check the kind of this object variant by using the ``kind``
## accessor.
##
## For a ``JsonNode`` who's kind is ``JObject``, you can acess its fields using
## the ``[]`` operator. The following example shows how to do this:
##
## .. code-block:: Nim
##   import json
##
##   let jsonNode = parseJson("""{"key": 3.14}""")
##
##   doAssert jsonNode.kind == JObject
##   doAssert jsonNode["key"].kind == JFloat
##
## Reading values
## --------------
##
## Once you have a ``JsonNode``, retrieving the values can then be achieved
## by using one of the helper procedures, which include:
##
## * ``getInt``
## * ``getFloat``
## * ``getStr``
## * ``getBool``
##
## To retrieve the value of ``"key"`` you can do the following:
##
## .. code-block:: Nim
##   import json
##
##   let jsonNode = parseJson("""{"key": 3.14}""")
##
##   doAssert jsonNode["key"].getFloat() == 3.14
##
## **Important:** The ``[]`` operator will raise an exception when the
## specified field does not exist.
##
## Handling optional keys
## ----------------------
##
## By using the ``{}`` operator instead of ``[]``, it will return ``nil``
## when the field is not found. The ``get``-family of procedures will return a
## type's default value when called on ``nil``.
##
## .. code-block:: Nim
##   import json
##
##   let jsonNode = parseJson("{}")
##
##   doAssert jsonNode{"nope"}.getInt() == 0
##   doAssert jsonNode{"nope"}.getFloat() == 0
##   doAssert jsonNode{"nope"}.getStr() == ""
##   doAssert jsonNode{"nope"}.getBool() == false
##
## Using default values
## --------------------
##
## The ``get``-family helpers also accept an additional parameter which allow
## you to fallback to a default value should the key's values be ``null``:
##
## .. code-block:: Nim
##   import json
##
##   let jsonNode = parseJson("""{"key": 3.14, "key2": null}""")
##
##   doAssert jsonNode["key"].getFloat(6.28) == 3.14
##   doAssert jsonNode["key2"].getFloat(3.14) == 3.14
##   doAssert jsonNode{"nope"}.getFloat(3.14) == 3.14 # note the {}
##
## Unmarshalling
## -------------
##
## In addition to reading dynamic data, Nim can also unmarshall JSON directly
## into a type with the ``to`` macro.
##
## .. code-block:: Nim
##   import json
##
##   type
##     User = object
##       name: string
##       age: int
##
##   let userJson = parseJson("""{ "name": "Nim", "age": 12 }""")
##   let user = to(userJson, User)
##
## Creating JSON
## =============
##
## This module can also be used to comfortably create JSON using the ``%*``
## operator:
##
## .. code-block:: nim
##   import json
##
##   var hisName = "John"
##   let herAge = 31
##   var j = %*
##     [
##       { "name": hisName, "age": 30 },
##       { "name": "Susan", "age": herAge }
##     ]
##
##   var j2 = %* {"name": "Isaac", "books": ["Robot Dreams"]}
##   j2["details"] = %* {"age":35, "pi":3.1415}
##   echo j2

runnableExamples:
  ## Note: for JObject, key ordering is preserved, unlike in some languages,
  ## this is convenient for some use cases. Example:
  type Foo = object
    a1, a2, a0, a3, a4: int
  doAssert $(%* Foo()) == """{"a1":0,"a2":0,"a0":0,"a3":0,"a4":0}"""

import
  hashes, tables, strutils, lexbase, streams, unicode, macros, parsejson,
  typetraits, options

export
  tables.`$`

export
  parsejson.JsonEventKind, parsejson.JsonError, JsonParser, JsonKindError,
  open, close, str, getInt, getFloat, kind, getColumn, getLine, getFilename,
  errorMsg, errorMsgExpected, next, JsonParsingError, raiseParseErr

when defined(nimJsonGet):
  {.pragma: deprecatedGet, deprecated.}
else:
  {.pragma: deprecatedGet.}

type
  JsonNodeKind* = enum ## possible JSON node types
    JNull,
    JBool,
    JInt,
    JFloat,
    JString,
    JObject,
    JArray

  JsonNode* = ref JsonNodeObj ## JSON node
  JsonNodeObj* {.acyclic.} = object
    case kind*: JsonNodeKind
    of JString:
      str*: string
    of JInt:
      num*: BiggestInt
    of JFloat:
      fnum*: float
    of JBool:
      bval*: bool
    of JNull:
      nil
    of JObject:
      fields*: OrderedTable[string, JsonNode]
    of JArray:
      elems*: seq[JsonNode]

proc newJString*(s: string): JsonNode =
  ## Creates a new `JString JsonNode`.
  new(result)
  result.kind = JString
  result.str = s

proc newJStringMove(s: string): JsonNode =
  new(result)
  result.kind = JString
  shallowCopy(result.str, s)

proc newJInt*(n: BiggestInt): JsonNode =
  ## Creates a new `JInt JsonNode`.
  new(result)
  result.kind = JInt
  result.num  = n

proc newJFloat*(n: float): JsonNode =
  ## Creates a new `JFloat JsonNode`.
  new(result)
  result.kind = JFloat
  result.fnum  = n

proc newJBool*(b: bool): JsonNode =
  ## Creates a new `JBool JsonNode`.
  new(result)
  result.kind = JBool
  result.bval = b

proc newJNull*(): JsonNode =
  ## Creates a new `JNull JsonNode`.
  new(result)

proc newJObject*(): JsonNode =
  ## Creates a new `JObject JsonNode`
  new(result)
  result.kind = JObject
  result.fields = initOrderedTable[string, JsonNode](4)

proc newJArray*(): JsonNode =
  ## Creates a new `JArray JsonNode`
  new(result)
  result.kind = JArray
  result.elems = @[]

proc getStr*(n: JsonNode, default: string = ""): string =
  ## Retrieves the string value of a `JString JsonNode`.
  ##
  ## Returns ``default`` if ``n`` is not a ``JString``, or if ``n`` is nil.
  if n.isNil or n.kind != JString: return default
  else: return n.str

proc getInt*(n: JsonNode, default: int = 0): int =
  ## Retrieves the int value of a `JInt JsonNode`.
  ##
  ## Returns ``default`` if ``n`` is not a ``JInt``, or if ``n`` is nil.
  if n.isNil or n.kind != JInt: return default
  else: return int(n.num)

proc getBiggestInt*(n: JsonNode, default: BiggestInt = 0): BiggestInt =
  ## Retrieves the BiggestInt value of a `JInt JsonNode`.
  ##
  ## Returns ``default`` if ``n`` is not a ``JInt``, or if ``n`` is nil.
  if n.isNil or n.kind != JInt: return default
  else: return n.num

proc getNum*(n: JsonNode, default: BiggestInt = 0): BiggestInt {.deprecated: "use getInt or getBiggestInt instead".} =
  ## **Deprecated since v0.18.2:** use ``getInt`` or ``getBiggestInt`` instead.
  getBiggestInt(n, default)

proc getFloat*(n: JsonNode, default: float = 0.0): float =
  ## Retrieves the float value of a `JFloat JsonNode`.
  ##
  ## Returns ``default`` if ``n`` is not a ``JFloat`` or ``JInt``, or if ``n`` is nil.
  if n.isNil: return default
  case n.kind
  of JFloat: return n.fnum
  of JInt: return float(n.num)
  else: return default

proc getFNum*(n: JsonNode, default: float = 0.0): float {.deprecated: "use getFloat instead".} =
  ## **Deprecated since v0.18.2:** use ``getFloat`` instead.
  getFloat(n, default)

proc getBool*(n: JsonNode, default: bool = false): bool =
  ## Retrieves the bool value of a `JBool JsonNode`.
  ##
  ## Returns ``default`` if ``n`` is not a ``JBool``, or if ``n`` is nil.
  if n.isNil or n.kind != JBool: return default
  else: return n.bval

proc getBVal*(n: JsonNode, default: bool = false): bool {.deprecated: "use getBool instead".} =
  ## **Deprecated since v0.18.2:** use ``getBool`` instead.
  getBool(n, default)

proc getFields*(n: JsonNode,
    default = initOrderedTable[string, JsonNode](4)):
        OrderedTable[string, JsonNode] =
  ## Retrieves the key, value pairs of a `JObject JsonNode`.
  ##
  ## Returns ``default`` if ``n`` is not a ``JObject``, or if ``n`` is nil.
  if n.isNil or n.kind != JObject: return default
  else: return n.fields

proc getElems*(n: JsonNode, default: seq[JsonNode] = @[]): seq[JsonNode] =
  ## Retrieves the array of a `JArray JsonNode`.
  ##
  ## Returns ``default`` if ``n`` is not a ``JArray``, or if ``n`` is nil.
  if n.isNil or n.kind != JArray: return default
  else: return n.elems

proc add*(father, child: JsonNode) =
  ## Adds `child` to a JArray node `father`.
  assert father.kind == JArray
  father.elems.add(child)

proc add*(obj: JsonNode, key: string, val: JsonNode) =
  ## Sets a field from a `JObject`.
  assert obj.kind == JObject
  obj.fields[key] = val

proc `%`*(s: string): JsonNode =
  ## Generic constructor for JSON data. Creates a new `JString JsonNode`.
  new(result)
  result.kind = JString
  result.str = s

proc `%`*(n: uint): JsonNode =
  ## Generic constructor for JSON data. Creates a new `JInt JsonNode`.
  new(result)
  result.kind = JInt
  result.num  = BiggestInt(n)

proc `%`*(n: int): JsonNode =
  ## Generic constructor for JSON data. Creates a new `JInt JsonNode`.
  new(result)
  result.kind = JInt
  result.num  = n

proc `%`*(n: BiggestUInt): JsonNode =
  ## Generic constructor for JSON data. Creates a new `JInt JsonNode`.
  new(result)
  result.kind = JInt
  result.num  = BiggestInt(n)

proc `%`*(n: BiggestInt): JsonNode =
  ## Generic constructor for JSON data. Creates a new `JInt JsonNode`.
  new(result)
  result.kind = JInt
  result.num  = n

proc `%`*(n: float): JsonNode =
  ## Generic constructor for JSON data. Creates a new `JFloat JsonNode`.
  new(result)
  result.kind = JFloat
  result.fnum  = n

proc `%`*(b: bool): JsonNode =
  ## Generic constructor for JSON data. Creates a new `JBool JsonNode`.
  new(result)
  result.kind = JBool
  result.bval = b

proc `%`*(keyVals: openArray[tuple[key: string, val: JsonNode]]): JsonNode =
  ## Generic constructor for JSON data. Creates a new `JObject JsonNode`
  if keyvals.len == 0: return newJArray()
  result = newJObject()
  for key, val in items(keyVals): result.fields[key] = val

template `%`*(j: JsonNode): JsonNode = j

proc `%`*[T](elements: openArray[T]): JsonNode =
  ## Generic constructor for JSON data. Creates a new `JArray JsonNode`
  result = newJArray()
  for elem in elements: result.add(%elem)

proc `%`*[T](table: Table[string, T]|OrderedTable[string, T]): JsonNode =
  ## Generic constructor for JSON data. Creates a new ``JObject JsonNode``.
  result = newJObject()
  for k, v in table: result[k] = %v

proc `%`*[T](opt: Option[T]): JsonNode =
  ## Generic constructor for JSON data. Creates a new ``JNull JsonNode``
  ## if ``opt`` is empty, otherwise it delegates to the underlying value.
  if opt.isSome: %opt.get else: newJNull()

when false:
  # For 'consistency' we could do this, but that only pushes people further
  # into that evil comfort zone where they can use Nim without understanding it
  # causing problems later on.
  proc `%`*(elements: set[bool]): JsonNode =
    ## Generic constructor for JSON data. Creates a new `JObject JsonNode`.
    ## This can only be used with the empty set ``{}`` and is supported
    ## to prevent the gotcha ``%*{}`` which used to produce an empty
    ## JSON array.
    result = newJObject()
    assert false notin elements, "usage error: only empty sets allowed"
    assert true notin elements, "usage error: only empty sets allowed"

proc `[]=`*(obj: JsonNode, key: string, val: JsonNode) {.inline.} =
  ## Sets a field from a `JObject`.
  assert(obj.kind == JObject)
  obj.fields[key] = val

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
  ## string. Creates a new ``JString JsonNode``.
  result = %($o)

proc toJson(x: NimNode): NimNode {.compiletime.} =
  case x.kind
  of nnkBracket: # array
    if x.len == 0: return newCall(bindSym"newJArray")
    result = newNimNode(nnkBracket)
    for i in 0 ..< x.len:
      result.add(toJson(x[i]))
    result = newCall(bindSym("%", brOpen), result)
  of nnkTableConstr: # object
    if x.len == 0: return newCall(bindSym"newJObject")
    result = newNimNode(nnkTableConstr)
    for i in 0 ..< x.len:
      x[i].expectKind nnkExprColonExpr
      result.add newTree(nnkExprColonExpr, x[i][0], toJson(x[i][1]))
    result = newCall(bindSym("%", brOpen), result)
  of nnkCurly: # empty object
    x.expectLen(0)
    result = newCall(bindSym"newJObject")
  of nnkNilLit:
    result = newCall(bindSym"newJNull")
  of nnkPar:
    if x.len == 1: result = toJson(x[0])
    else: result = newCall(bindSym("%", brOpen), x)
  else:
    result = newCall(bindSym("%", brOpen), x)

macro `%*`*(x: untyped): untyped =
  ## Convert an expression to a JsonNode directly, without having to specify
  ## `%` for every element.
  result = toJson(x)

proc `==`* (a, b: JsonNode): bool =
  ## Check two nodes for equality
  if a.isNil:
    if b.isNil: return true
    return false
  elif b.isNil or a.kind != b.kind:
    return false
  else:
    case a.kind
    of JString:
      result = a.str == b.str
    of JInt:
      result = a.num == b.num
    of JFloat:
      result = a.fnum == b.fnum
    of JBool:
      result = a.bval == b.bval
    of JNull:
      result = true
    of JArray:
      result = a.elems == b.elems
    of JObject:
     # we cannot use OrderedTable's equality here as
     # the order does not matter for equality here.
     if a.fields.len != b.fields.len: return false
     for key, val in a.fields:
       if not b.fields.hasKey(key): return false
       if b.fields[key] != val: return false
     result = true

proc hash*(n: OrderedTable[string, JsonNode]): Hash {.noSideEffect.}

proc hash*(n: JsonNode): Hash =
  ## Compute the hash for a JSON node
  case n.kind
  of JArray:
    result = hash(n.elems)
  of JObject:
    result = hash(n.fields)
  of JInt:
    result = hash(n.num)
  of JFloat:
    result = hash(n.fnum)
  of JBool:
    result = hash(n.bval.int)
  of JString:
    result = hash(n.str)
  of JNull:
    result = Hash(0)

proc hash*(n: OrderedTable[string, JsonNode]): Hash =
  for key, val in n:
    result = result xor (hash(key) !& hash(val))
  result = !$result

proc len*(n: JsonNode): int =
  ## If `n` is a `JArray`, it returns the number of elements.
  ## If `n` is a `JObject`, it returns the number of pairs.
  ## Else it returns 0.
  case n.kind
  of JArray: result = n.elems.len
  of JObject: result = n.fields.len
  else: discard

proc `[]`*(node: JsonNode, name: string): JsonNode {.inline, deprecatedGet.} =
  ## Gets a field from a `JObject`, which must not be nil.
  ## If the value at `name` does not exist, raises KeyError.
  ##
  ## **Note:** The behaviour of this procedure changed in version 0.14.0. To
  ## get a list of usages and to restore the old behaviour of this procedure,
  ## compile with the ``-d:nimJsonGet`` flag.
  assert(not isNil(node))
  assert(node.kind == JObject)
  when defined(nimJsonGet):
    if not node.fields.hasKey(name): return nil
  result = node.fields[name]

proc `[]`*(node: JsonNode, index: int): JsonNode {.inline.} =
  ## Gets the node at `index` in an Array. Result is undefined if `index`
  ## is out of bounds, but as long as array bound checks are enabled it will
  ## result in an exception.
  assert(not isNil(node))
  assert(node.kind == JArray)
  return node.elems[index]

proc hasKey*(node: JsonNode, key: string): bool =
  ## Checks if `key` exists in `node`.
  assert(node.kind == JObject)
  result = node.fields.hasKey(key)

proc contains*(node: JsonNode, key: string): bool =
  ## Checks if `key` exists in `node`.
  assert(node.kind == JObject)
  node.fields.hasKey(key)

proc contains*(node: JsonNode, val: JsonNode): bool =
  ## Checks if `val` exists in array `node`.
  assert(node.kind == JArray)
  find(node.elems, val) >= 0

proc existsKey*(node: JsonNode, key: string): bool {.deprecated: "use hasKey instead".} = node.hasKey(key)
  ## **Deprecated:** use `hasKey` instead.

proc `{}`*(node: JsonNode, keys: varargs[string]): JsonNode =
  ## Traverses the node and gets the given value. If any of the
  ## keys do not exist, returns ``nil``. Also returns ``nil`` if one of the
  ## intermediate data structures is not an object.
  ##
  ## This proc can be used to create tree structures on the
  ## fly (sometimes called `autovivification`:idx:):
  ##
  ## .. code-block:: nim
  ##   myjson{"parent", "child", "grandchild"} = newJInt(1)
  ##
  result = node
  for key in keys:
    if isNil(result) or result.kind != JObject:
      return nil
    result = result.fields.getOrDefault(key)

proc `{}`*(node: JsonNode, index: varargs[int]): JsonNode =
  ## Traverses the node and gets the given value. If any of the
  ## indexes do not exist, returns ``nil``. Also returns ``nil`` if one of the
  ## intermediate data structures is not an array.
  result = node
  for i in index:
    if isNil(result) or result.kind != JArray or i >= node.len:
      return nil
    result = result.elems[i]

proc getOrDefault*(node: JsonNode, key: string): JsonNode =
  ## Gets a field from a `node`. If `node` is nil or not an object or
  ## value at `key` does not exist, returns nil
  if not isNil(node) and node.kind == JObject:
    result = node.fields.getOrDefault(key)

template simpleGetOrDefault*{`{}`(node, [key])}(node: JsonNode, key: string): JsonNode = node.getOrDefault(key)

proc `{}=`*(node: JsonNode, keys: varargs[string], value: JsonNode) =
  ## Traverses the node and tries to set the value at the given location
  ## to ``value``. If any of the keys are missing, they are added.
  var node = node
  for i in 0..(keys.len-2):
    if not node.hasKey(keys[i]):
      node[keys[i]] = newJObject()
    node = node[keys[i]]
  node[keys[keys.len-1]] = value

proc delete*(obj: JsonNode, key: string) =
  ## Deletes ``obj[key]``.
  assert(obj.kind == JObject)
  if not obj.fields.hasKey(key):
    raise newException(KeyError, "key not in object")
  obj.fields.del(key)

proc copy*(p: JsonNode): JsonNode =
  ## Performs a deep copy of `a`.
  case p.kind
  of JString:
    result = newJString(p.str)
  of JInt:
    result = newJInt(p.num)
  of JFloat:
    result = newJFloat(p.fnum)
  of JBool:
    result = newJBool(p.bval)
  of JNull:
    result = newJNull()
  of JObject:
    result = newJObject()
    for key, val in pairs(p.fields):
      result.fields[key] = copy(val)
  of JArray:
    result = newJArray()
    for i in items(p.elems):
      result.elems.add(copy(i))

# ------------- pretty printing ----------------------------------------------

proc indent(s: var string, i: int) =
  s.add(spaces(i))

proc newIndent(curr, indent: int, ml: bool): int =
  if ml: return curr + indent
  else: return indent

proc nl(s: var string, ml: bool) =
  s.add(if ml: "\n" else: " ")

proc escapeJsonUnquoted*(s: string; result: var string) =
  ## Converts a string `s` to its JSON representation without quotes.
  ## Appends to ``result``.
  for c in s:
    case c
    of '\L': result.add("\\n")
    of '\b': result.add("\\b")
    of '\f': result.add("\\f")
    of '\t': result.add("\\t")
    of '\r': result.add("\\r")
    of '"': result.add("\\\"")
    of '\0'..'\7': result.add("\\u000" & $ord(c))
    of '\14'..'\31': result.add("\\u00" & toHex(ord(c), 2))
    of '\\': result.add("\\\\")
    else: result.add(c)

proc escapeJsonUnquoted*(s: string): string =
  ## Converts a string `s` to its JSON representation without quotes.
  result = newStringOfCap(s.len + s.len shr 3)
  escapeJsonUnquoted(s, result)

proc escapeJson*(s: string; result: var string) =
  ## Converts a string `s` to its JSON representation with quotes.
  ## Appends to ``result``.
  result.add("\"")
  escapeJsonUnquoted(s, result)
  result.add("\"")

proc escapeJson*(s: string): string =
  ## Converts a string `s` to its JSON representation with quotes.
  result = newStringOfCap(s.len + s.len shr 3)
  escapeJson(s, result)

proc toPretty(result: var string, node: JsonNode, indent = 2, ml = true,
              lstArr = false, currIndent = 0) =
  case node.kind
  of JObject:
    if lstArr: result.indent(currIndent) # Indentation
    if node.fields.len > 0:
      result.add("{")
      result.nl(ml) # New line
      var i = 0
      for key, val in pairs(node.fields):
        if i > 0:
          result.add(",")
          result.nl(ml) # New Line
        inc i
        # Need to indent more than {
        result.indent(newIndent(currIndent, indent, ml))
        escapeJson(key, result)
        result.add(": ")
        toPretty(result, val, indent, ml, false,
                 newIndent(currIndent, indent, ml))
      result.nl(ml)
      result.indent(currIndent) # indent the same as {
      result.add("}")
    else:
      result.add("{}")
  of JString:
    if lstArr: result.indent(currIndent)
    escapeJson(node.str, result)
  of JInt:
    if lstArr: result.indent(currIndent)
    when defined(js): result.add($node.num)
    else: result.add(node.num)
  of JFloat:
    if lstArr: result.indent(currIndent)
    # Fixme: implement new system.add ops for the JS target
    when defined(js): result.add($node.fnum)
    else: result.add(node.fnum)
  of JBool:
    if lstArr: result.indent(currIndent)
    result.add(if node.bval: "true" else: "false")
  of JArray:
    if lstArr: result.indent(currIndent)
    if len(node.elems) != 0:
      result.add("[")
      result.nl(ml)
      for i in 0..len(node.elems)-1:
        if i > 0:
          result.add(",")
          result.nl(ml) # New Line
        toPretty(result, node.elems[i], indent, ml,
            true, newIndent(currIndent, indent, ml))
      result.nl(ml)
      result.indent(currIndent)
      result.add("]")
    else: result.add("[]")
  of JNull:
    if lstArr: result.indent(currIndent)
    result.add("null")

proc pretty*(node: JsonNode, indent = 2): string =
  ## Returns a JSON Representation of `node`, with indentation and
  ## on multiple lines.
  ##
  ## Similar to prettyprint in Python.
  runnableExamples:
    let j = %* {"name": "Isaac", "books": ["Robot Dreams"],
                "details": {"age":35, "pi":3.1415}}
    doAssert pretty(j) == """
{
  "name": "Isaac",
  "books": [
    "Robot Dreams"
  ],
  "details": {
    "age": 35,
    "pi": 3.1415
  }
}"""
  result = ""
  toPretty(result, node, indent)

proc toUgly*(result: var string, node: JsonNode) =
  ## Converts `node` to its JSON Representation, without
  ## regard for human readability. Meant to improve ``$`` string
  ## conversion performance.
  ##
  ## JSON representation is stored in the passed `result`
  ##
  ## This provides higher efficiency than the ``pretty`` procedure as it
  ## does **not** attempt to format the resulting JSON to make it human readable.
  var comma = false
  case node.kind:
  of JArray:
    result.add "["
    for child in node.elems:
      if comma: result.add ","
      else:     comma = true
      result.toUgly child
    result.add "]"
  of JObject:
    result.add "{"
    for key, value in pairs(node.fields):
      if comma: result.add ","
      else:     comma = true
      key.escapeJson(result)
      result.add ":"
      result.toUgly value
    result.add "}"
  of JString:
    node.str.escapeJson(result)
  of JInt:
    when defined(js): result.add($node.num)
    else: result.add(node.num)
  of JFloat:
    when defined(js): result.add($node.fnum)
    else: result.add(node.fnum)
  of JBool:
    result.add(if node.bval: "true" else: "false")
  of JNull:
    result.add "null"

proc `$`*(node: JsonNode): string =
  ## Converts `node` to its JSON Representation on one line.
  result = newStringOfCap(node.len shl 1)
  toUgly(result, node)

iterator items*(node: JsonNode): JsonNode =
  ## Iterator for the items of `node`. `node` has to be a JArray.
  assert node.kind == JArray
  for i in items(node.elems):
    yield i

iterator mitems*(node: var JsonNode): var JsonNode =
  ## Iterator for the items of `node`. `node` has to be a JArray. Items can be
  ## modified.
  assert node.kind == JArray
  for i in mitems(node.elems):
    yield i

iterator pairs*(node: JsonNode): tuple[key: string, val: JsonNode] =
  ## Iterator for the child elements of `node`. `node` has to be a JObject.
  assert node.kind == JObject
  for key, val in pairs(node.fields):
    yield (key, val)

iterator mpairs*(node: var JsonNode): tuple[key: string, val: var JsonNode] =
  ## Iterator for the child elements of `node`. `node` has to be a JObject.
  ## Values can be modified
  assert node.kind == JObject
  for key, val in mpairs(node.fields):
    yield (key, val)

proc parseJson(p: var JsonParser): JsonNode =
  ## Parses JSON from a JSON Parser `p`.
  case p.tok
  of tkString:
    # we capture 'p.a' here, so we need to give it a fresh buffer afterwards:
    result = newJStringMove(p.a)
    p.a = ""
    discard getTok(p)
  of tkInt:
    result = newJInt(parseBiggestInt(p.a))
    discard getTok(p)
  of tkFloat:
    result = newJFloat(parseFloat(p.a))
    discard getTok(p)
  of tkTrue:
    result = newJBool(true)
    discard getTok(p)
  of tkFalse:
    result = newJBool(false)
    discard getTok(p)
  of tkNull:
    result = newJNull()
    discard getTok(p)
  of tkCurlyLe:
    result = newJObject()
    discard getTok(p)
    while p.tok != tkCurlyRi:
      if p.tok != tkString:
        raiseParseErr(p, "string literal as key")
      var key = p.a
      discard getTok(p)
      eat(p, tkColon)
      var val = parseJson(p)
      result[key] = val
      if p.tok != tkComma: break
      discard getTok(p)
    eat(p, tkCurlyRi)
  of tkBracketLe:
    result = newJArray()
    discard getTok(p)
    while p.tok != tkBracketRi:
      result.add(parseJson(p))
      if p.tok != tkComma: break
      discard getTok(p)
    eat(p, tkBracketRi)
  of tkError, tkCurlyRi, tkBracketRi, tkColon, tkComma, tkEof:
    raiseParseErr(p, "{")

when not defined(js):
  proc parseJson*(s: Stream, filename: string = ""): JsonNode =
    ## Parses from a stream `s` into a `JsonNode`. `filename` is only needed
    ## for nice error messages.
    ## If `s` contains extra data, it will raise `JsonParsingError`.
    var p: JsonParser
    p.open(s, filename)
    try:
      discard getTok(p) # read first token
      result = p.parseJson()
      eat(p, tkEof) # check if there is no extra data
    finally:
      p.close()

  proc parseJson*(buffer: string): JsonNode =
    ## Parses JSON from `buffer`.
    ## If `buffer` contains extra data, it will raise `JsonParsingError`.
    result = parseJson(newStringStream(buffer), "input")

  proc parseFile*(filename: string): JsonNode =
    ## Parses `file` into a `JsonNode`.
    ## If `file` contains extra data, it will raise `JsonParsingError`.
    var stream = newFileStream(filename, fmRead)
    if stream == nil:
      raise newException(IOError, "cannot read from file: " & filename)
    result = parseJson(stream, filename)
else:
  from math import `mod`
  type
    JSObject = object

  proc parseNativeJson(x: cstring): JSObject {.importc: "JSON.parse".}

  proc getVarType(x: JSObject): JsonNodeKind =
    result = JNull
    proc getProtoName(y: JSObject): cstring
      {.importc: "Object.prototype.toString.call".}
    case $getProtoName(x) # TODO: Implicit returns fail here.
    of "[object Array]": return JArray
    of "[object Object]": return JObject
    of "[object Number]":
      if cast[float](x) mod 1.0 == 0:
        return JInt
      else:
        return JFloat
    of "[object Boolean]": return JBool
    of "[object Null]": return JNull
    of "[object String]": return JString
    else: assert false

  proc len(x: JSObject): int =
    assert x.getVarType == JArray
    asm """
      `result` = `x`.length;
    """

  proc `[]`(x: JSObject, y: string): JSObject =
    assert x.getVarType == JObject
    asm """
      `result` = `x`[`y`];
    """

  proc `[]`(x: JSObject, y: int): JSObject =
    assert x.getVarType == JArray
    asm """
      `result` = `x`[`y`];
    """

  proc convertObject(x: JSObject): JsonNode =
    case getVarType(x)
    of JArray:
      result = newJArray()
      for i in 0 ..< x.len:
        result.add(x[i].convertObject())
    of JObject:
      result = newJObject()
      asm """for (var property in `x`) {
        if (`x`.hasOwnProperty(property)) {
      """
      var nimProperty: cstring
      var nimValue: JSObject
      asm "`nimProperty` = property; `nimValue` = `x`[property];"
      result[$nimProperty] = nimValue.convertObject()
      asm "}}"
    of JInt:
      result = newJInt(cast[int](x))
    of JFloat:
      result = newJFloat(cast[float](x))
    of JString:
      result = newJString($cast[cstring](x))
    of JBool:
      result = newJBool(cast[bool](x))
    of JNull:
      result = newJNull()

  proc parseJson*(buffer: string): JsonNode =
    return parseNativeJson(buffer).convertObject()

# -- Json deserialiser macro. --

proc createJsonIndexer(jsonNode: NimNode,
                       index: string | int | NimNode): NimNode
    {.compileTime.} =
  when index is string:
    let indexNode = newStrLitNode(index)
  elif index is int:
    let indexNode = newIntLitNode(index)
  elif index is NimNode:
    let indexNode = index

  result = newNimNode(nnkBracketExpr).add(
    jsonNode,
    indexNode
  )

proc transformJsonIndexer(jsonNode: NimNode): NimNode =
  case jsonNode.kind
  of nnkBracketExpr:
    result = newNimNode(nnkCurlyExpr)
  else:
    result = jsonNode.copy()

  for child in jsonNode:
    result.add(transformJsonIndexer(child))

template verifyJsonKind(node: JsonNode, kinds: set[JsonNodeKind],
                        ast: string) =
  if node.kind notin kinds:
    let msg = "Incorrect JSON kind. Wanted '$1' in '$2' but got '$3'." % [
      $kinds,
      ast,
      $node.kind
    ]
    raise newException(JsonKindError, msg)

proc getEnum(node: JsonNode, ast: string, T: typedesc): T =
  when T is SomeInteger:
    # TODO: I shouldn't need this proc.
    proc convert[T](x: BiggestInt): T = T(x)
    verifyJsonKind(node, {JInt}, ast)
    return convert[T](node.getBiggestInt())
  else:
    verifyJsonKind(node, {JString}, ast)
    return parseEnum[T](node.getStr())

proc toIdentNode(typeNode: NimNode): NimNode =
  ## Converts a Sym type node (returned by getType et al.) into an
  ## Ident node. Placing Sym type nodes inside the resulting code AST is
  ## unsound (according to @Araq) so this is necessary.
  case typeNode.kind
  of nnkSym:
    return newIdentNode($typeNode)
  of nnkBracketExpr:
    result = typeNode
    for i in 0..<len(result):
      result[i] = newIdentNode($result[i])
  of nnkIdent:
    return typeNode
  else:
    doAssert false, "Cannot convert typeNode to an ident node: " & $typeNode.kind

proc createGetEnumCall(jsonNode, kindType: NimNode): NimNode =
  # -> getEnum(`jsonNode`, `kindType`)
  result = newCall(bindSym("getEnum"), jsonNode, toStrLit(jsonNode), kindType)

proc createOfBranchCond(ofBranch, getEnumCall: NimNode): NimNode =
  ## Creates an expression that acts as the condition for an ``of`` branch.
  var cond = newIdentNode("false")
  for ofCond in ofBranch:
    if ofCond.kind == nnkRecList:
      break

    let comparison = infix(getEnumCall, "==", ofCond)
    cond = infix(cond, "or", comparison)

  return cond

proc processObjField(field, jsonNode: NimNode): seq[NimNode] {.compileTime.}
proc processOfBranch(ofBranch, jsonNode, kindType,
                     kindJsonNode: NimNode): seq[NimNode] {.compileTime.} =
  ## Processes each field inside of an object's ``of`` branch.
  ## For each field a new ExprColonExpr node is created and put in the
  ## resulting list.
  ##
  ## Sample ``ofBranch`` AST:
  ##
  ## .. code-block::plain
  ##     OfBranch                      of 0, 1:
  ##       IntLit 0                      foodPos: float
  ##       IntLit 1                      enemyPos: float
  ##       RecList
  ##         Sym "foodPos"
  ##         Sym "enemyPos"
  result = @[]
  let getEnumCall = createGetEnumCall(kindJsonNode, kindType)

  for branchField in ofBranch[^1]:
    let objFields = processObjField(branchField, jsonNode)

    for objField in objFields:
      let exprColonExpr = newNimNode(nnkExprColonExpr)
      result.add(exprColonExpr)
      # Add the name of the field.
      exprColonExpr.add(toIdentNode(objField[0]))

      # Add the value of the field.
      let cond = createOfBranchCond(ofBranch, getEnumCall)
      exprColonExpr.add(newIfStmt(
        (cond, objField[1])
      ))

proc processElseBranch(recCaseNode, elseBranch, jsonNode, kindType,
                       kindJsonNode: NimNode): seq[NimNode] {.compileTime.} =
  ## Processes each field inside of a variant object's ``else`` branch.
  ##
  ## ..code-block::plain
  ##   Else
  ##     RecList
  ##       Sym "other"
  result = @[]
  let getEnumCall = createGetEnumCall(kindJsonNode, kindType)

  # We need to build up a list of conditions from each ``of`` branch so that
  # we can then negate it to get ``else``.
  var cond = newIdentNode("false")
  for i in 1 ..< len(recCaseNode):
    if recCaseNode[i].kind == nnkElse:
      break

    cond = infix(cond, "or", createOfBranchCond(recCaseNode[i], getEnumCall))

  # Negate the condition.
  cond = prefix(cond, "not")

  for branchField in elseBranch[^1]:
    let objFields = processObjField(branchField, jsonNode)

    for objField in objFields:
      let exprColonExpr = newNimNode(nnkExprColonExpr)
      result.add(exprColonExpr)
      # Add the name of the field.
      exprColonExpr.add(toIdentNode(objField[0]))

      # Add the value of the field.
      let ifStmt = newIfStmt((cond, objField[1]))
      exprColonExpr.add(ifStmt)

proc createConstructor(typeSym, jsonNode: NimNode): NimNode {.compileTime.}

proc detectDistinctType(typeSym: NimNode): NimNode =
  let
    typeImpl = getTypeImpl(typeSym)
    typeInst = getTypeInst(typeSym)
  result = if typeImpl.typeKind == ntyDistinct: typeImpl else: typeInst

proc processObjField(field, jsonNode: NimNode): seq[NimNode] =
  ## Process a field from a ``RecList``.
  ##
  ## The field will typically be a simple ``Sym`` node, but for object variants
  ## it may also be a ``RecCase`` in which case things become complicated.
  result = @[]
  case field.kind
  of nnkSym:
    # Ordinary field. For example, `name: string`.
    let exprColonExpr = newNimNode(nnkExprColonExpr)
    result.add(exprColonExpr)

    # Add the field name.
    exprColonExpr.add(toIdentNode(field))

    # Add the field value.
    # -> jsonNode["`field`"]
    let indexedJsonNode = createJsonIndexer(jsonNode, $field)
    let typeNode = detectDistinctType(field)
    exprColonExpr.add(createConstructor(typeNode, indexedJsonNode))
  of nnkRecCase:
    # A "case" field that introduces a variant.
    let exprColonExpr = newNimNode(nnkExprColonExpr)
    result.add(exprColonExpr)

    # Add the "case" field name (usually "kind").
    exprColonExpr.add(toIdentNode(field[0]))

    # -> jsonNode["`field[0]`"]
    let kindJsonNode = createJsonIndexer(jsonNode, $field[0])

    # Add the "case" field's value.
    let kindType = toIdentNode(getTypeInst(field[0]))
    let getEnumSym = bindSym("getEnum")
    let astStrLit = toStrLit(kindJsonNode)
    let getEnumCall = newCall(getEnumSym, kindJsonNode, astStrLit, kindType)
    exprColonExpr.add(getEnumCall)

    # Iterate through each `of` branch.
    for i in 1 ..< field.len:
      case field[i].kind
      of nnkOfBranch:
        result.add processOfBranch(field[i], jsonNode, kindType, kindJsonNode)
      of nnkElse:
        result.add processElseBranch(field, field[i], jsonNode, kindType, kindJsonNode)
      else:
        doAssert false, "Expected OfBranch or Else node kinds, got: " & $field[i].kind
  else:
    doAssert false, "Unable to process object field: " & $field.kind

  doAssert result.len > 0

proc processFields(obj: NimNode,
                   jsonNode: NimNode): seq[NimNode] {.compileTime.} =
  ## Process all the fields of an ``ObjectTy`` and any of its
  ## parent type's fields (via inheritance).
  result = @[]
  case obj.kind
  of nnkObjectTy:
    expectKind(obj[2], nnkRecList)
    for field in obj[2]:
      let nodes = processObjField(field, jsonNode)
      result.add(nodes)

    # process parent type fields
    case obj[1].kind
    of nnkBracketExpr:
      assert $obj[1][0] == "ref"
      result.add(processFields(getType(obj[1][1]), jsonNode))
    of nnkSym:
      result.add(processFields(getType(obj[1]), jsonNode))
    else:
      discard
  of nnkTupleTy:
    for identDefs in obj:
      expectKind(identDefs, nnkIdentDefs)
      let nodes = processObjField(identDefs[0], jsonNode)
      result.add(nodes)
  else:
    doAssert false, "Unable to process field type: " & $obj.kind

proc processType(typeName: NimNode, obj: NimNode,
                 jsonNode: NimNode, isRef: bool): NimNode {.compileTime.} =
  ## Process a type such as ``Sym "float"`` or ``ObjectTy ...``.
  ##
  ## Sample ``ObjectTy``:
  ##
  ## .. code-block::plain
  ##     ObjectTy
  ##       Empty
  ##       InheritanceInformation
  ##       RecList
  ##         Sym "events"
  case obj.kind
  of nnkObjectTy, nnkTupleTy:
    # Create object constructor.
    result =
      if obj.kind == nnkObjectTy: newNimNode(nnkObjConstr)
      else: newNimNode(nnkPar)

    if obj.kind == nnkObjectTy:
      result.add(typeName) # Name of the type to construct.

    # Process each object/tuple field and add it as an exprColonExpr
    result.add(processFields(obj, jsonNode))

    # Object might be null. So we need to check for that.
    if isRef:
      result = quote do:
        verifyJsonKind(`jsonNode`, {JObject, JNull}, astToStr(`jsonNode`))
        if `jsonNode`.kind == JNull:
          nil
        else:
          `result`
    else:
      result = quote do:
        verifyJsonKind(`jsonNode`, {JObject}, astToStr(`jsonNode`));
        `result`

  of nnkEnumTy:
    let instType = toIdentNode(getTypeInst(typeName))
    let getEnumCall = createGetEnumCall(jsonNode, instType)
    result = quote do:
      (
        `getEnumCall`
      )
  of nnkSym:
    let name = normalize($typeName.getTypeImpl())
    case name
    of "string":
      result = quote do:
        (
          verifyJsonKind(`jsonNode`, {JString, JNull}, astToStr(`jsonNode`));
          if `jsonNode`.kind == JNull: "" else: `jsonNode`.str
        )
    of "biggestint":
      result = quote do:
        (
          verifyJsonKind(`jsonNode`, {JInt}, astToStr(`jsonNode`));
          `jsonNode`.num
        )
    of "bool":
      result = quote do:
        (
          verifyJsonKind(`jsonNode`, {JBool}, astToStr(`jsonNode`));
          `jsonNode`.bval
        )
    else:
      if name.startsWith("int") or name.startsWith("uint"):
        result = quote do:
          (
            verifyJsonKind(`jsonNode`, {JInt}, astToStr(`jsonNode`));
            `jsonNode`.num.`obj`
          )
      elif name.startsWith("float"):
        result = quote do:
          (
            verifyJsonKind(`jsonNode`, {JInt, JFloat}, astToStr(`jsonNode`));
            if `jsonNode`.kind == JFloat: `jsonNode`.fnum.`obj` else: `jsonNode`.num.`obj`
          )
      else:
        doAssert false, "Unable to process nnkSym " & $typeName
  else:
    doAssert false, "Unable to process type: " & $obj.kind

  doAssert(not result.isNil(), "processType not initialised.")

import options
proc workaroundMacroNone[T](): Option[T] =
  none(T)

proc depth(n: NimNode, current = 0): int =
  result = 1
  for child in n:
    let d = 1 + child.depth(current + 1)
    if d > result:
      result = d

proc createConstructor(typeSym, jsonNode: NimNode): NimNode =
  ## Accepts a type description, i.e. "ref Type", "seq[Type]", "Type" etc.
  ##
  ## The ``jsonNode`` refers to the node variable that we are deserialising.
  ##
  ## Returns an object constructor node.
  # echo("--createConsuctor-- \n", treeRepr(typeSym))
  # echo()

  if depth(jsonNode) > 150:
    error("The `to` macro does not support ref objects with cycles.", jsonNode)

  case typeSym.kind
  of nnkBracketExpr:
    var bracketName = ($typeSym[0]).normalize
    case bracketName
    of "option":
      # TODO: Would be good to verify that this is Option[T] from
      # options module I suppose.
      let lenientJsonNode = transformJsonIndexer(jsonNode)

      let optionGeneric = typeSym[1]
      let value = createConstructor(typeSym[1], jsonNode)
      let workaround = bindSym("workaroundMacroNone") # TODO: Nim Bug: This shouldn't be necessary.

      result = quote do:
        (
          if `lenientJsonNode`.isNil or `jsonNode`.kind == JNull: `workaround`[`optionGeneric`]() else: some[`optionGeneric`](`value`)
        )
    of "table", "orderedtable":
      let tableKeyType = typeSym[1]
      if ($tableKeyType).cmpIgnoreStyle("string") != 0:
        error("JSON doesn't support keys of type " & $tableKeyType)
      let tableValueType = typeSym[2]

      let forLoopKey = genSym(nskForVar, "key")
      let indexerNode = createJsonIndexer(jsonNode, forLoopKey)
      let constructorNode = createConstructor(tableValueType, indexerNode)

      let tableInit =
        if bracketName == "table":
          bindSym("initTable")
        else:
          bindSym("initOrderedTable")

      # Create a statement expression containing a for loop.
      result = quote do:
        (
          var map = `tableInit`[`tableKeyType`, `tableValueType`]();
          verifyJsonKind(`jsonNode`, {JObject}, astToStr(`jsonNode`));
          for `forLoopKey` in keys(`jsonNode`.fields): map[`forLoopKey`] = `constructorNode`;
          map
        )
    of "ref":
      # Ref type.
      var typeName = $typeSym[1]
      # Remove the `:ObjectType` suffix.
      if typeName.endsWith(":ObjectType"):
        typeName = typeName[0 .. ^12]

      let obj = getType(typeSym[1])
      result = processType(newIdentNode(typeName), obj, jsonNode, true)
    of "range":
      let typeNode = typeSym
      # Deduce the base type from one of the endpoints
      let baseType = getType(typeNode[1])

      result = createConstructor(baseType, jsonNode)
    of "seq":
      let seqT = typeSym[1]
      let forLoopI = genSym(nskForVar, "i")
      let indexerNode = createJsonIndexer(jsonNode, forLoopI)
      let constructorNode = createConstructor(detectDistinctType(seqT), indexerNode)

      # Create a statement expression containing a for loop.
      result = quote do:
        (
          var list: `typeSym` = @[];
          verifyJsonKind(`jsonNode`, {JArray}, astToStr(`jsonNode`));
          for `forLoopI` in 0 ..< `jsonNode`.len: list.add(`constructorNode`);
          list
        )
    of "array":
      let arrayT = typeSym[2]
      let forLoopI = genSym(nskForVar, "i")
      let indexerNode = createJsonIndexer(jsonNode, forLoopI)
      let constructorNode = createConstructor(arrayT, indexerNode)

      # Create a statement expression containing a for loop.
      result = quote do:
        (
          var list: `typeSym`;
          verifyJsonKind(`jsonNode`, {JArray}, astToStr(`jsonNode`));
          for `forLoopI` in 0 ..< `jsonNode`.len: list[`forLoopI`] =`constructorNode`;
          list
        )

    else:
      # Generic type.
      let obj = getType(typeSym)
      result = processType(typeSym, obj, jsonNode, false)
  of nnkSym:
    # Handle JsonNode.
    if ($typeSym).cmpIgnoreStyle("jsonnode") == 0:
      return jsonNode

    # Handle all other types.
    let obj = getType(typeSym)
    let typeNode = getTypeImpl(typeSym)
    if typeNode.typeKind == ntyDistinct:
      result = createConstructor(typeNode, jsonNode)
    elif obj.kind == nnkBracketExpr:
      # When `Sym "Foo"` turns out to be a `ref object`.
      result = createConstructor(obj, jsonNode)
    else:
      result = processType(typeSym, obj, jsonNode, false)
  of nnkTupleTy:
    result = processType(typeSym, typeSym, jsonNode, false)
  of nnkPar, nnkTupleConstr:
    # TODO: The fact that `jsonNode` here works to give a good line number
    # is weird. Specifying typeSym should work but doesn't.
    error("Use a named tuple instead of: " & $toStrLit(typeSym), jsonNode)
  of nnkDistinctTy:
    var baseType = typeSym
    # solve nested distinct types
    while baseType.typeKind == ntyDistinct:
      let impl = getTypeImpl(baseType[0])
      if impl.typeKind != ntyDistinct:
        baseType = baseType[0]
        break
      baseType = impl
    let ret = createConstructor(baseType, jsonNode)
    let typeInst = getTypeInst(typeSym)
    result = quote do:
      (
        `typeInst`(`ret`)
      )
  else:
    doAssert false, "Unable to create constructor for: " & $typeSym.kind

  doAssert(not result.isNil(), "Constructor not initialised.")

proc postProcess(node: NimNode): NimNode
proc postProcessValue(value: NimNode): NimNode =
  ## Looks for object constructors and calls the ``postProcess`` procedure
  ## on them. Otherwise it just returns the node as-is.
  case value.kind
  of nnkObjConstr:
    result = postProcess(value)
  else:
    result = value
    for i in 0 ..< len(result):
      result[i] = postProcessValue(result[i])

proc postProcessExprColonExpr(exprColonExpr, resIdent: NimNode): NimNode =
  ## Transform each field mapping in the ExprColonExpr into a simple
  ## field assignment. Special processing is performed if the field mapping
  ## has an if statement.
  ##
  ## ..code-block::plain
  ##    field: (if true: 12)  ->  if true: `resIdent`.field = 12
  expectKind(exprColonExpr, nnkExprColonExpr)
  let fieldName = exprColonExpr[0]
  let fieldValue = exprColonExpr[1]
  case fieldValue.kind
  of nnkIfStmt:
    doAssert fieldValue.len == 1, "Cannot postProcess two ElifBranches."
    expectKind(fieldValue[0], nnkElifBranch)

    let cond = fieldValue[0][0]
    let bodyValue = postProcessValue(fieldValue[0][1])
    doAssert(bodyValue.kind != nnkNilLit)
    result =
      quote do:
        if `cond`:
          `resIdent`.`fieldName` = `bodyValue`
  else:
    let fieldValue = postProcessValue(fieldValue)
    doAssert(fieldValue.kind != nnkNilLit)
    result =
      quote do:
        `resIdent`.`fieldName` = `fieldValue`


proc postProcess(node: NimNode): NimNode =
  ## The ``createConstructor`` proc creates a ObjConstr node which contains
  ## if statements for fields that may not be assignable (due to an object
  ## variant). Nim doesn't handle this, but may do in the future.
  ##
  ## For simplicity, we post process the object constructor into multiple
  ## assignments.
  ##
  ## For example:
  ##
  ## ..code-block::plain
  ##    Object(                           (var res = Object();
  ##      field: if true: 12      ->       if true: res.field = 12;
  ##    )                                  res)
  result = newNimNode(nnkStmtListExpr)

  expectKind(node, nnkObjConstr)

  # Create the type.
  # -> var res = Object()
  var resIdent = genSym(nskVar, "res")
  # TODO: Placing `node[0]` inside quote is buggy
  var resType = toIdentNode(node[0])

  result.add(
    quote do:
      var `resIdent` = `resType`();
  )

  # Process each ExprColonExpr.
  for i in 1..<len(node):
    result.add postProcessExprColonExpr(node[i], resIdent)

  # Return the `res` variable.
  result.add(
    quote do:
      `resIdent`
  )


macro to*(node: JsonNode, T: typedesc): untyped =
  ## `Unmarshals`:idx: the specified node into the object type specified.
  ##
  ## Known limitations:
  ##
  ##   * Heterogeneous arrays are not supported.
  ##   * Sets in object variants are not supported.
  ##   * Not nil annotations are not supported.
  ##
  ## Example:
  ##
  ## .. code-block:: Nim
  ##     let jsonNode = parseJson("""
  ##        {
  ##          "person": {
  ##            "name": "Nimmer",
  ##            "age": 21
  ##          },
  ##          "list": [1, 2, 3, 4]
  ##        }
  ##     """)
  ##
  ##     type
  ##       Person = object
  ##         name: string
  ##         age: int
  ##
  ##       Data = object
  ##         person: Person
  ##         list: seq[int]
  ##
  ##     var data = to(jsonNode, Data)
  ##     doAssert data.person.name == "Nimmer"
  ##     doAssert data.person.age == 21
  ##     doAssert data.list == @[1, 2, 3, 4]

  let typeNode = getTypeImpl(T)
  expectKind(typeNode, nnkBracketExpr)
  doAssert(($typeNode[0]).normalize == "typedesc")

  # Create `temp` variable to store the result in case the user calls this
  # on `parseJson` (see bug #6604).
  result = newNimNode(nnkStmtListExpr)
  let temp = genSym(nskLet, "temp")
  result.add quote do:
    let `temp` = `node`

  let constructor = createConstructor(typeNode[1], temp)
  # TODO: Rename postProcessValue and move it (?)
  result.add(postProcessValue(constructor))

  # echo(treeRepr(result))
  # echo(toStrLit(result))

when false:
  import os
  var s = newFileStream(paramStr(1), fmRead)
  if s == nil: quit("cannot open the file" & paramStr(1))
  var x: JsonParser
  open(x, s, paramStr(1))
  while true:
    next(x)
    case x.kind
    of jsonError:
      Echo(x.errorMsg())
      break
    of jsonEof: break
    of jsonString, jsonInt, jsonFloat: echo(x.str)
    of jsonTrue: echo("!TRUE")
    of jsonFalse: echo("!FALSE")
    of jsonNull: echo("!NULL")
    of jsonObjectStart: echo("{")
    of jsonObjectEnd: echo("}")
    of jsonArrayStart: echo("[")
    of jsonArrayEnd: echo("]")

  close(x)

# { "json": 5 }
# To get that we shall use, obj["json"]

when isMainModule:
  # Note: Macro tests are in tests/stdlib/tjsonmacro.nim

  let testJson = parseJson"""{ "a": [1, 2, 3, 4], "b": "asd", "c": "\ud83c\udf83", "d": "\u00E6"}"""
  # nil passthrough
  doAssert(testJson{"doesnt_exist"}{"anything"}.isNil)
  testJson{["e", "f"]} = %true
  doAssert(testJson["e"]["f"].bval)

  # make sure UTF-16 decoding works.
  doAssert(testJson["c"].str == "🎃")
  doAssert(testJson["d"].str == "æ")

  # make sure no memory leek when parsing invalid string
  let startMemory = getOccupiedMem()
  for i in 0 .. 10000:
    try:
      discard parseJson"""{ invalid"""
    except:
      discard
  # memory diff should less than 4M
  doAssert(abs(getOccupiedMem() - startMemory) < 4 * 1024 * 1024)


  # test `$`
  let stringified = $testJson
  let parsedAgain = parseJson(stringified)
  doAssert(parsedAgain["b"].str == "asd")

  parsedAgain["abc"] = %5
  doAssert parsedAgain["abc"].num == 5

  # Bounds checking
  when compileOption("boundChecks"):
    try:
      let a = testJson["a"][9]
      doAssert(false, "IndexError not thrown")
    except IndexError:
      discard
    try:
      let a = testJson["a"][-1]
      doAssert(false, "IndexError not thrown")
    except IndexError:
      discard
    try:
      doAssert(testJson["a"][0].num == 1, "Index doesn't correspond to its value")
    except:
      doAssert(false, "IndexError thrown for valid index")

  doAssert(testJson{"b"}.getStr()=="asd", "Couldn't fetch a singly nested key with {}")
  doAssert(isNil(testJson{"nonexistent"}), "Non-existent keys should return nil")
  doAssert(isNil(testJson{"a", "b"}), "Indexing through a list should return nil")
  doAssert(isNil(testJson{"a", "b"}), "Indexing through a list should return nil")
  doAssert(testJson{"a"}==parseJson"[1, 2, 3, 4]", "Didn't return a non-JObject when there was one to be found")
  doAssert(isNil(parseJson("[1, 2, 3]"){"foo"}), "Indexing directly into a list should return nil")

  # Generator:
  var j = %* [{"name": "John", "age": 30}, {"name": "Susan", "age": 31}]
  doAssert j == %[%{"name": %"John", "age": %30}, %{"name": %"Susan", "age": %31}]

  var j2 = %*
    [
      {
        "name": "John",
        "age": 30
      },
      {
        "name": "Susan",
        "age": 31
      }
    ]
  doAssert j2 == %[%{"name": %"John", "age": %30}, %{"name": %"Susan", "age": %31}]

  var name = "John"
  let herAge = 30
  const hisAge = 31

  var j3 = %*
    [ { "name": "John"
      , "age": herAge
      }
    , { "name": "Susan"
      , "age": hisAge
      }
    ]
  doAssert j3 == %[%{"name": %"John", "age": %30}, %{"name": %"Susan", "age": %31}]

  var j4 = %*{"test": nil}
  doAssert j4 == %{"test": newJNull()}

  let seqOfNodes = @[%1, %2]
  let jSeqOfNodes = %seqOfNodes
  doAssert(jSeqOfNodes[1].num == 2)

  type MyObj = object
    a, b: int
    s: string
    f32: float32
    f64: float64
    next: ref MyObj
  var m: MyObj
  m.s = "hi"
  m.a = 5
  let jMyObj = %m
  doAssert(jMyObj["a"].num == 5)
  doAssert(jMyObj["s"].str == "hi")

  # Test loading of file.
  when not defined(js):
    var parsed = parseFile("tests/testdata/jsontest.json")

    try:
      discard parsed["key2"][12123]
      doAssert(false)
    except IndexError: doAssert(true)

    var parsed2 = parseFile("tests/testdata/jsontest2.json")
    doAssert(parsed2{"repository", "description"}.str=="IRC Library for Haskell", "Couldn't fetch via multiply nested key using {}")

  doAssert escapeJsonUnquoted("\10Foo🎃barÄ") == "\\nFoo🎃barÄ"
  doAssert escapeJsonUnquoted("\0\7\20") == "\\u0000\\u0007\\u0014" # for #7887
  doAssert escapeJson("\10Foo🎃barÄ") == "\"\\nFoo🎃barÄ\""
  doAssert escapeJson("\0\7\20") == "\"\\u0000\\u0007\\u0014\"" # for #7887

  # Test with extra data
  when not defined(js):
    try:
      discard parseJson("123 456")
      doAssert(false)
    except JsonParsingError:
      doAssert getCurrentExceptionMsg().contains(errorMessages[errEofExpected])

    try:
      discard parseFile("tests/testdata/jsonwithextradata.json")
      doAssert(false)
    except JsonParsingError:
      doAssert getCurrentExceptionMsg().contains(errorMessages[errEofExpected])

  # bug #6438
  doAssert($ %*[] == "[]")
  doAssert($ %*{} == "{}")

  doAssert(not compiles(%{"error": "No messages"}))

  # bug #9111
  block:
    type
      Bar = string
      Foo = object
        a: int
        b: Bar

    let
      js = """{"a": 123, "b": "abc"}""".parseJson
      foo = js.to Foo

    doAssert(foo.b == "abc")

  # Generate constructors for range[T] types
  block:
    type
      Q1 = range[0'u8  .. 50'u8]
      Q2 = range[0'u16 .. 50'u16]
      Q3 = range[0'u32 .. 50'u32]
      Q4 = range[0'i8  .. 50'i8]
      Q5 = range[0'i16 .. 50'i16]
      Q6 = range[0'i32 .. 50'i32]
      Q7 = range[0'f32 .. 50'f32]
      Q8 = range[0'f64 .. 50'f64]
      Q9 = range[0     .. 50]

      X = object
        m1: Q1
        m2: Q2
        m3: Q3
        m4: Q4
        m5: Q5
        m6: Q6
        m7: Q7
        m8: Q8
        m9: Q9

    let obj = X(
      m1: Q1(42),
      m2: Q2(42),
      m3: Q3(42),
      m4: Q4(42),
      m5: Q5(42),
      m6: Q6(42),
      m7: Q7(42),
      m8: Q8(42),
      m9: Q9(42)
    )

    doAssert(obj == to(%obj, type(obj)))
