discard """
  matrix: "--mm:orc; --mm:refc"
  output: '''
[2, 5]
[2, 5]
[7, 2, 3]
@[4, 9]
'''
"""

# bug #26329
type O = object
  a: int
  arr: array[2, int]

var o = O(a: 5)
o = O(a: 1, arr: [2, o.a])
echo o.arr

proc main =
  var o = O(a: 5)
  o = O(a: 1, arr: [2, o.a])
  echo o.arr

  type P = object
    a: int
    b: array[3, int]
  var p = P(a: 3, b: [1, 2, 7])
  p = P(a: 0, b: [p.b[2], p.b[1], p.a])
  echo p.b

  type Q = object
    a: int
    s: seq[int]
  var q = Q(a: 9)
  q = Q(a: 0, s: @[4, q.a])
  echo q.s

main()
