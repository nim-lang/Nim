discard """
targets: "c cpp"
output: "ok"
"""
var closureIterResult = newSeq[int]()

proc checkpoint(arg: int) =
    closureIterResult.add(arg)

type
    TestException = object of Exception
    AnotherException = object of Exception

proc testClosureIterAux(it: iterator(): int, exceptionExpected: bool, expectedResults: varargs[int]) =
    closureIterResult.setLen(0)

    var exceptionCaught = false

    try:
        for i in it():
            closureIterResult.add(i)
    except TestException:
        exceptionCaught = true

    if closureIterResult != @expectedResults or exceptionCaught != exceptionExpected:
        if closureIterResult != @expectedResults:
            echo "Expected: ", @expectedResults
            echo "Actual: ", closureIterResult
        if exceptionCaught != exceptionExpected:
            echo "Expected exception: ", exceptionExpected
            echo "Got exception: ", exceptionCaught
        doAssert(false)

proc test(it: iterator(): int, expectedResults: varargs[int]) =
    testClosureIterAux(it, false, expectedResults)

proc testExc(it: iterator(): int, expectedResults: varargs[int]) =
    testClosureIterAux(it, true, expectedResults)

proc raiseException() =
    raise newException(TestException, "Test exception!")

block:
    iterator it(): int {.closure.} =
        var i = 5
        while i != 0:
            yield i
            if i == 3:
                yield 123
            dec i

    test(it, 5, 4, 3, 123, 2, 1)

block:
    iterator it(): int {.closure.} =
        yield 0
        try:
            checkpoint(1)
            raiseException()
        except TestException:
            checkpoint(2)
            yield 3
            checkpoint(4)
        finally:
            checkpoint(5)

        checkpoint(6)

    test(it, 0, 1, 2, 3, 4, 5, 6)

block:
    iterator it(): int {.closure.} =
        yield 0
        try:
            yield 1
            checkpoint(2)
        finally:
            checkpoint(3)
            yield 4
            checkpoint(5)
            yield 6

    test(it, 0, 1, 2, 3, 4, 5, 6)

block:
    iterator it(): int {.closure.} =
        yield 0
        try:
            yield 1
            raiseException()
            yield 2
        finally:
            checkpoint(3)
            yield 4
            checkpoint(5)
            yield 6

    testExc(it, 0, 1, 3, 4, 5, 6)

block:
    iterator it(): int {.closure.} =
        try:
            try:
                raiseException()
            except AnotherException:
                yield 123
            finally:
                checkpoint(3)
        finally:
            checkpoint(4)

    testExc(it, 3, 4)

block:
    iterator it(): int {.closure.} =
        try:
            yield 1
            raiseException()
        except AnotherException:
            checkpoint(123)
        finally:
            checkpoint(2)
        checkpoint(3)

    testExc(it, 1, 2)

block:
    iterator it(): int {.closure.} =
        try:
            yield 0
            try:
                yield 1
                try:
                    yield 2
                    raiseException()
                except AnotherException:
                    yield 123
                finally:
                    yield 3
            except AnotherException:
                yield 124
            finally:
                yield 4
            checkpoint(1234)
        except:
            yield 5
            checkpoint(6)
        finally:
            checkpoint(7)
            yield 8
        checkpoint(9)

    test(it, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9)

block:
    iterator it(): int {.closure.} =
        try:
            yield 0
            return 2
        finally:
            checkpoint(1)
        checkpoint(123)

    test(it, 0, 1)

block:
    iterator it(): int {.closure.} =
        try:
            try:
                yield 0
                raiseException()
            finally:
                checkpoint(1)
        except TestException:
            yield 2
            return
        finally:
            yield 3

        checkpoint(123)

    test(it, 0, 1, 2, 3)

block:
    iterator it(): int {.closure.} =
        try:
            try:
                yield 0
                raiseException()
            finally:
                return # Return in finally should stop exception propagation
        except AnotherException:
            yield 2
            return
        finally:
            yield 3
        checkpoint(123)

    test(it, 0, 3)

echo "ok"
