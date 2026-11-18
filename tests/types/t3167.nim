discard """
  output: "3"
"""

# bug #3167: generic proc type alias in a recursive object
type
  ParserThunk[T] = (proc(): T)

  ArgDefType = enum
    adtValue
    adtMoreArgs

  ArgDef = ref object
    case typ: ArgDefType
    of adtValue:
      valueType: int
    of adtMoreArgs:
      args: ParserThunk[ArgsDef]

  ArgsDef = ParserThunk[seq[ArgDef]]

proc valueArgDef(name: string, valueType: int): ArgDef =
  ArgDef(typ: adtValue, valueType: valueType)

echo valueArgDef("a", 3).valueType
