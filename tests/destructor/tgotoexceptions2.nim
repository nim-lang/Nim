discard """
  cmd: "nim c --gc:arc --exceptions:goto $file"
  output: '''
B1
B2
catch
A1
1
B1
B2
catch
A1
A2
0
B1
B2
A1
1
B1
B2
A1
A2
3
A
B
C
'''
"""

# More thorough test of return-in-finaly

var raiseEx = true
var returnA = true
var returnB = false

proc main: int =
  try: #A
    try: #B
      if raiseEx:
        raise newException(OSError, "")
      return 3
    finally: #B
      echo "B1"
      if returnB:
        return 2
      echo "B2"
  except OSError: #A
    echo "catch"
  finally: #A
    echo "A1"
    if returnA:
      return 1
    echo "A2"

for x in [true, false]:
  for y in [true, false]:
    # echo "raiseEx: " & $x
    # echo "returnA: " & $y
    # echo "returnB: " & $z
    # in the original test returnB was set to true too and
    # this leads to swallowing the OSError exception. This is
    # somewhat compatible with Python but it's non-sense, 'finally'
    # should not be allowed to swallow exceptions. The goto based
    # implementation does something sane so we don't "correct" its
    # behavior just to be compatible with v1.
    raiseEx = x
    returnA = y
    echo main()

# Various tests of return nested in double try/except statements

proc test1() =

  defer: echo "A"

  try:
    raise newException(OSError, "Problem")
  except OSError:
    return

test1()


proc test2() =

  defer: echo "B"

  try:
    return
  except OSError:
    discard

test2()

proc test3() =
  try:
    try:
      raise newException(OSError, "Problem")
    except OSError:
      return
  finally:
    echo "C"

test3()
