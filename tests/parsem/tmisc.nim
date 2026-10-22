discard """
  matrix: "--parsem:on"
  output: '''
3
@[2, 4, 6]
1 2 3
B
yes
not yet
17
'''
"""

# Generic instances, iterators, methods and `compiles` in bodies that refer
# to routines declared further down.

proc useGeneric(): int = twice(1) + addOne(0)
proc twice[T](x: T): T = later(x) * 2
proc later[T](x: T): T = x
proc addOne(x: int): int = x + 1
echo useGeneric()

proc collect(): seq[int] =
  for x in evens(): result.add x
iterator evens(): int =
  for i in 1..3: yield double(i)
proc double(x: int): int = x * 2
echo collect()

proc show() = echo items3()
proc items3(): string =
  for x in countUp3(): result.add $x & " "
  result.setLen result.len - 1
iterator countUp3(): int {.closure.} =
  yield 1; yield 2; yield 3
show()

type
  A = ref object of RootObj
  B = ref object of A

proc dispatch(x: A) = echo name(x)
method name(x: A): string {.base.} = "A"
method name(x: B): string = "B"
dispatch(B())

proc check(): string =
  when compiles(declaredLater(1)): "yes" else: "no"
proc declaredLater(x: int): int = x
echo check()

# a top-level statement still only sees what is declared above it:
echo(when compiles(notYet()): "already" else: "not yet")
proc notYet() = discard

# mutual recursion where the cycle is broken by an annotated forward
# declaration, exactly as without `--parsem`:
proc f(n: int): int {.gcsafe, raises: [].}
proc g(n: int): int = (if n <= 0: 0 else: f(n - 1) + 1)
proc f(n: int): int = (if n <= 0: 0 else: g(n - 1) + 1)
proc h() {.gcsafe.} = echo g(17)
h()
