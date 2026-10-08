discard """
  joinable: false
  targets: "c js"
  matrix: "--experimental:cyclicImports"
  output: '''
1
2
1
10
120
dark
42
'''
"""

import mcyclic_procs {.cyclic.}

type
  Celsius* = distinct float

proc fromA*(): int = 1

proc useB*(b: B): int = fromB()

# mutual recursion across the two modules:
proc isEven*(n: int): bool =
  if n == 0: true else: isOdd(n - 1)

proc fact*(n: int): int =
  if n <= 1: 1 else: n * factB(n - 1)

echo fromA()
echo useB(B())
echo useA()
echo ord(isEven(10)) * 10
echo fact(5)
echo shade()
echo truncInt(Celsius(42.0))

# the converter and the pure enum of the partner are imported once they exist:
let c: float = Celsius(1.5)
doAssert c == 1.5
doAssert dark == Color.dark
