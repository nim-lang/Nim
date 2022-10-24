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
## See also
## ========
## * `std/parsejson <parsejson.html>`_
## * `std/jsonutils <jsonutils.html>`_
## * `std/marshal <marshal.html>`_
## * `std/jscore <jscore.html>`_
##
##
## Overview
## ========
##
## Parsing JSON
## ------------
##
## JSON often arrives into your program (via an API or a file) as a `string`.
## The first step is to change it from its serialized form into a nested object
## structure called a `JsonNode`.
##
## The `parseJson` procedure takes a string containing JSON and returns a
## `JsonNode` object. This is an object variant and it is either a
## `JObject`, `JArray`, `JString`, `JInt`, `JFloat`, `JBool` or
## `JNull`. You check the kind of this object variant by using the `kind`
## accessor.
##
## For a `JsonNode` who's kind is `JObject`, you can access its fields using
## the `[]` operator. The following example shows how to do this:
##
## .. code-block:: Nim
##   import std/json
##
##   let jsonNode = parseJson("""{"key": 3.14}""")
##
##   doAssert jsonNode.kind == JObject
##   doAssert jsonNode["key"].kind == JFloat
##
## Reading values
## --------------
##
## Once you have a `JsonNode`, retrieving the values can then be achieved
## by using one of the helper procedures, which include:
##
## * `getInt`
## * `getFloat`
## * `getStr`
## * `getBool`
##
## To retrieve the value of `"key"` you can do the following:
##
## .. code-block:: Nim
##   import std/json
##
##   let jsonNode = parseJson("""{"key": 3.14}""")
##
##   doAssert jsonNode["key"].getFloat() == 3.14
##
## **Important:** The `[]` operator will raise an exception when the
## specified field does not exist.
##
## Handling optional keys
## ----------------------
##
## By using the `{}` operator instead of `[]`, it will return `nil`
## when the field is not found. The `get`-family of procedures will return a
## type's default value when called on `nil`.
##
## .. code-block:: Nim
##   import std/json
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
## The `get`-family helpers also accept an additional parameter which allow
## you to fallback to a default value should the key's values be `null`:
##
## .. code-block:: Nim
##   import std/json
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
## In addition to reading dynamic data, Nim can also unmarshal JSON directly
## into a type with the `to` macro.
##
## Note: Use `Option <options.html#Option>`_ for keys sometimes missing in json
## responses, and backticks around keys with a reserved keyword as name.
##
## .. code-block:: Nim
##   import std/json
##   import std/options
##
##   type
##     User = object
##       name: string
##       age: int
##       `type`: Option[string]
##
##   let userJson = parseJson("""{ "name": "Nim", "age": 12 }""")
##   let user = to(userJson, User)
##   if user.`type`.isSome():
##     assert user.`type`.get() != "robot"
##
## Creating JSON
## =============
##
## This module can also be used to comfortably create JSON using the `%*`
## operator:
##
## .. code-block:: nim
##   import std/json
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
##
## See also: std/jsonutils for hookable json serialization/deserialization
## of arbitrary types.

runnableExamples:
  ## Note: for JObject, key ordering is preserved, unlike in some languages,
  ## this is convenient for some use cases. Example:
  type Foo = object
    a1, a2, a0, a3, a4: int
  doAssert $(%* Foo()) == """{"a1":0,"a2":0,"a0":0,"a3":0,"a4":0}"""

import tables, strutils, macros, parsejson
import options # xxx remove this dependency using same approach as https://github.com/nim-lang/Nim/pull/14563


when defined(nimPreviewSlimSystem):
  import std/[syncio, assertions, formatfloat]

export
  tables.`$`


import std/private/jsontree
export jsontree

import std/private/jsonparser
export jsonparser

import std/private/jsonmapper
export jsonmapper


# -- Json deserialiser. --

template verifyJsonKind(node: JsonNode, kinds: set[JsonNodeKind],
                        ast: string) =
  if node == nil:
    raise newException(KeyError, "key not found: " & ast)
  elif  node.kind notin kinds:
    let msg = "Incorrect JSON kind. Wanted '$1' in '$2' but got '$3'." % [
      $kinds,
      ast,
      $node.kind
    ]
    raise newException(JsonKindError, msg)

