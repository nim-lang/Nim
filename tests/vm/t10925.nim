# bug #10925: `return` within `except` runs the `finally` section in the VM

proc testInc(i: var int) =
  try: raise newException(ValueError, "x")
  except: return
  finally: inc(i)

proc retInBody(log: var seq[string]): int =
  try:
    try:
      log.add "body"
      return 1
    finally:
      log.add "inner"
  finally:
    log.add "outer"

proc retInExceptNested(log: var seq[string]): int =
  try:
    try:
      raise newException(ValueError, "x")
    except ValueError:
      log.add "except"
      return 2
    finally:
      log.add "inner"
  finally:
    log.add "outer"

proc retInExceptOfOuter(log: var seq[string]): int =
  try:
    raise newException(ValueError, "x")
  except ValueError:
    try:
      log.add "except"
      return 3
    finally:
      log.add "inner"
  finally:
    log.add "outer"

proc finallyChangesResult(): int =
  try:
    raise newException(ValueError, "x")
  except:
    return 4
  finally:
    result = 5

proc main =
  var i = 0
  testInc(i)
  doAssert i == 1
  var log: seq[string] = @[]
  doAssert retInBody(log) == 1
  doAssert log == @["body", "inner", "outer"]
  log = @[]
  doAssert retInExceptNested(log) == 2
  doAssert log == @["except", "inner", "outer"]
  log = @[]
  doAssert retInExceptOfOuter(log) == 3
  doAssert log == @["except", "inner", "outer"]
  doAssert finallyChangesResult() == 5

static: main()
main()
