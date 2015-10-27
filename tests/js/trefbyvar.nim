discard """
  output: '''0
5
0
5'''
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
