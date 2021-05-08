#
#
#           The Nim Compiler
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# Implements a table from trees to trees. Does structural equivalence checking.

import
  hashes, ast, astalgo, types

proc hashTree*(n: PNode): Hash =
  if n.isNil:
    return
  result = ord(n.kind)
  case n.kind
  of nkEmpty, nkNilLit, nkType:
    discard
  of nkIdent:
    result = result !& n.ident.h
  of nkSym:
    result = result !& n.sym.id
  of nkCharLit..nkUInt64Lit:
    if (n.intVal >= low(int)) and (n.intVal <= high(int)):
      result = result !& int(n.intVal)
  of nkFloatLit..nkFloat64Lit:
    if (n.floatVal >= - 1000000.0) and (n.floatVal <= 1000000.0):
      result = result !& toInt(n.floatVal)
  of nkStrLit..nkTripleStrLit:
    result = result !& hash(n.strVal)
  else:
    for i in 0..<n.len:
      result = result !& hashTree(n[i])
  result = !$result
  #echo "hashTree ", result
  #echo n

proc treesEquivalent(a, b: PNode): bool =
  if a == b:
    result = true
  elif (a != nil) and (b != nil) and (a.kind == b.kind):
    case a.kind
    of nkEmpty, nkNilLit, nkType: result = true
    of nkSym: result = a.sym.id == b.sym.id
    of nkIdent: result = a.ident.id == b.ident.id
    of nkCharLit..nkUInt64Lit: result = a.intVal == b.intVal
    of nkFloatLit..nkFloat64Lit: result = a.floatVal == b.floatVal
    of nkStrLit..nkTripleStrLit: result = a.strVal == b.strVal
    else:
      if a.len == b.len:
        for i in 0..<a.len:
          if not treesEquivalent(a[i], b[i]): return
        result = true
    if result: result = sameTypeOrNil(a.typ, b.typ)

proc nodeTableRawGet(t: TNodeTable, k: Hash, key: PNode): int =
  var h: Hash = k and high(t.data)
  while t.data[h].key != nil:
    if (t.data[h].h == k) and treesEquivalent(t.data[h].key, key):
      return h
    h = nextTry(h, high(t.data))
  result = -1

proc nodeTableGet*(t: TNodeTable, key: PNode): int =
  var index = nodeTableRawGet(t, hashTree(key), key)
  if index >= 0: result = t.data[index].val
  else: result = low(int)

proc nodeTableRawInsert(data: var TNodePairSeq, k: Hash, key: PNode,
                        val: int) =
  var h: Hash = k and high(data)
  while data[h].key != nil: h = nextTry(h, high(data))
  assert(data[h].key == nil)
  data[h].h = k
  data[h].key = key
  data[h].val = val

proc nodeTablePut*(t: var TNodeTable, key: PNode, val: int) =
  let k = hashTree(key)
  let index = nodeTableRawGet(t, k, key)
  if index >= 0:
    assert(t.data[index].key != nil)
    t.data[index].val = val
  else:
    if mustRehash(t.data.len, t.counter):
      var n = newSeq[TNodePair](t.data.len * GrowthFactor)
      for i in 0..high(t.data):
        if t.data[i].key != nil:
          nodeTableRawInsert(n, t.data[i].h, t.data[i].key, t.data[i].val)
      t.data = move n
    nodeTableRawInsert(t.data, k, key, val)
    inc(t.counter)

proc nodeTableTestOrSet*(t: var TNodeTable, key: PNode, val: int): int =
  let k = hashTree(key)
  let index = nodeTableRawGet(t, k, key)
  if index >= 0:
    assert(t.data[index].key != nil)
    result = t.data[index].val
  else:
    if mustRehash(t.data.len, t.counter):
      var n = newSeq[TNodePair](t.data.len * GrowthFactor)
      for i in 0..high(t.data):
        if t.data[i].key != nil:
          nodeTableRawInsert(n, t.data[i].h, t.data[i].key, t.data[i].val)
      t.data = move n
    nodeTableRawInsert(t.data, k, key, val)
    result = val
    inc(t.counter)
