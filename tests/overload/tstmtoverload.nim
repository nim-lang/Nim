
# bug #2481
import math

template test(loopCount: int, extraI: int, testBody: untyped): typed =
  block:
    for i in 0..loopCount-1:
      testBody
    echo "done extraI=", extraI

template test(loopCount: int, extraF: float, testBody: untyped): typed =
  block:
    test(loopCount, round(extraF).int, testBody)

template test(loopCount: int, testBody: untyped): typed =
  block:
    test(loopCount, 0, testBody)
    echo "done extraI passed 0"

when isMainModule:
  var
    loops = 0

  test 0, 0:
    loops += 1
  echo "test 0 complete, loops=", loops

  test 1, 1.0:
    loops += 1
  echo "test 1.0 complete, loops=", loops

  when true:
    # when true we get the following compile time error:
    #   b.nim(35, 6) Error: expression 'loops += 1' has no type (or is ambiguous)
    loops = 0
    test 2:
      loops += 1
    echo "test no extra complete, loops=", loops
