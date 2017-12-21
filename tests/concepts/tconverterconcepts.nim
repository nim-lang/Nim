discard """
output: '''
10
test
12.02
10
10
10
cannot square
cannot square
100
4
121
4
4
11
10.23
3
'''
"""

import typetraits

template tryRet(x) =
  when compiles(x):
    return x

type
  Stringable = concept x
    return $x

  FixedLiteral = concept x
    return 10

  Squared = concept y
    when y is int:
      return $(y * y)
    else:
      return "cannot square"

  TryLen = concept y
    when compiles(y.len):
      return y.len

  AnotherTryLen = concept x
    tryRet(len(x))

proc stringableTest(x: Stringable) =
  echo x

stringableTest 10
stringableTest "test"
stringableTest 12.02

proc fixedLiteralTest(x: FixedLiteral) =
  echo x

fixedLiteralTest 20
fixedLiteralTest "test"
fixedLiteralTest [1, 2, 3]

proc squaredTest(x: Squared) =
  echo x

squaredTest "test"
squaredTest 2.0
squaredTest 10

proc tryLenTest(x: TryLen) =
  echo x

tryLenTest "test"
tryLenTest 121
tryLenTest [1, 2, 3, 4]

proc anotherTryLenTest(x: AnotherTryLen) =
  echo x

anotherTryLenTest "test"
anotherTryLenTest 11
anotherTryLenTest 10.23
anotherTryLenTest [2, 3, 4]

