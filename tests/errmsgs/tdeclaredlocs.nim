discard """
  action: reject
  matrix: "--declaredLocs --hints:off"
  nimoutFull: true
  nimout: '''
tdeclaredlocs.nim(92, 3) Error: type mismatch: got <seq[MyInt2]>
but expected one of:
proc fn(a: Bam) [proc declared in tdeclaredlocs.nim(86, 6)]
  first type mismatch at position: 1
  required type for a: Bam [object declared in tdeclaredlocs.nim(78, 3)]
  but expression 'a' is of type: seq[MyInt2{char}] [char declared in tdeclaredlocs.nim(73, 3)]
proc fn(a: Goo[MyInt2]) [proc declared in tdeclaredlocs.nim(89, 6)]
  first type mismatch at position: 1
  required type for a: Goo[MyInt2{char}] [object declared in tdeclaredlocs.nim(79, 3)]
  but expression 'a' is of type: seq[MyInt2{char}] [char declared in tdeclaredlocs.nim(73, 3)]
proc fn(a: Goo[cint]) [proc declared in tdeclaredlocs.nim(88, 6)]
  first type mismatch at position: 1
  required type for a: Goo[cint{int32}] [object declared in tdeclaredlocs.nim(79, 3)]
  but expression 'a' is of type: seq[MyInt2{char}] [char declared in tdeclaredlocs.nim(73, 3)]
proc fn(a: array[3, Bar]) [proc declared in tdeclaredlocs.nim(82, 6)]
  first type mismatch at position: 1
  required type for a: array[0..2, Bar] [object declared in tdeclaredlocs.nim(74, 3)]
  but expression 'a' is of type: seq[MyInt2{char}] [char declared in tdeclaredlocs.nim(73, 3)]
proc fn(a: seq[Bar]) [proc declared in tdeclaredlocs.nim(81, 6)]
  first type mismatch at position: 1
  required type for a: seq[Bar] [object declared in tdeclaredlocs.nim(74, 3)]
  but expression 'a' is of type: seq[MyInt2{char}] [char declared in tdeclaredlocs.nim(73, 3)]
proc fn(a: seq[MyInt1]) [proc declared in tdeclaredlocs.nim(80, 6)]
  first type mismatch at position: 1
  required type for a: seq[MyInt1{int}] [int declared in tdeclaredlocs.nim(72, 3)]
  but expression 'a' is of type: seq[MyInt2{char}] [char declared in tdeclaredlocs.nim(73, 3)]
proc fn(a: set[Baz]) [proc declared in tdeclaredlocs.nim(84, 6)]
  first type mismatch at position: 1
  required type for a: set[Baz{enum}] [enum declared in tdeclaredlocs.nim(75, 3)]
  but expression 'a' is of type: seq[MyInt2{char}] [char declared in tdeclaredlocs.nim(73, 3)]
proc fn(a: set[MyInt2]) [proc declared in tdeclaredlocs.nim(83, 6)]
  first type mismatch at position: 1
  required type for a: set[MyInt2{char}] [char declared in tdeclaredlocs.nim(73, 3)]
  but expression 'a' is of type: seq[MyInt2{char}] [char declared in tdeclaredlocs.nim(73, 3)]
proc fn(a: var SetBaz) [proc declared in tdeclaredlocs.nim(85, 6)]
  first type mismatch at position: 1
  required type for a: var SetBaz [enum declared in tdeclaredlocs.nim(75, 3)]
  but expression 'a' is of type: seq[MyInt2{char}] [char declared in tdeclaredlocs.nim(73, 3)]
proc fn(a: var ref ptr Bam) [proc declared in tdeclaredlocs.nim(87, 6)]
  first type mismatch at position: 1
  required type for a: var ref ptr Bam [object declared in tdeclaredlocs.nim(78, 3)]
  but expression 'a' is of type: seq[MyInt2{char}] [char declared in tdeclaredlocs.nim(73, 3)]

expression: fn(a)
'''
"""

#[
see also: tests/errmsgs/tsigmatch.nim
]#














# line 70
type
  MyInt1 = int
  MyInt2 = char
  Bar = object
  Baz = enum k0, k1
  Baz2 = Baz
  SetBaz = set[Baz2]
  Bam = ref object
  Goo[T] = object
proc fn(a: seq[MyInt1]) = discard
proc fn(a: seq[Bar]) = discard
proc fn(a: array[3, Bar]) = discard
proc fn(a: set[MyInt2]) = discard
proc fn(a: set[Baz]) = discard
proc fn(a: var SetBaz) = discard
proc fn(a: Bam) = discard
proc fn(a: var ref ptr Bam) = discard
proc fn(a: Goo[cint]) = discard
proc fn(a: Goo[MyInt2]) = discard

var a: seq[MyInt2]
fn(a)
