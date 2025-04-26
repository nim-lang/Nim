discard """
action: run
"""

block: #24913
  type
    A = object
      b: int
    B = object
      b: proc(x: float): int

  proc b(T: typedesc[A]; s: float): int = 5
  proc b(T: typedesc[B]; s: float): int = 7
  proc testme(x: float): int = 3
  doAssert A.b(1.0) == 5
  doAssert B.b(1.0) == 7
  doAssert B(b: testme).b(1.0) == 3
