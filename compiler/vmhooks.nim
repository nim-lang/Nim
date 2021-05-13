#
#
#           The Nim Compiler
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

import pathutils

template setX(k, field) {.dirty.} =
  a.slots[a.ra].ensureKind(k)
  a.slots[a.ra].field = v

proc setResult*(a: VmArgs; v: BiggestInt) = setX(rkInt, intVal)
proc setResult*(a: VmArgs; v: BiggestFloat) = setX(rkFloat, floatVal)
proc setResult*(a: VmArgs; v: bool) =
  let v = v.ord
  setX(rkInt, intVal)

proc setResult*(a: VmArgs; v: string) =
  a.slots[a.ra].ensureKind(rkNode)
  a.slots[a.ra].node = newNode(nkStrLit)
  a.slots[a.ra].node.strVal = v

proc setResult*(a: VmArgs; n: PNode) =
  a.slots[a.ra].ensureKind(rkNode)
  a.slots[a.ra].node = n

proc setResult*(a: VmArgs; v: AbsoluteDir) = setResult(a, v.string)

proc setResult*(a: VmArgs; v: seq[string]) =
  a.slots[a.ra].ensureKind(rkNode)
  var n = newNode(nkBracket)
  for x in v: n.add newStrNode(nkStrLit, x)
  a.slots[a.ra].node = n

template getReg(a, i): untyped =
  doAssert i < a.rc-1
  a.slots[i+a.rb+1].unsafeAddr

template getX(k, field): untyped {.dirty.} =
  let p = getReg(a, i)
  doAssert p.kind == k, $p.kind
  p.field

proc numArgs*(a: VmArgs): int =
  result = a.rc-1

proc getInt*(a: VmArgs; i: Natural): BiggestInt = getX(rkInt, intVal)
proc getBool*(a: VmArgs; i: Natural): bool = getInt(a, i) != 0
proc getFloat*(a: VmArgs; i: Natural): BiggestFloat = getX(rkFloat, floatVal)
proc getNode*(a: VmArgs; i: Natural): PNode = getX(rkNode, node)
proc getString*(a: VmArgs; i: Natural): string = getX(rkNode, node).strVal
proc getVar*(a: VmArgs; i: Natural): PNode =
  let p = getReg(a, i)
  # depending on whether we come from top-level or proc scope, we need to consider 2 cases
  case p.kind
  of rkRegisterAddr: result = p.regAddr.node
  of rkNodeAddr: result = p.nodeAddr[]
  else: doAssert false, $p.kind

proc getNodeAddr*(a: VmArgs; i: Natural): PNode =
  let nodeAddr = getX(rkNodeAddr, nodeAddr)
  doAssert nodeAddr != nil
  result = nodeAddr[]
