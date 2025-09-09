discard """
cmd: "nim check --hints:off $file"
action: "reject"
nimoutFull: true
nimout: '''
t22753.nim(58, 13) Error: array expects two type parameters
t22753.nim(59, 1) Error: expression 'x' has no type (or is ambiguous)
t22753.nim(59, 1) Error: expression 'x' has no type (or is ambiguous)
t22753.nim(59, 1) Error: expression 'x' has no type (or is ambiguous)
t22753.nim(59, 1) Error: expression 'x' has no type (or is ambiguous)
t22753.nim(59, 2) Error: type mismatch: got <>
but expected one of:
proc `[]`(s: string; i: BackwardsIndex): char
  first type mismatch at position: 2
  required type for i: BackwardsIndex
  but expression '0' is of type: int literal(0)
proc `[]`(s: var string; i: BackwardsIndex): var char
  first type mismatch at position: 2
  required type for i: BackwardsIndex
  but expression '0' is of type: int literal(0)
proc `[]`[I: Ordinal; T](a: T; i: I): T
  first type mismatch at position: 0
proc `[]`[Idx, T; U, V: Ordinal](a: array[Idx, T]; x: HSlice[U, V]): seq[T]
  first type mismatch at position: 2
  required type for x: HSlice[[].U, [].V]
  but expression '0' is of type: int literal(0)
proc `[]`[Idx, T](a: array[Idx, T]; i: BackwardsIndex): T
  first type mismatch at position: 2
  required type for i: BackwardsIndex
  but expression '0' is of type: int literal(0)
proc `[]`[Idx, T](a: var array[Idx, T]; i: BackwardsIndex): var T
  first type mismatch at position: 2
  required type for i: BackwardsIndex
  but expression '0' is of type: int literal(0)
proc `[]`[T, U: Ordinal](s: string; x: HSlice[T, U]): string
  first type mismatch at position: 2
  required type for x: HSlice[[].T, [].U]
  but expression '0' is of type: int literal(0)
proc `[]`[T; U, V: Ordinal](s: openArray[T]; x: HSlice[U, V]): seq[T]
  first type mismatch at position: 2
  required type for x: HSlice[[].U, [].V]
  but expression '0' is of type: int literal(0)
proc `[]`[T](s: openArray[T]; i: BackwardsIndex): T
  first type mismatch at position: 2
  required type for i: BackwardsIndex
  but expression '0' is of type: int literal(0)
proc `[]`[T](s: var openArray[T]; i: BackwardsIndex): var T
  first type mismatch at position: 2
  required type for i: BackwardsIndex
  but expression '0' is of type: int literal(0)

expression: x[0]
t22753.nim(59, 2) Error: expression '' has no type (or is ambiguous)
t22753.nim(59, 2) Error: '' cannot be assigned to
'''
"""

var x: array[3] # bug #22753
x[0] = 9
