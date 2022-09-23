discard """
  matrix: "--hint:all:off --hint:XDeclaredButNotUsed"
  nimoutFull: true
  nimout: '''
treportunused.nim(51, 5) Hint: 'A' is declared but not used [XDeclaredButNotUsed]
treportunused.nim(52, 5) Hint: 'B' is declared but not used [XDeclaredButNotUsed]
treportunused.nim(55, 5) Hint: 'D' is declared but not used [XDeclaredButNotUsed]
treportunused.nim(56, 5) Hint: 'E' is declared but not used [XDeclaredButNotUsed]
treportunused.nim(59, 5) Hint: 'G' is declared but not used [XDeclaredButNotUsed]
treportunused.nim(60, 5) Hint: 'H' is declared but not used [XDeclaredButNotUsed]
treportunused.nim(64, 5) Hint: 'K' is declared but not used [XDeclaredButNotUsed]
treportunused.nim(65, 5) Hint: 'L' is declared but not used [XDeclaredButNotUsed]
treportunused.nim(31, 10) Hint: 's1' is declared but not used [XDeclaredButNotUsed]
treportunused.nim(32, 10) Hint: 's2' is declared but not used [XDeclaredButNotUsed]
treportunused.nim(33, 10) Hint: 's3' is declared but not used [XDeclaredButNotUsed]
treportunused.nim(34, 6) Hint: 's4' is declared but not used [XDeclaredButNotUsed]
treportunused.nim(35, 6) Hint: 's5' is declared but not used [XDeclaredButNotUsed]
treportunused.nim(36, 7) Hint: 's6' is declared but not used [XDeclaredButNotUsed]
treportunused.nim(37, 7) Hint: 's7' is declared but not used [XDeclaredButNotUsed]
treportunused.nim(38, 5) Hint: 's8' is declared but not used [XDeclaredButNotUsed]
treportunused.nim(39, 5) Hint: 's9' is declared but not used [XDeclaredButNotUsed]
treportunused.nim(40, 6) Hint: 's10' is declared but not used [XDeclaredButNotUsed]
treportunused.nim(41, 6) Hint: 's11' is declared but not used [XDeclaredButNotUsed]
treportunused.nim(45, 3) Hint: 'v0.99' is declared but not used [XDeclaredButNotUsed]
treportunused.nim(46, 3) Hint: 'v0.99.99' is declared but not used [XDeclaredButNotUsed]
'''
action: compile
"""

# bug #9764
iterator s1(a:string): int = discard
iterator s2(): int = discard
template s3(): untyped = 123
proc s4(): int = 123
proc s5[T](a: T): int = 123
macro s6(a: int): untyped = discard
const s7 = 0
let s8 = 0
var s9: int
type s10 = object
type s11 = type(1.2)

# bug #14407 (requires `compiler/nim.cfg` containing define:nimPreviewFloatRoundtrip)
let
  `v0.99` = "0.99"
  `v0.99.99` = "0.99.99"

block: # bug #18201
  # Test that unused type aliases raise hint XDeclaredButNotUsed.
  type
    A = int
    B = distinct int

    C = object
    D = C
    E = distinct C

    F = string
    G = F
    H = distinct F

    J = enum
      Foo
    K = J
    L = distinct J
