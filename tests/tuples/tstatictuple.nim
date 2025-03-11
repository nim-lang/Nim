# issue #24755

type
  Field = object
  FieldS = object
  FieldOps = enum
    foNeg, foAdd, foSub, foMul, foDiv, foAdj, foToSingle, foToDouble
  FieldUnop[Op: static FieldOps, T1] = object
    f1: T1
  FieldAddSub[S: static tuple, T: tuple] = object
    field: T
  SomeField = Field | FieldS | FieldUnop | FieldAddSub
  SomeField2 = Field | FieldS | FieldUnop | FieldAddSub

template fieldUnop[X:SomeField](o: static FieldOps, x: X): auto =
  FieldUnop[o,X](f1: x)
template fieldAddSub[X,Y](sx: static int, x: X, sy: static int, y: Y): auto =
  FieldAddSub[(a:sx,b:sy),tuple[a:X,b:Y]](field:(a:x,b:y))

template `:=`*(r: var FieldS, x: SomeField) =
  discard
template toSingle(x: SomeField): auto =
  fieldUnop(foToSingle, x)
template toDouble(x: SomeField): auto =
  fieldUnop(foToDouble, x)
template `+`(x: SomeField, y: SomeField2): auto =
  fieldAddSub(1, x, 1, y)

var
  fd: Field
  fs,fs2: FieldS

fs2 := toSingle(fs.toDouble + fd)
