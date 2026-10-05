discard """
  action: compile
  cmd: "nim check --hints:off --warning:ResultUsed:on $file"
  nimout: '''
tresultused.nim(34, 3) Warning: used 'result' variable [ResultUsed]
tresultused.nim(37, 3) Warning: used 'result' variable [ResultUsed]
'''
"""

let value = 0
discard value

for item in 0 .. 0:
  discard item

proc usesLocal() =
  var local = 0
  discard local

block:
  let result = 0
  discard result

proc voidReturn() =
  return

proc implicitReturn(): int =
  0

proc explicitReturn(): int =
  return 0

proc usesResult(): int =
  result = 0

proc usesBareReturn(): int =
  return

doAssert implicitReturn() == 0
doAssert explicitReturn() == 0
doAssert usesResult() == 0
doAssert usesBareReturn() == 0
