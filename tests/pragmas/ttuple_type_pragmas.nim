discard """
  cmd: "nim check --hints:off $file"
  action: "compile"
  nimoutFull: true
  nimout: '''
ttuple_type_pragmas.nim(34, 12) Warning: the 'packed' pragma is not supported for tuple types: equal tuple types would disagree on the representation; use an object type instead; this will become a compile time error in the future [TupleTypePragma]
ttuple_type_pragmas.nim(35, 12) Warning: the 'bycopy' pragma is not supported for tuple types: equal tuple types would disagree on the representation; use an object type instead; this will become a compile time error in the future [TupleTypePragma]
ttuple_type_pragmas.nim(36, 11) Warning: the 'byref' pragma is not supported for tuple types: equal tuple types would disagree on the representation; use an object type instead; this will become a compile time error in the future [TupleTypePragma]
ttuple_type_pragmas.nim(37, 11) Warning: the 'union' pragma is not supported for tuple types: equal tuple types would disagree on the representation; use an object type instead; this will become a compile time error in the future [TupleTypePragma]
ttuple_type_pragmas.nim(38, 21) Warning: the 'importc' pragma is not supported for tuple types: equal tuple types would disagree on the representation; use an object type instead; this will become a compile time error in the future [TupleTypePragma]
ttuple_type_pragmas.nim(38, 34) Warning: the 'header' pragma is not supported for tuple types: equal tuple types would disagree on the representation; use an object type instead; this will become a compile time error in the future [TupleTypePragma]
ttuple_type_pragmas.nim(39, 12) Warning: the 'nodecl' pragma is not supported for tuple types: equal tuple types would disagree on the representation; use an object type instead; this will become a compile time error in the future [TupleTypePragma]
ttuple_type_pragmas.nim(40, 16) Warning: the 'bycopy' pragma is not supported for tuple types: equal tuple types would disagree on the representation; use an object type instead; this will become a compile time error in the future [TupleTypePragma]
ttuple_type_pragmas.nim(41, 11) Warning: the 'packed' pragma is not supported for tuple types: equal tuple types would disagree on the representation; use an object type instead; this will become a compile time error in the future [TupleTypePragma]
'''
"""

# refs #26424: tuple types are structural, so a pragma that changes how a
# tuple type is laid out, passed or declared would apply to only some of the
# equal types.

type
  Plain = tuple[a: int8, b: int32]

  # no warning: these do not change the representation, or the type is
  # nominal.
  NoWarn1 {.final.} = tuple[a: int8, b: int32]
  NoWarn2 {.pure.} = tuple[a: int8, b: int32]
  NoWarn3 {.deprecated.} = tuple[a: int8, b: int32]
  Obj {.packed, bycopy.} = object
    a: int8
    b: int32

  Packed {.packed.} = tuple[a: int8, b: int32]
  ByCopy {.bycopy.} = tuple[a: int8, b: int32]
  ByRef {.byref.} = tuple[a: int8, b: int32]
  Union {.union.} = tuple[a: int8, b: int32]
  Imported {.importc: "T", header: "<t.h>".} = tuple[a: int8, b: int32]
  NoDecl {.nodecl.} = tuple[a: int8, b: int32]
  Generic[T] {.bycopy.} = tuple[a: T, b: int32]
  Alias {.packed.} = Plain
