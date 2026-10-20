discard """
  output: '''
Hello world
4.21
12.4
@[()]
caught
'''
"""

echo "Hello world"

# bug #15081
proc logic() =
  echo 4.21
  var x = 12.4
  echo x
logic()

# bug #11974
type Y = object
var ys = @[Y()]
echo ys

# bug #22824
type TT = object of Defect
try:
  raise TT.newException("Test")
except TT:
  echo "caught"
