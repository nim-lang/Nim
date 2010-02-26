#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2010 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements Nimrod's support for the ``variant`` datatype.
## `TVariant` shows how the flexibility of dynamic typing is achieved
## within a static type system. 

type
  TVarType* = enum
    vtNone,
    vtBool, 
    vtChar,
    vtEnum,
    vtInt,
    vtFloat,
    vtString,
    vtSet,
    vtSeq,
    vtDict
  TVariant* {.final.} = object of TObject
    case vtype: TVarType
    of vtNone: nil
    of vtBool, vtChar, vtEnum, vtInt: vint: int64
    of vtFloat: vfloat: float64
    of vtString: vstring: string
    of vtSet, vtSeq: q: seq[TVariant]
    of vtDict: d: seq[tuple[key, val: TVariant]]
    
iterator objectFields*[T](x: T, skipInherited: bool): tuple[
  key: string, val: TVariant] {.magic: "ObjectFields"}

proc `?`*(x: ordinal): TVariant =
  result.kind = vtEnum
  result.vint = x

proc `?`*(x: biggestInt): TVariant =
  result.kind = vtInt
  result.vint = x

proc `?`*(x: char): TVariant =
  result.kind = vtChar
  result.vint = ord(x)

proc `?`*(x: bool): TVariant =
  result.kind = vtBool
  result.vint = ord(x)

proc `?`*(x: biggestFloat): TVariant =
  result.kind = vtFloat
  result.vfloat = x

proc `?`*(x: string): TVariant =
  result.kind = vtString
  result.vstring = x

proc `?`*[T](x: openArray[T]): TVariant =
  result.kind = vtSeq
  newSeq(result.q, x.len)
  for i in 0..x.len-1: result.q[i] = <>x[i]

proc `?`*[T](x: set[T]): TVariant =
  result.kind = vtSet
  result.q = @[]
  for a in items(x): result.q.add(<>a)

proc `?`* [T: object](x: T): TVariant {.magic: "ToVariant".}
  ## this converts a value to a variant ("boxing")

proc `><`*[T](v: TVariant, typ: T): T {.magic: "FromVariant".}

?[?5, ?67, ?"hallo"]
myVar?int

  
proc `==`* (x, y: TVariant): bool =
  if x.vtype == y.vtype:
    case x.vtype
    of vtNone: result = true
    of vtBool, vtChar, vtEnum, vtInt: result = x.vint == y.vint
    of vtFloat: result = x.vfloat == y.vfloat
    of vtString: result = x.vstring == y.vstring
    of vtSet:
      # complicated! We check that each a in x also occurs in y and that the
      # counts are identical:
      if x.q.len == y.q.len:
        for a in items(x.q):
          block inner:
            for b in items(y.q):
              if a == b: break inner
            return false
        result = true
    of vtSeq:
      if x.q.len == y.q.len:
        for i in 0..x.q.len-1:
          if x.q[i] != y.q[i]: return false
        result = true
    of vtDict:
      # it is an ordered dict:
      if x.d.len == y.d.len:
        for i in 0..x.d.len-1:
          if x.d[i].key != y.d[i].key: return false
          if x.d[i].val != y.d[i].val: return false
        result = true

proc `[]`* (a, b: TVariant): TVariant =
  case a.vtype
  of vtSeq:
    if b.vtype in {vtBool, vtChar, vtEnum, vtInt}:
      result = a.q[b.vint]
    else:
      variantError()
  of vtDict:
    for i in 0..a.d.len-1:
      if a.d[i].key == b: return a.d[i].val
    if b.vtype in {vtBool, vtChar, vtEnum, vtInt}:
      result = a.d[b.vint].val
    variantError()
  else: variantError()

proc `[]=`* (a, b, c: TVariant) =
  case a.vtype
  of vtSeq:
    if b.vtype in {vtBool, vtChar, vtEnum, vtInt}:
      a.q[b.vint] = b
    else:
      variantError()
  of vtDict:
    for i in 0..a.d.len-1:
      if a.d[i].key == b:
        a.d[i].val = c
        return
    if b.vtype in {vtBool, vtChar, vtEnum, vtInt}:
      a.d[b.vint].val = c
    variantError()
  else: variantError()
  
proc `[]`* (a: TVariant, b: int): TVariant {.inline} = return a[?b]
proc `[]`* (a: TVariant, b: string): TVariant {.inline} = return a[?b]
proc `[]=`* (a: TVariant, b: int, c: TVariant) {.inline} = a[?b] = c
proc `[]=`* (a: TVariant, b: string, c: TVariant) {.inline} = a[?b] = c

proc `+`* (x, y: TVariant): TVariant =
  case x.vtype
  of vtBool, vtChar, vtEnum, vtInt:
    if y.vtype == x.vtype:
      result.vtype = x.vtype
      result.vint = x.vint + y.vint
    else:
      case y.vtype
      of vtBool, vtChar, vtEnum, vtInt:
        
    
    
    vint: int64
  of vtFloat: vfloat: float64
  of vtString: vstring: string
  of vtSet, vtSeq: q: seq[TVariant]
  of vtDict: d: seq[tuple[key, val: TVariant]]

proc `-`* (x, y: TVariant): TVariant
proc `*`* (x, y: TVariant): TVariant
proc `/`* (x, y: TVariant): TVariant
proc `div`* (x, y: TVariant): TVariant
proc `mod`* (x, y: TVariant): TVariant
proc `&`* (x, y: TVariant): TVariant
proc `$`* (x: TVariant): string =
  # uses JS notation
  
proc parseVariant*(s: string): TVariant
proc `<`* (x, y: TVariant): bool
proc `<=`* (x, y: TVariant): bool

proc hash*(x: TVariant): int =
  

