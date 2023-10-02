discard """
  cmd: "nim check $file"
  errormsg: "illformed AST: case buf[pos]"
  nimout: '''
t10735.nim(43, 5) Error: 'let' symbol requires an initialization
t10735.nim(44, 10) Error: undeclared identifier: 'pos'
t10735.nim(44, 10) Error: expression 'pos' has no type (or is ambiguous)
t10735.nim(44, 10) Error: expression 'pos' has no type (or is ambiguous)
t10735.nim(44, 9) Error: type mismatch: got <cstring, >
but expected one of:
proc `[]`(s: string; i: BackwardsIndex): char
  first type mismatch at position: 0
proc `[]`(s: var string; i: BackwardsIndex): var char
  first type mismatch at position: 0
proc `[]`[I: Ordinal; T](a: T; i: I): T
  first type mismatch at position: 0
proc `[]`[Idx, T; U, V: Ordinal](a: array[Idx, T]; x: HSlice[U, V]): seq[T]
  first type mismatch at position: 0
proc `[]`[Idx, T](a: array[Idx, T]; i: BackwardsIndex): T
  first type mismatch at position: 0
proc `[]`[Idx, T](a: var array[Idx, T]; i: BackwardsIndex): var T
  first type mismatch at position: 0
proc `[]`[T, U: Ordinal](s: string; x: HSlice[T, U]): string
  first type mismatch at position: 0
proc `[]`[T; U, V: Ordinal](s: openArray[T]; x: HSlice[U, V]): seq[T]
  first type mismatch at position: 0
proc `[]`[T](s: openArray[T]; i: BackwardsIndex): T
  first type mismatch at position: 0
proc `[]`[T](s: var openArray[T]; i: BackwardsIndex): var T
  first type mismatch at position: 0
template `[]`(a: WideCStringObj; idx: int): Utf16Char
  first type mismatch at position: 0
template `[]`(s: string; i: int): char
  first type mismatch at position: 0

expression: `[]`(buf, pos)
t10735.nim(44, 9) Error: expression '' has no type (or is ambiguous)
t10735.nim(46, 3) Error: illformed AST: case buf[pos]
'''
  joinable: false
"""

let buf: cstring
case buf[pos]
else:
  case buf[pos]
