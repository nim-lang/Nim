discard """
  nimout: '''tsetlen_invalidates.nim(12, 10) Warning: BEGIN [User]
tsetlen_invalidates.nim(18, 12) Warning: cannot prove: 0 <= len(a) + -1; counter example: a`1.len -> 0
a.len -> 1 [IndexCheck]
tsetlen_invalidates.nim(26, 10) Warning: END [User]
'''
  cmd: "drnim $file"
  action: "compile"
"""

{.push staticBoundChecks: defined(nimDrNim).}
{.warning: "BEGIN".}

proc p() =
  var a = newSeq[int](3)
  if a.len > 0:
    a.setLen 0
    echo a[0]

  if a.len > 0:
    echo a[0]

{.pop.}

p()
{.warning: "END".}
