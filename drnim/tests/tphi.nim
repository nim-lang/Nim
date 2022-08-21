discard """
  nimout: '''tphi.nim(9, 10) Warning: BEGIN [User]
tphi.nim(22, 10) Warning: END [User]'''
  cmd: "drnim $file"
  action: "compile"
"""
import std/logic
{.push staticBoundChecks: defined(nimDrNim).}
{.warning: "BEGIN".}

proc testAsgn(y: int) =
  var a = y
  if a > 0:
    if a > 3:
      a = a + 2
    else:
      a = a + 1
    {.assert: a > 1.}

testAsgn(3)

{.warning: "END".}
{.pop.}
