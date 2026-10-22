discard """
  output: '''
42
7
3
'''
"""

# bug #26521: trying the `static` overload must not turn `doit(r)` into a
# by-value call
type R = ref object
  v: int

proc foo(r: int): int = r
proc foo(s: static[int]) = discard
proc doit(x: var R): int =
  x = R(v: 42)
  0

var r = R(v: 1)
discard doit(r).foo()
echo r.v

proc bar(x: int): int = x
proc bar(s: static[int]) = discard
proc inc2(x: var int): int =
  x = 7
  0

var i = 1
discard inc2(i).bar()
echo i

proc baz(x: int): int = x
proc baz(s: static[int]): int = s + 1
echo 2.baz()
