discard """
  output: '''123
c is not nil'''
"""

# bug #9149

type
  Container = ref object
    data: int

converter containerToString*(x: Container): string = $x.data

var c = Container(data: 123)
var str = string c
echo str

if c == nil: # this line can compile on v0.18, but not on 0.19
  echo "c is nil"

if not c.isNil:
  echo "c is not nil"
