discard """
  output: '''0
5
0
5
@[1, 2]
~'''
"""

# bug #2476

type A = ref object
    m: int

proc f(a: var A) =
    var b: A
    b.new()
    b.m = 5
    a = b

var t: A
t.new()

echo t.m
t.f()
echo t.m

proc main =
  # now test the same for locals
  var t: A
  t.new()

  echo t.m
  t.f()
  echo t.m

main()

# bug #5974
type
  View* = object
    data: ref seq[int]

let a = View(data: new(seq[int]))
a.data[] = @[1, 2]

echo a.data[]

# bug #5379
var input = newSeq[ref string]()
input.add(nil)
input.add(new string)
input[1][] = "~"
echo input[1][]
