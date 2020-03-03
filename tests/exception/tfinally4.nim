discard """
  output: '''
B1
A1
1
B1
B2
catch
A1
1
B1
A1
A2
2
B1
B2
catch
A1
A2
0
B1
A1
1
B1
B2
A1
1
B1
A1
A2
2
B1
B2
A1
A2
3'''
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
