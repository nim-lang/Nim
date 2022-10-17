discard """
  cmd: "nim check --hints:off --warnings:off $file"
  action: "reject"
  nimout:'''
t7955.nim(46, 14) Error: type mismatch: got <BRC> but expected 'SBase[system.string, system.int]'
t7955.nim(46, 18) Error: type mismatch: got <BRD> but expected 'SBase[system.string, system.int]'
t7955.nim(47, 15) Error: type mismatch: got <SRD> but expected 'BRC = ref BRC:ObjectType'
t7955.nim(48, 15) Error: type mismatch: got <SRC> but expected 'BRD = ref BRD:ObjectType'
'''
"""









type
  SBase[T, V] = ref object of RootObj
    val: T
    color: V
  SRC = ref object of SBase[string, int]
  SRD = ref object of SBase[string, int]

var a = SBase[string, int](val: "base", color: 1)
var b = SRC(val: "rc", color: 2)
var c = SRD(val: "rd", color: 3)

var x = [a, b, c] #ok
var y = [b, c] #failed
var z = [c, b] #failed

type
  BBase[T, V] = ref object of RootObj
    val: T
    color: V
  BRC = ref object of BBase[string, int]
  BRD = ref object of BBase[string, int]

var a1 = BBase[string, int](val: "base", color: 1)
var b1 = BRC(val: "rc", color: 2)
var c1 = BRD(val: "rd", color: 3)

var x1 = [a, b1, c1]
var y1 = [b1, c]
var z1 = [c1, b]