discard """
  nimout: '''tensures.nim(11, 10) Warning: BEGIN [User]
tensures.nim(20, 5) Warning: cannot prove:
0 < n [IndexCheck]
tensures.nim(30, 10) Warning: END [User]'''
  cmd: "drnim $file"
  action: "compile"
"""

{.push staticBoundChecks: defined(nimDrNim).}
{.warning: "BEGIN".}

proc fac(n: int) {.requires: n > 0.} =
  discard

proc g(): int {.ensures: result > 0.} =
  result = 10

fac 7 # fine
fac -45 # wrong

fac g() # fine

proc main =
  var x = g()
  fac x

main()

{.warning: "END".}
{.pop.}
