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

template getX(k, field) {.dirty.} =
  doAssert i < a.rc-1
  doAssert a.slots[i+a.rb+1].kind == k
  result = a.slots[i+a.rb+1].field

proc numArgs*(a: VmArgs): int =
  result = a.rc-1

proc getInt*(a: VmArgs; i: Natural): BiggestInt = getX(rkInt, intVal)
proc getBool*(a: VmArgs; i: Natural): bool = getInt(a, i) != 0
proc getFloat*(a: VmArgs; i: Natural): BiggestFloat = getX(rkFloat, floatVal)
proc getString*(a: VmArgs; i: Natural): string =
  doAssert i < a.rc-1
  doAssert a.slots[i+a.rb+1].kind == rkNode
  result = a.slots[i+a.rb+1].node.strVal

proc getNode*(a: VmArgs; i: Natural): PNode =
  doAssert i < a.rc-1
  doAssert a.slots[i+a.rb+1].kind == rkNode
  result = a.slots[i+a.rb+1].node

proc getNodeAddr*(a: VmArgs; i: Natural): PNode =
  doAssert i < a.rc-1
  doAssert a.slots[i+a.rb+1].kind == rkNodeAddr
  let nodeAddr = a.slots[i+a.rb+1].nodeAddr
  doAssert nodeAddr != nil
  result = nodeAddr[]
