discard """
  matrix: "--parsem:on"
  output: '''
odd 7: true
even 10: true
11
from a template declared below
3
6
42
gcsafe ok
'''
"""

import std/macros

# Bodies are checked against the complete top-level scope: no forward
# declarations needed for routines declared further down.

proc isOdd(n: int): bool =
  if n == 0: false else: isEven(n - 1)

proc isEven(n: int): bool =
  if n == 0: true else: isOdd(n - 1)

echo "odd 7: ", isOdd(7)
echo "even 10: ", isEven(10)

# `auto` return types of routines declared below:
proc useLater(): int = later() + 1
proc later(): auto = 10
echo useLater()

# templates declared below:
proc greet() = tmpl()
template tmpl() = echo "from a template declared below"
greet()

# compile-time evaluation reaching a body that calls a routine declared further
# down -- the routine just has to be declared above the evaluation:
proc helper(): int = helper2() + 1
proc helper2(): int = 2
const C = helper()
echo C

proc viaMacro(): int = helper() * 2
macro m(): untyped =
  result = newLit(viaMacro())
echo m()

# effects are inferred through a routine declared below:
proc caller(): int {.gcsafe, raises: [].} = callee()
proc callee(): int = 42
echo caller()

proc threadSafe() {.gcsafe.} =
  echo "gcsafe ok"
proc run() {.gcsafe.} = threadSafe()
run()
