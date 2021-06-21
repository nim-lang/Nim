discard """
output: '''
it's nil
@[1, 2, 3]
'''
"""

import macros


block anontuples:
  proc `^` (a, b: int): int =
    result = 1
    for i in 1..b: result = result * a

  var m = (0, 5)
  var n = (56, 3)

  m = (n[0] + m[1], m[1] ^ n[1])

  doAssert m == (61, 125)

  # also test we can produce unary anon tuples in a macro:
  macro mm(): untyped =
    result = newTree(nnkTupleConstr, newLit(13))

  proc nowTuple(): (int,) =
    result = (0,)

  doAssert nowTuple() == (Field0: 0)
  doAssert mm() == (Field0: 13)



block unpack_asgn:
  proc foobar(): (int, int) = (2, 4)

  # test within a proc:
  proc pp(x: var int) =
    var y: int
    (y, x) = foobar()

  template pt(x) =
    var y: int
    (x, y) = foobar()

  # test within a generic:
  proc pg[T](x, y: var T) =
    pt(x)

  # test as a top level statement:
  var x, y, a, b: int
  # test for regression:
  (x, y) = (1, 2)
  (x, y) = fooBar()

  doAssert x == 2
  doAssert y == 4

  pp(a)
  doAssert a == 4

  pg(a, b)
  doAssert a == 2
  doAssert b == 0



block unpack_const:
  const (a, ) = (1, )
  doAssert a == 1

  const (b, c) = (2, 3)
  doAssert b == 2
  doAssert c == 3

  # bug #10098
  const (x, y, z) = (4, 5, 6)
  doAssert x == 4
  doAssert y == 5
  doAssert z == 6


# bug #10724
block unpack_const_named:
  const (a, ) = (x: 1, )
  doAssert a == 1

  const (b, c) = (x: 2, y: 3)
  doAssert b == 2
  doAssert c == 3

  const (d, e, f) = (x: 4, y: 5, z: 6)
  doAssert d == 4
  doAssert e == 5
  doAssert f == 6

block const_named:
  const x = block:
    (a: 1, b: 2, c: 3)
  doAssert x.a == 1
  doAssert x.b == 2
  doAssert x.c == 3


block tuple_subscript:
  proc`[]` (t: tuple, key: string): string =
    for name, field in fieldPairs(t):
      if name == key:
        return $field
    return ""

  proc`[]` [A,B](t: tuple, key: string, op: (proc(x: A): B)): B =
    for name, field in fieldPairs(t):
      when field is A:
        if name == key:
          return op(field)

  proc`[]=`[T](t: var tuple, key: string, val: T) =
    for name, field in fieldPairs(t):
      when field is T:
        if name == key:
          field = val

  var tt = (a: 1, b: "str1")

  # test built in operator
  tt[0] = 5

  doAssert tt[0] == 5
  doAssert `[]`(tt, 0) == 5

  # test overloaded operator
  tt["b"] = "str2"
  doAssert tt["b"] == "str2"
  doAssert `[]`(tt, "b") == "str2"
  doAssert tt["b", proc(s: string): int = s.len] == 4



block tuple_with_seq:
  template foo(s: string = "") =
    if s.len == 0:
      echo "it's nil"
    else:
      echo s
  foo

  # bug #2632
  proc takeTup(x: tuple[s: string;x: seq[int]]) =
    discard
  takeTup(("foo", @[]))

  #proc foobar(): () =
  proc f(xs: seq[int]) =
    discard

  proc g(t: tuple[n:int, xs:seq[int]]) =
    discard

  when true:
    f(@[]) # OK
    g((1,@[1])) # OK
    g((0,@[])) # NG

  # bug #2630
  type T = tuple[a: seq[int], b: int]
  var t: T = (@[1,2,3], 7)

  proc test(s: seq[int]): T =
    echo s
    (s, 7)
  t = test(t.a)
