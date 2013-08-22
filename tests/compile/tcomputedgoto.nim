discard """
  output: '''yeah A
yeah A
yeah CD
yeah CD
yeah A
yeah CD
yeah CD
yeah A
yeah B
yeah A
yeah A
yeah A'''
"""

type
  MyEnum = enum
    enumA, enumB, enumC, enumD, enumE

proc vm() =
  var instructions: array [0..100, MyEnum]
  instructions[2] = enumC
  instructions[3] = enumD
  instructions[4] = enumA
  instructions[5] = enumD
  instructions[6] = enumC
  instructions[7] = enumA
  instructions[8] = enumB

  instructions[12] = enumE
  var pc = 0
  while true:
    {.computedGoto.}
    let instr = instructions[pc]
    case instr
    of enumA:
      echo "yeah A"
    of enumC, enumD:
      echo "yeah CD"
    of enumB:
      echo "yeah B"
    of enumE:
      break
    inc(pc)
  
vm()
