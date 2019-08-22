discard """
  nimout: '''tmodule1.nim(11, 8) Warning: goodbye; importme is deprecated [Deprecated]
tmodule1.nim(14, 10) Warning: Ty is deprecated [Deprecated]
tmodule1.nim(17, 10) Warning: hello; Ty1 is deprecated [Deprecated]
tmodule1.nim(20, 8) Warning: aVar is deprecated [Deprecated]
tmodule1.nim(22, 3) Warning: aProc is deprecated [Deprecated]
tmodule1.nim(23, 3) Warning: hello; aProc1 is deprecated [Deprecated]
'''
"""

import importme

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
