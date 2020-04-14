discard """
  nimout: '''BEGIN
tsetlen_invalidates.nim(17, 12) Warning: cannot prove: 0 <= len(a) + -1; counter example: a.len -> 0 [IndexCheck]
END
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
