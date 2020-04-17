##[
experimental module, unstable API
]##

import macros

proc lastSon(n: NimNode): NimNode =
  if n.len == 0: n
  else: n[^1]

proc maybeExport(n: NimNode, doExport: bool): NimNode =
  if doExport: newTree(nnkPostfix, ident"*", n)
  else: n

macro enumMap*(body): untyped =
  ## builds an enum with a map enum => val, allowing library implementation
  ## of enum with holes. This lifts restrictions on enum values, so that
  ## arbitrary types can be used as values, including non ordinal, repeated, or
  ##  out of order values.
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
      v.add ai[^1]

  for i, ai in elems:
    if i>0: elems[i] = ai[0]

  let valsIdent = ident"vals".maybeExport(isExported)
  let val = ident"val".maybeExport(isExported)

  result = quote do:
    const varr = `v`
    `body2`
    template `val`(a: `name`): untyped = varr[ord(a)]
    template `valsIdent`(t: type `name`): untyped = varr

proc byValImpl[V](a: V, T: typedesc, vals: array): T =
  ## can be optimized in different ways if ever needed, eg building a trie
  ## at CT, followed by trie search at RT. Other option is a hash table
  for ai in T:
    if vals[ai.ord] == a:
      return ai

template byVal*(E: typedesc[enum], a: typed): E =
  byValImpl(a, E, E.vals)

template findByIt*(E: typedesc[enum], pred: untyped): E =
  # TODO: rename; enumByIt?
  var ret: E
  block outer:
    for it {.inject.} in E:
      if pred:
        ret = it
        break outer
  ret
