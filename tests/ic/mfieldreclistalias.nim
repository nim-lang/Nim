type
  Envelope* = object
    payload*: seq[byte]
    signature*: int

proc flatTypeInternal(value: auto): auto = value

template flatType(value: auto): type =
  typeof(flatTypeInternal(value))

template protoType(FieldType: untyped) =
  type FlatType = flatType(default(FieldType))
  discard default(FlatType)

proc check*[T](value: T): int =
  for name, field in fieldPairs(value):
    protoType(typeof(field))
  value.signature

proc run*(): int = check(Envelope())
