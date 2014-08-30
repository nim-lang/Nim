#
#
#           The Nim Compiler
#        (c) Copyright 2014 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

template setX(k, field) {.immediate, dirty.} =
  var s: seq[TFullReg]
  move(s, cast[seq[TFullReg]](a.slots))
  if s[a.ra].kind != k:
    myreset(s[a.ra])
    s[a.ra].kind = k
  s[a.ra].field = v

proc setResult*(a: VmArgs; v: BiggestInt) = setX(rkInt, intVal)
proc setResult*(a: VmArgs; v: BiggestFloat) = setX(rkFloat, floatVal)
proc setResult*(a: VmArgs; v: bool) = 
  let v = v.ord
  setX(rkInt, intVal)

proc setResult*(a: VmArgs; v: string) =
  var s: seq[TFullReg]
  move(s, cast[seq[TFullReg]](a.slots))
  if s[a.ra].kind != rkNode:
    myreset(s[a.ra])
    s[a.ra].kind = rkNode
  s[a.ra].node = newNode(nkStrLit)
  s[a.ra].node.strVal = v

template getX(k, field) {.immediate, dirty.} =
  doAssert i < a.rc-1
  let s = cast[seq[TFullReg]](a.slots)
  doAssert s[i+a.rb+1].kind == k
  result = s[i+a.rb+1].field

proc getInt*(a: VmArgs; i: Natural): BiggestInt = getX(rkInt, intVal)
proc getFloat*(a: VmArgs; i: Natural): BiggestFloat = getX(rkFloat, floatVal)
proc getString*(a: VmArgs; i: Natural): string =
  doAssert i < a.rc-1
  let s = cast[seq[TFullReg]](a.slots)
  doAssert s[i+a.rb+1].kind == rkNode
  result = s[i+a.rb+1].node.strVal
