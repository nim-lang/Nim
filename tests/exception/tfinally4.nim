discard """
  file: "tfinally4.nim"
  output: "B1\NA1\N1\NB1\NB2\Ncatch\NA1\N1\NB1\NA1\NA2\N2\NB1\NB2\Ncatch\NA1\NA2\N0\NB1\NA1\N1\NB1\NB2\NA1\N1\NB1\NA1\NA2\N2\NB1\NB2\NA1\NA2\N3"
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
    for z in [true, false]:
      # echo "raiseEx: " & $x
      # echo "returnA: " & $y
      # echo "returnB: " & $z
      raiseEx = x
      returnA = y
      returnB = z
      echo main()
