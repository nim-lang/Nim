discard """
  output: '''
rc rd base
rd rc base
rc rd
'''
"""

# bug #7955: array construction with a generic `ref object` base
type
  SBase[T, V] = ref object of RootObj
    val: T
    color: V
  SRC = ref object of SBase[string, int]
  SRD = ref object of SBase[string, int]

var a = SBase[string, int](val: "base", color: 1)
var b = SRC(val: "rc", color: 2)
var c = SRD(val: "rd", color: 3)

var x = [a, b, c]
var y = [b, c, a]
var z = [c, b, a]
echo y[0].val, " ", y[1].val, " ", y[2].val
echo z[0].val, " ", z[1].val, " ", z[2].val

type
  PBase[T] = object of RootObj
    val: T
  PC = object of PBase[string]
  PD = object of PBase[string]

var pc = PC(val: "rc")
var pd = PD(val: "rd")
var w = [addr pc, addr pd]
echo w[0].val, " ", w[1].val
