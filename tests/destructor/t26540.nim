discard """
  matrix: "--mm:refc"
  output: '''
3 3 3
3 3 3 3
3 3
1 2 3
'''
"""

# bug #26540: `=dup` of a seq whose element type has a hook returned an
# empty seq with refc
type D = object
  x: int

proc `=destroy`(d: var D) = discard

type R = object
  s: seq[D]

proc mk(p: seq[D]): R = R(s: p)
proc takeSink(s: sink seq[D]): int = s.len

var a = @[D(x: 1), D(x: 2), D(x: 3)]
let b = @[a]
var c: seq[seq[D]]
c.add a
echo b[0].len, " ", c[0].len, " ", a.len

let t = (a, 1)
let arr = [a, a]
echo t[0].len, " ", arr[0].len, " ", arr[1].len, " ", mk(a).s.len

let d = `=dup`(a)
echo d.len, " ", takeSink(a)

var e = `=dup`(a)
e[0].x = 10
echo a[0].x, " ", a[1].x, " ", a[2].x
