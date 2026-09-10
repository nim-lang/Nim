discard """
  output: "ok"
"""

var overflowDetected = false
when nimvm:
  {.push overflowChecks: off.}
else:
  var branchX = high(int)
  try:
    inc branchX
  except OverflowDefect:
    overflowDetected = true

doAssert overflowDetected

var x = high(int)
try:
  inc x
except OverflowDefect:
  echo "ok"
