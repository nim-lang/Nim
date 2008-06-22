#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2006 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# type-info module for Nimrod

include hti

proc typeid(x: any): PNimType

type
  Variant = opaque record
    # contains the address and a typeinfo
    a: pointer # an address
    k: TNimTypeKind

# conversions to any and from any are inserted by the compiler!
# x.attr is supported, as well as x[]!
# here is a special iterator for variants:
iterator fields(x: variant): (fieldname: string, value: variant) =
proc setField(structure: variant, fieldname: string, value: variant)
proc getField(structure: variant, fieldname: string)

# any is implemented as a pair (val: pointer, info: PTypeInfo)
# val is for:
# an array - its address
# a record - its address
# an object - its address
# a string - the address of the pointer to the string data
# a sequence - the address of the pointer to the sequence data
# a float - the address of a memory location where the float is stored
#           this is a given address; storage comes from compiler or is
#           already there (in a container)
# an int - the address of a memory location where the int is stored
#         storage comes from compiler or is
#         already there (in a container)
# a cstring - the address of an address of an array of chars
# a ref - the address of the ref! (not the ref itself!)

# But this does not work too well...
# Better: any is a ref to Object; than we define intObj, floatObj,
#   etc.; for strings this not needed as they already fit into the
#   scheme!
#

type
  TAnyImpl {.exportc: "TAnyImpl".} = record
    typ {.exportc: "info".}: PNimType
    val {.exportc: "val".}: pointer

proc
  typeKind(p: PNimType): TTypeKind {.inline.}

  getAnyLength(x: any): int

  isContainer(x: any): bool

  writeAny(container: any, index: int, val: any)
  readAny(container: any, index: int): any

  writeAny(container: any, name: string, val: any)
  readAny(container: any, name: string): any

  getAttr(container: any, index: int, out name: string, out val: any)

  getEnumStrings(enumeration: any): sequence of string

  anyToInt(x: any): biggestint
  anyToFloat(x: any): biggestfloat
  anyToString(x: any): string
  anyToChar(x: any): char
  anyToBool(x: any): bool
  #anyToT{T}(x: any, out result: T)

  # etc...

  #write(a: array of any) # also possible!

#generic proc
#  deepCopy{T}(x: T): T

import
  strutils

proc anyToImpl(a: any): TAnyImpl {.inline.} =
  result = cast{TAnyImpl}(a)

proc typeKind(p: PNimType): TTypeKind =
  result = p.typeKind

type
  Pint = untraced ref int
  Pint8 = untraced ref int8
  Pint16 = untraced ref int16
  Pint32 = untraced ref int32
  Pint64 = untraced ref int64
  Puint = untraced ref uint
  Puint8 = untraced ref uint8
  Puint16 = untraced ref uint16
  Puint32 = untraced ref uint32
  Puint64 = untraced ref uint64
  Pfloat = untraced ref float
  Pfloat32 = untraced ref float32
  Pfloat64 = untraced ref float64
  Pstring = untraced ref string
  Pbool = untraced ref bool
  Pchar = untraced ref char

proc anyToInt(x: any): biggestint =
  var impl = anyToImpl(x)
  case impl.typ.typeKind
    of tyInt, tyEnum: result = cast{pint}(x.val)^
    of tySInt8:  result = cast{pint8}(x.val)^
    of tySInt16: result = cast{pint16}(x.val)^
    of tySInt32: result = cast{pint32}(x.val)^
    of tySInt64: result = cast{pint64}(x.val)^
    of tyUInt:   result = cast{puint}(x.val)^
    of tyUInt8:  result = cast{puint8}(x.val)^
    of tyUInt16: result = cast{puint16}(x.val)^
    of tyUInt32: result = cast{puint32}(x.val)^
    of tyUInt64: result = cast{puint64}(x.val)^
    else: raise EConvertError

proc anyToFloat(x: any): biggestfloat =
  var impl = anyToImpl(x)
  case impl.typ.typeKind
    of tyReal:   result = cast{pfloat}(x.val)^
    of tyReal32: result = cast{pfloat32}(x.val)^
    of tyReal64: result = cast{pfloat64}(x.val)^
    # of tyReal128:
    else: raise EConvertError

proc anyToString(x: any): string =
  var impl = anyToImpl(x)
  case impl.typ.typeKind
    of tyString: result = cast{pstring}(x.val)^
    else: raise EConvertError

proc anyToChar(x: any): char =
  var impl = anyToImpl(x)
  case impl.typ.typeKind
    of tyChar: result = cast{pchar}(x.val)^
    else: raise EConvertError

proc anyToBool(x: any): bool =
  var impl = anyToImpl(x)
  case impl.typ.typeKind
    of tyBool: result = cast{pbool}(x.val)^
    else: raise EConvertError

proc getAnyLength(x: any): int =
  result = anyToImpl(x).typ.len

const
  ContainerSet = {tyArray, tyRecord, tyObject, tyOpenArray, tySequence, tyTable}

proc isContainer(x: any): bool =
  result = anyToImpl(x).typ.typeKind in ContainerSet

proc strcmp(a, b: cstring): int {.external: "strcmp", nodecl.}

proc strToIndex(info: PTypeInfo, str: string): int =
  for i in 0..typ.len-1:
    if strcmp(info.slots[i].name, str) == 0:
      return i
  raise EConvertError

proc writeAny(container: any, index: int, val: any) =
  var x = anyToImpl(container)
  if index >= 0 and index < container.len:
    case x.typ.typeKind
      of tySequence:
        var u = cast{TAddress}(x.val)
        genericAssignAux(cast{pointer}(u) +% x.typ.slots[index].offset +%
                         GenericSeqSize,
                         anyToImpl(val).val, u.typ.baseType)
      of tyArray:
      of tyRecord, tyObject:
      else: raise EConvertError
  else:
    raise EIndexError


proc readAny(container: any, index: int): any =
  var x = anyToImpl(container)
  if x.typ.typeKind in ContainerSet:
    if index >= 0 and index < container.len:
    # XXX

    else:
      raise EIndexError
  else:
    raise EConvertError

proc writeAny(container: any, name: string, val: any) =
  result = writeAny(container, strToIndex(anyToImpl(container).typ), val)

proc readAny(container: any, name: string): any =
  result = readAny(container, strToIndex(anyToImpl(container).typ))

proc getAttr(container: any, index: int, out name: string, out val: any) =
  var x = anyToImpl(container)
  if x.typ.typeKind in ContainerSet:
    val = readAny(container, index)
    name = $x.typ.slots[index].name
  else:
    raise EConvertError

proc getEnumStrings(enumeration: any): sequence of string =
  result = []
  var x = anyToImpl(enumeration)
  if x.typ.typekind == tyEnum:
    for i in 0 .. x.typ.len-1:
      result &= $x.typ.slots[i].name
  else:
    raise EConvertError
