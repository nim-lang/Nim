discard """
  matrix: "--hint:all:off"
  nimoutFull: true
  nimout: '''
tdeprecated3.nim(21, 8) Warning: goodbye; mdeprecated3 is deprecated [Deprecated]
tdeprecated3.nim(24, 10) Warning: Ty is deprecated [Deprecated]
tdeprecated3.nim(27, 10) Warning: hello; Ty1 is deprecated [Deprecated]
tdeprecated3.nim(30, 8) Warning: aVar is deprecated [Deprecated]
tdeprecated3.nim(32, 3) Warning: aProc is deprecated [Deprecated]
tdeprecated3.nim(33, 3) Warning: hello; aProc1 is deprecated [Deprecated]
'''
"""







# line 20
import mdeprecated3

block:
  var z: Ty
  z = 0
block:
  var z: Ty1
  z = 0
block:
  echo aVar
block:
  aProc()
  aProc1()
