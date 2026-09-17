discard """
  output: '''
2
1
2
1
2
1
'''
  matrix: "--mm:arc; --mm:orc; --gc:refc"
"""

proc read() =
  if true:
    raise newException(ValueError, "foo")

block:
  iterator count1(): int {.closure.} =
    yield 1
    read()

  iterator count0(): int {.closure.} =
    try:
      yield 2
      for x in count1(): echo x
    except Exception:
      raise

  proc main =
    for x in count0(): echo x
  
  try:
    main()
    doAssert false
  except ValueError as err:
    let expected = """
t24670.nim(33)           t24670
t24670.nim(30)           main
t24670.nim(25)           count0
t24670.nim(20)           count1
t24670.nim(15)           read
[[reraised from:
t24670.nim(33)           t24670
t24670.nim(30)           main
t24670.nim(22)           count0
]]
"""
    doAssert err.getStackTrace() == expected, err.getStackTrace()

block:
  iterator count1(): int {.closure.} =
    yield 1
    read()

  iterator count0(): int {.closure.} =
    try:
      yield 2
      var it = count1
      echo it()
      echo it()
    except Exception:
      raise

  proc main =
    var it = count0
    echo it()
    echo it()
  
  try:
    main()
    doAssert false
  except ValueError as err:
    let expected = """
t24670.nim(70)           t24670
t24670.nim(67)           main
t24670.nim(60)           count0
t24670.nim(53)           count1
t24670.nim(15)           read
[[reraised from:
t24670.nim(70)           t24670
t24670.nim(67)           main
t24670.nim(55)           count0
]]
"""
    doAssert err.getStackTrace() == expected, err.getStackTrace()

block:
  iterator count1(): int {.closure.} =
    yield 1
    read()

  iterator count0(): int {.closure.} =
    try:
      yield 2
      var foo = count1
      while true:
        echo foo()
        if finished(foo): break
    except Exception:
      raise

  proc main =
    var foo = count0
    while true:
      echo foo()
      if finished(foo): break

  try:
    main()
    doAssert false
  except ValueError as err:
    let expected = """
t24670.nim(109)          t24670
t24670.nim(105)          main
t24670.nim(97)           count0
t24670.nim(90)           count1
t24670.nim(15)           read
[[reraised from:
t24670.nim(109)          t24670
t24670.nim(105)          main
t24670.nim(92)           count0
]]
"""
    doAssert err.getStackTrace() == expected, err.getStackTrace()

block:
  iterator count1(): int {.closure.} =
    yield 1
    read()

  iterator count0(): int {.closure.} =
    try:
      var it = count1
      yield it()
      yield it()
    finally:
      var it = count1
      yield it()
      yield it()

  proc main =
    for x in count0():
      discard x

  try:
    main()
    doAssert false
  except ValueError as err:
    let expected = """
t24670.nim(146)          t24670
t24670.nim(143)          main
t24670.nim(139)          count0
t24670.nim(129)          count1
t24670.nim(15)           read
[[reraised from:
t24670.nim(146)          t24670
t24670.nim(143)          main
t24670.nim(131)          count0
]]
"""
    doAssert err.getStackTrace() == expected, err.getStackTrace()
