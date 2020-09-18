discard """
  output: "ok"
  cmd: "nim $target --overflowChecks:off $options $file"
"""
# Tests nim's ability to detect overflows

{.push overflowChecks: on.}

var
  a = high(int)
  b = -2
  overflowDetected = false

try:
  writeLine(stdout, b - a)
except OverflowDefect:
  overflowDetected = true

{.pop.} # overflow check

doAssert(overflowDetected)

block: # Overflow checks in a proc
  var
    a = high(int)
    b = -2
    overflowDetected = false

  {.push overflowChecks: on.}
  proc foo() =
    let c = b - a
  {.pop.}

  try:
    foo()
  except OverflowDefect:
    overflowDetected = true

  doAssert(overflowDetected)

block: # Overflow checks in a forward declared proc
  var
    a = high(int)
    b = -2
    overflowDetected = false

  proc foo()

  {.push overflowChecks: on.}
  proc foo() =
    let c = b - a
  {.pop.}

  try:
    foo()
  except OverflowDefect:
    overflowDetected = true

  doAssert(overflowDetected)

block: # Overflow checks doesn't affect fwd declaration
  var
    a = high(int)
    b = -2
    overflowDetected = false

  {.push overflowChecks: on.}
  proc foo()
  {.pop.}

  proc foo() =
    let c = b - a

  try:
    foo()
  except OverflowDefect:
    overflowDetected = true

  doAssert(not overflowDetected)


echo "ok"