when defined(nimFixedForwardGeneric):

  macro isRefSkipDistinct*(arg: typed): untyped =
    ## internal only, do not use
    var impl = getTypeImpl(arg)
    if impl.kind == nnkBracketExpr and impl[0].eqIdent("typeDesc"):
      impl = getTypeImpl(impl[1])
    while impl.kind == nnkDistinctTy:
      impl = getTypeImpl(impl[0])
    result = newLit(impl.kind == nnkRefTy)

  # The following forward declarations don't work in older versions of Nim

  # forward declare all initFromJson

  proc initFromJson(dst: var string; jsonNode: JsonNode; jsonPath: var string)
  proc initFromJson(dst: var bool; jsonNode: JsonNode; jsonPath: var string)
  proc initFromJson(dst: var JsonNode; jsonNode: JsonNode; jsonPath: var string)
  proc initFromJson[T: SomeInteger](dst: var T; jsonNode: JsonNode, jsonPath: var string)
  proc initFromJson[T: SomeFloat](dst: var T; jsonNode: JsonNode; jsonPath: var string)
  proc initFromJson[T: enum](dst: var T; jsonNode: JsonNode; jsonPath: var string)
  proc initFromJson[T](dst: var seq[T]; jsonNode: JsonNode; jsonPath: var string)
  proc initFromJson[S, T](dst: var array[S, T]; jsonNode: JsonNode; jsonPath: var string)
  proc initFromJson[T](dst: var Table[string, T]; jsonNode: JsonNode; jsonPath: var string)
  proc initFromJson[T](dst: var OrderedTable[string, T]; jsonNode: JsonNode; jsonPath: var string)
  proc initFromJson[T](dst: var ref T; jsonNode: JsonNode; jsonPath: var string)
  proc initFromJson[T](dst: var Option[T]; jsonNode: JsonNode; jsonPath: var string)
  proc initFromJson[T: distinct](dst: var T; jsonNode: JsonNode; jsonPath: var string)
  proc initFromJson[T: object|tuple](dst: var T; jsonNode: JsonNode; jsonPath: var string)

  # initFromJson definitions

  proc initFromJson(dst: var string; jsonNode: JsonNode; jsonPath: var string) =
    verifyJsonKind(jsonNode, {JString, JNull}, jsonPath)
    # since strings don't have a nil state anymore, this mapping of
    # JNull to the default string is questionable. `none(string)` and
    # `some("")` have the same potentional json value `JNull`.
    if jsonNode.kind == JNull:
      dst = ""
    else:
      dst = jsonNode.str

  proc initFromJson(dst: var bool; jsonNode: JsonNode; jsonPath: var string) =
    verifyJsonKind(jsonNode, {JBool}, jsonPath)
    dst = jsonNode.bval

  proc initFromJson(dst: var JsonNode; jsonNode: JsonNode; jsonPath: var string) =
    if jsonNode == nil:
      raise newException(KeyError, "key not found: " & jsonPath)
    dst = jsonNode.copy

  proc initFromJson[T: SomeInteger](dst: var T; jsonNode: JsonNode, jsonPath: var string) =
    when T is uint|uint64 or (not defined(js) and int.sizeof == 4):
      verifyJsonKind(jsonNode, {JInt, JString}, jsonPath)
      case jsonNode.kind
      of JString:
        let x = parseBiggestUInt(jsonNode.str)
        dst = cast[T](x)
      else:
        dst = T(jsonNode.num)
    else:
      verifyJsonKind(jsonNode, {JInt}, jsonPath)
      dst = cast[T](jsonNode.num)

  proc initFromJson[T: SomeFloat](dst: var T; jsonNode: JsonNode; jsonPath: var string) =
    if jsonNode.kind == JString:
      case jsonNode.str
      of "nan":
        let b = NaN
        dst = T(b)
        # dst = NaN # would fail some tests because range conversions would cause CT error
        # in some cases; but this is not a hot-spot inside this branch and backend can optimize this.
      of "inf":
        let b = Inf
        dst = T(b)
      of "-inf":
        let b = -Inf
        dst = T(b)
      else: raise newException(JsonKindError, "expected 'nan|inf|-inf', got " & jsonNode.str)
    else:
      verifyJsonKind(jsonNode, {JInt, JFloat}, jsonPath)
      if jsonNode.kind == JFloat:
        dst = T(jsonNode.fnum)
      else:
        dst = T(jsonNode.num)

  proc initFromJson[T: enum](dst: var T; jsonNode: JsonNode; jsonPath: var string) =
    verifyJsonKind(jsonNode, {JString}, jsonPath)
    dst = parseEnum[T](jsonNode.getStr)

  proc initFromJson[T](dst: var seq[T]; jsonNode: JsonNode; jsonPath: var string) =
    verifyJsonKind(jsonNode, {JArray}, jsonPath)
    dst.setLen jsonNode.len
    let orignalJsonPathLen = jsonPath.len
    for i in 0 ..< jsonNode.len:
      jsonPath.add '['
      jsonPath.addInt i
      jsonPath.add ']'
      initFromJson(dst[i], jsonNode[i], jsonPath)
      jsonPath.setLen orignalJsonPathLen

  proc initFromJson[S,T](dst: var array[S,T]; jsonNode: JsonNode; jsonPath: var string) =
    verifyJsonKind(jsonNode, {JArray}, jsonPath)
    let originalJsonPathLen = jsonPath.len
    for i in 0 ..< jsonNode.len:
      jsonPath.add '['
      jsonPath.addInt i
      jsonPath.add ']'
      initFromJson(dst[i.S], jsonNode[i], jsonPath) # `.S` for enum indexed arrays
      jsonPath.setLen originalJsonPathLen

  proc initFromJson[T](dst: var Table[string,T]; jsonNode: JsonNode; jsonPath: var string) =
    dst = initTable[string, T]()
    verifyJsonKind(jsonNode, {JObject}, jsonPath)
    let originalJsonPathLen = jsonPath.len
    for key in keys(jsonNode.fields):
      jsonPath.add '.'
      jsonPath.add key
      initFromJson(mgetOrPut(dst, key, default(T)), jsonNode[key], jsonPath)
      jsonPath.setLen originalJsonPathLen

  proc initFromJson[T](dst: var OrderedTable[string,T]; jsonNode: JsonNode; jsonPath: var string) =
    dst = initOrderedTable[string,T]()
    verifyJsonKind(jsonNode, {JObject}, jsonPath)
    let originalJsonPathLen = jsonPath.len
    for key in keys(jsonNode.fields):
      jsonPath.add '.'
      jsonPath.add key
      initFromJson(mgetOrPut(dst, key, default(T)), jsonNode[key], jsonPath)
      jsonPath.setLen originalJsonPathLen

  proc initFromJson[T](dst: var ref T; jsonNode: JsonNode; jsonPath: var string) =
    verifyJsonKind(jsonNode, {JObject, JNull}, jsonPath)
    if jsonNode.kind == JNull:
      dst = nil
    else:
      dst = new(T)
      initFromJson(dst[], jsonNode, jsonPath)

  proc initFromJson[T](dst: var Option[T]; jsonNode: JsonNode; jsonPath: var string) =
    if jsonNode != nil and jsonNode.kind != JNull:
      when T is ref:
        dst = some(new(T))
      else:
        dst = some(default(T))
      initFromJson(dst.get, jsonNode, jsonPath)

  macro assignDistinctImpl[T: distinct](dst: var T;jsonNode: JsonNode; jsonPath: var string) =
    let typInst = getTypeInst(dst)
    let typImpl = getTypeImpl(dst)
    let baseTyp = typImpl[0]

    result = quote do:
      when nimvm:
        # workaround #12282
        var tmp: `baseTyp`
        initFromJson( tmp, `jsonNode`, `jsonPath`)
        `dst` = `typInst`(tmp)
      else:
        initFromJson( `baseTyp`(`dst`), `jsonNode`, `jsonPath`)

  proc initFromJson[T: distinct](dst: var T; jsonNode: JsonNode; jsonPath: var string) =
    assignDistinctImpl(dst, jsonNode, jsonPath)

  proc detectIncompatibleType(typeExpr, lineinfoNode: NimNode) =
    if typeExpr.kind == nnkTupleConstr:
      error("Use a named tuple instead of: " & typeExpr.repr, lineinfoNode)

  proc foldObjectBody(dst, typeNode, tmpSym, jsonNode, jsonPath, originalJsonPathLen: NimNode) =
    case typeNode.kind
    of nnkEmpty:
      discard
    of nnkRecList, nnkTupleTy:
      for it in typeNode:
        foldObjectBody(dst, it, tmpSym, jsonNode, jsonPath, originalJsonPathLen)

    of nnkIdentDefs:
      typeNode.expectLen 3
      let fieldSym = typeNode[0]
      let fieldNameLit = newLit(fieldSym.strVal)
      let fieldPathLit = newLit("." & fieldSym.strVal)
      let fieldType = typeNode[1]

      # Detecting incompatiple tuple types in `assignObjectImpl` only
      # would be much cleaner, but the ast for tuple types does not
      # contain usable type information.
      detectIncompatibleType(fieldType, fieldSym)

      dst.add quote do:
        jsonPath.add `fieldPathLit`
        when nimvm:
          when isRefSkipDistinct(`tmpSym`.`fieldSym`):
            # workaround #12489
            var tmp: `fieldType`
            initFromJson(tmp, getOrDefault(`jsonNode`,`fieldNameLit`), `jsonPath`)
            `tmpSym`.`fieldSym` = tmp
          else:
            initFromJson(`tmpSym`.`fieldSym`, getOrDefault(`jsonNode`,`fieldNameLit`), `jsonPath`)
        else:
          initFromJson(`tmpSym`.`fieldSym`, getOrDefault(`jsonNode`,`fieldNameLit`), `jsonPath`)
        jsonPath.setLen `originalJsonPathLen`

    of nnkRecCase:
      let kindSym = typeNode[0][0]
      let kindNameLit = newLit(kindSym.strVal)
      let kindPathLit = newLit("." & kindSym.strVal)
      let kindType = typeNode[0][1]
      let kindOffsetLit = newLit(uint(getOffset(kindSym)))
      dst.add quote do:
        var kindTmp: `kindType`
        jsonPath.add `kindPathLit`
        initFromJson(kindTmp, `jsonNode`[`kindNameLit`], `jsonPath`)
        jsonPath.setLen `originalJsonPathLen`
        when defined js:
          `tmpSym`.`kindSym` = kindTmp
        else:
          when nimvm:
            `tmpSym`.`kindSym` = kindTmp
          else:
            # fuck it, assign kind field anyway
            ((cast[ptr `kindType`](cast[uint](`tmpSym`.addr) + `kindOffsetLit`))[]) = kindTmp
      dst.add nnkCaseStmt.newTree(nnkDotExpr.newTree(tmpSym, kindSym))
      for i in 1 ..< typeNode.len:
        foldObjectBody(dst, typeNode[i], tmpSym, jsonNode, jsonPath, originalJsonPathLen)

    of nnkOfBranch, nnkElse:
      let ofBranch = newNimNode(typeNode.kind)
      for i in 0 ..< typeNode.len-1:
        ofBranch.add copyNimTree(typeNode[i])
      let dstInner = newNimNode(nnkStmtListExpr)
      foldObjectBody(dstInner, typeNode[^1], tmpSym, jsonNode, jsonPath, originalJsonPathLen)
      # resOuter now contains the inner stmtList
      ofBranch.add dstInner
      dst[^1].expectKind nnkCaseStmt
      dst[^1].add ofBranch

    of nnkObjectTy:
      typeNode[0].expectKind nnkEmpty
      typeNode[1].expectKind {nnkEmpty, nnkOfInherit}
      if typeNode[1].kind == nnkOfInherit:
        let base = typeNode[1][0]
        var impl = getTypeImpl(base)
        while impl.kind in {nnkRefTy, nnkPtrTy}:
          impl = getTypeImpl(impl[0])
        foldObjectBody(dst, impl, tmpSym, jsonNode, jsonPath, originalJsonPathLen)
      let body = typeNode[2]
      foldObjectBody(dst, body, tmpSym, jsonNode, jsonPath, originalJsonPathLen)

    else:
      error("unhandled kind: " & $typeNode.kind, typeNode)

  macro assignObjectImpl[T](dst: var T; jsonNode: JsonNode; jsonPath: var string) =
    let typeSym = getTypeInst(dst)
    let originalJsonPathLen = genSym(nskLet, "originalJsonPathLen")
    result = newStmtList()
    result.add quote do:
      let `originalJsonPathLen` = len(`jsonPath`)
    if typeSym.kind in {nnkTupleTy, nnkTupleConstr}:
      # both, `dst` and `typeSym` don't have good lineinfo. But nothing
      # else is available here.
      detectIncompatibleType(typeSym, dst)
      foldObjectBody(result, typeSym, dst, jsonNode, jsonPath, originalJsonPathLen)
    else:
      foldObjectBody(result, typeSym.getTypeImpl, dst, jsonNode, jsonPath, originalJsonPathLen)

  proc initFromJson[T: object|tuple](dst: var T; jsonNode: JsonNode; jsonPath: var string) =
    assignObjectImpl(dst, jsonNode, jsonPath)

  proc to*[T](node: JsonNode, t: typedesc[T]): T =
    ## `Unmarshals`:idx: the specified node into the object type specified.
    ##
    ## Known limitations:
    ##
    ##   * Heterogeneous arrays are not supported.
    ##   * Sets in object variants are not supported.
    ##   * Not nil annotations are not supported.
    ##
    runnableExamples:
      let jsonNode = parseJson("""
        {
          "person": {
            "name": "Nimmer",
            "age": 21
          },
          "list": [1, 2, 3, 4]
        }
      """)

      type
        Person = object
          name: string
          age: int

        Data = object
          person: Person
          list: seq[int]

      var data = to(jsonNode, Data)
      doAssert data.person.name == "Nimmer"
      doAssert data.person.age == 21
      doAssert data.list == @[1, 2, 3, 4]

    var jsonPath = ""
    initFromJson(result, node, jsonPath)

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
