type
  TFoo[T] = object
    val: T

  T1 = expr
  T2 = expr

  Numeric = int|float

proc takesExpr(x, y) =
  echo x, y

proc same(x, y: T1) =
  echo x, y

proc takesFoo(x, y: TFoo) =
  echo x.val, y.val

proc takes2Types(x,y: T1, z: T2) =
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

