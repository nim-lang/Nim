discard """
  cmd: "nim check --hints:off $file"
  errormsg: "type mismatch: got <BC>"
  nimout: '''
tenums.nim(32, 20) Error: type mismatch: got <Letters>
but expected one of:
proc takesChristmasColor(color: ChristmasColors)
  first type mismatch at position: 1
  required type for color: ChristmasColors
  but expression 'A' is of type: Letters

expression: takesChristmasColor(A)
tenums.nim(33, 20) Error: type mismatch: got <BC>
but expected one of:
proc takesChristmasColor(color: ChristmasColors)
  first type mismatch at position: 1
  required type for color: ChristmasColors
  but expression 'BC(C)' is of type: BC

expression: takesChristmasColor(BC(C))
'''
"""

type
  Colors = enum Red, Green, Blue
  ChristmasColors = range[Red .. Green]
  Letters = enum A, B, C
  BC = range[B .. C]

proc takesChristmasColor(color: ChristmasColors) = discard
takesChristmasColor(Green)
takesChristmasColor(A)
takesChristmasColor(BC(C))
