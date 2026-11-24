discard """
  output: '''
1 2
2 3
abcd
'''
"""

# bug #26789: a routine returning `lent T` whose body is an `if` or `case`
# expression; the address of a parameter in a branch was dropped

func f(a: seq[int], b: bool): lent seq[int] =
  if b: a else: a

func g(a: seq[int], k: bool): lent seq[int] =
  case k
  of true: a
  of false: a

type O = object
  x, y: seq[int]

func field(o: O, first: bool): lent seq[int] =
  if first: o.x else: o.y

func str(s: string, b: bool): lent string =
  if b: s else: s

let a = @[1, 2]
echo f(a, true)[0], " ", g(a, false)[1]
let o = O(x: @[2], y: @[3])
echo field(o, true)[0], " ", field(o, false)[0]
var s = "ab"
s.add "cd"
echo str(s, false)
