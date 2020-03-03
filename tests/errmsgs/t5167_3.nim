discard """
cmd: "nim c --threads:on $file"
errormsg: "type mismatch"
line: 24
"""

type
  TGeneric[T] = object
    x: int

proc foo1[A, B, C, D](x: proc (a: A, b: B, c: C, d: D)) =
  echo "foo1"

proc foo2(x: proc(x: int)) =
  echo "foo2"

# The goal of this test is to verify that none of the generic parameters of the
# proc will be marked as unused. The error message should be "type mismatch" instead
# of "'bar' doesn't have a concrete type, due to unspecified generic parameters".
proc bar[A, B, C, D](x: A, y: seq[B], z: array[4, TGeneric[C]], r: TGeneric[D]) =
  echo "bar"

foo1[int, seq[int], array[4, TGeneric[float]], TGeneric[string]] bar
foo2 bar

