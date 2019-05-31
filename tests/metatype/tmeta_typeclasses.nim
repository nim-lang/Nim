discard """
  output: '''12
1xxx
true0
12
testtest
1010
11string
testtest1
seq
seq
seq
foo seq
foo of numeric'''"""

type
  TFoo[T] = object
    val: T

  T1 = auto
  T2 = auto

  Numeric = int|float

proc takesExpr(x, y: auto) =
  echo x, y

proc same(x, y: T1) =
  echo x, y

proc takesFoo(x, y: TFoo) =
  echo x.val, y.val

proc takes2Types[T1, T2](x,y: T1, z: T2) =
  echo x, y, z

takesExpr(1, 2)
takesExpr(1, "xxx")
takesExpr[bool, int](true, 0)

same(1, 2)
same("test", "test")

var f: TFoo[int]
f.val = 10

takesFoo(f, f)

takes2Types(1, 1, "string")
takes2Types[string, int]("test", "test", 1)

proc takesSeq(x: seq) =
  echo "seq"

takesSeq(@[1, 2, 3])
takesSeq(@["x", "y", "z"])

proc takesSeqOfFoos(x: seq[TFoo]) =
  echo "foo seq"

var sf = newSeq[TFoo[int]](3)

takesSeq(sf)
takesSeqOfFoos(sf)

proc takesFooOfNumeric(x: TFoo[Numeric]) =
  echo "foo of numeric"

takesFooOfNumeric(sf[0])

