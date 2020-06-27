##[
This module implements enum maps, which are syntax sugar for compiletime or runtime
mapping from enum members to a value type. This can be used as a type safe
generalization of enum with holes, or any application where you have a
collection of values.

Note: experimental module, unstable API
]##

#[
## TODO
* pending https://github.com/nim-lang/RFCs/issues/150 or https://github.com/nim-lang/Nim/pull/8903,
reattach doc comments to enum members (+ show enummap attached values)

* pending #13830, you'll be able to write instead:
```nim
  type MyHoly {.enumMap.} = enum
    k1 = 1
    k2 = 4
```
so docs for this will need to be updated
]#

import macros

const nimHasArrayEnumIndex = compiles(block:
  type Foo = enum foo0
  discard [foo0: 0][foo0])
  # for bootstrap; remove pending csources2 https://github.com/timotheecour/Nim/issues/251

runnableExamples:
  ## See `tests/stdlib/tenummaps.nim` for more examples.
  enumMap:
    type MyHoly = enum
      kDefault = -1 ## sentinel, when reverse lookup fails in `byVal`
      k1 = 1 ##
      k2 = 4 ## hole
      k3 = 1 ## repeated and out of order is ok
  doAssert k2.ord == 2
  doAssert k2.val == 4
  doAssert k2 == MyHoly.k2
  static: doAssert MyHoly.byVal(4) == k2 # works at CT
  doAssert MyHoly.byVal(1) == k1 # finds 1st occurrence
  doAssert MyHoly.byVal(17) == kDefault # catch-all, can be used

  ## Any value type is valid:
  enumMap:
    type Color = enum
      cDefault = (ansi: 0, name: "normal", hex: "", rgb: [0'u8,0,0]) ## default
      cBlack = (30, "black", "#000000", [0'u8,0,0]) ## black
      cGreen = (32, "green", "#008000", [0'u8,128,0]) ## green
      cDarkolivegreen = (32, "dark olive green", "#556B2F", [85'u8, 107, 47]) ## red
  static:
    doAssert cBlack.val.name == "black"
    doAssert Color.findByIt(it.val.name == "green") == cGreen

  ## runtime values are possible:
  var myval = 10
  enumMapCustom(valKind="var"):
    type Foo = enum
      k0 = myval
  doAssert k0.val == myval
  k0.val = 11
  doAssert k0.val == 11

proc lastSon(n: NimNode): NimNode =
  if n.len == 0: n
  else: n[^1]

proc maybeExport(n: NimNode, doExport: bool): NimNode =
  if doExport: newTree(nnkPostfix, ident"*", n)
  else: n

proc enumMapImpl(valKind: string, body: NimNode): NimNode =
  ## builds an enum with a map enum => val, allowing library implementation
  ## of enum with holes. This lifts restrictions on enum values, so that
  ## arbitrary types can be used as values, including non ordinal, repeated, or
  ## out of order values.
  var body = body
  doAssert body.kind == nnkStmtList and body.len == 1
  body = body[0]
  doAssert body.kind == nnkTypeSection and body.len == 1
  let body2 = copyNimTree(body)
  let isExported = body[0][0].kind == nnkPostfix and body[0][0][0].strVal == "*"
  let name = body[0][0].lastSon

  let v = nnkBracket.newTree()
  let elems = body2[0][2]
  for i, ai in elems:
    if i>0:
      elems[i] = ai[0]
      v.add newTree(nnkExprColonExpr, elems[i], ai[^1])
      # this won't work: v.add newCommentStmtNode "..."
  let vals = ident"vals".maybeExport(isExported)
  let val = ident"val".maybeExport(isExported)

  result = newStmtList()
  result.add body2

  var varr: NimNode
  case valKind
  of "let":
    varr = genSym(nskLet, "varr")
    result.add quote do:
      let `varr` = `v`
  of "var":
    varr = genSym(nskVar, "varr")
    result.add quote do:
      var `varr` = `v`
  of "const":
    varr = genSym(nskConst, "varr")
    result.add quote do:
      const `varr` = `v`
  else: error("invalid valKind: " & valKind)

  result.add quote do:
    template `vals`(t: type `name`): untyped = `varr`
  if nimHasArrayEnumIndex:
    result.add quote do:
      template `val`(a: `name`): untyped = `varr`[a]
  else:
    result.add quote do:
      template `val`(a: `name`): untyped = `varr`[a.ord]

  if valKind == "var":
    let val2 = newTree(nnkAccQuoted, ident"val", ident"=").maybeExport(isExported)
    result.add quote do:
      template `val2`(a: `name`, b) = `varr`[a] = b

macro enumMap*(body: untyped): untyped =
  result = enumMapImpl(valKind = "const", body)

macro enumMapCustom*(valKind: static string, body: untyped): untyped =
  # pending #14346, merge with `enumMap`
  result = enumMapImpl(valKind = valKind, body)

when false:
  # broken pending https://github.com/nim-lang/Nim/issues/13747
  # so we use an auxiliary template as workaround
  proc byValImpl[V](a: V, T: typedesc): T =
    mixin vals
    for ai in T:
      if T.vals[ai] == a: return ai

proc byValImpl[V](a: V, T: typedesc, vals: array): T =
  ## can be optimized in different ways if ever needed, eg building a trie
  ## at CT, followed by trie search at RT. Other option is a hash table
  for ai in T:
    if vals[ai] == a: return ai

template byVal*(E: typedesc[enum], a: typed): E =
  ## reverse lookup by value
  byValImpl(a, E, E.vals)

template findByIt*(E: typedesc[enum], pred: untyped): E =
  ## reverse lookup by a predicate `pred` on `it`
  var ret: E
  block outer:
    for it {.inject.} in E:
      if pred:
        ret = it
        break outer
  ret
