{.experimental: "strictDefs".}


proc bar(x: out string) =
  x = "abc"

template moe = # bug #21043
  try:
    discard
  except ValueError as e:
    echo(e.msg)

template moe0 {.dirty.} = # bug #21043
  try:
    discard
  except ValueError as e:
    echo(e.msg)

proc foo() =
  block:
    let x: string
    if true:
      x = "abc"
    else:
      x = "def"
    doAssert x == "abc"
  block:
    let y: string
    bar(y)
    doAssert y == "abc"
  block:
    let x: string
    if true:
      x = "abc"
      discard "abc"
    else:
      x = "def"
      discard "def"
    doAssert x == "abc"
  block: #
    let x {.used.} : int
  block: #
    let x: float
    x = 1.234
    doAssert x == 1.234

  moe()
  moe0()
static: foo()
foo()

block:
  var closureIterResult = newSeq[int]()

  type
    TestError = object of CatchableError
  proc raiseTestError() =
    raise newException(TestError, "Test exception!")

  proc testClosureIterAux(it: iterator(): int, exceptionExpected: bool, expectedResults: varargs[int]) =
    closureIterResult.setLen(0)

    var exceptionCaught = false

    try:
      for i in it():
        closureIterResult.add(i)
    except TestError:
      exceptionCaught = true

    if closureIterResult != @expectedResults or exceptionCaught != exceptionExpected:
      if closureIterResult != @expectedResults:
        echo "Expected: ", @expectedResults
        echo "Actual: ", closureIterResult
      if exceptionCaught != exceptionExpected:
        echo "Expected exception: ", exceptionExpected
        echo "Got exception: ", exceptionCaught
      doAssert(false)

  iterator it(): int {.closure.} =
    var foo = 123
    let i = try:
        yield 0
        raiseTestError()
        1
      except TestError as e:
        assert(e.msg == "Test exception!")
        case foo
        of 1:
          yield 123
          2
        of 123:
          yield 5
          6
        else:
          7
    yield i

  proc test(it: iterator(): int, expectedResults: varargs[int]) =
    testClosureIterAux(it, false, expectedResults)

  test(it, 0, 5, 6)
