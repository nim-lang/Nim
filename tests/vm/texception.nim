proc someFunc() =
  try:
    raise newException(ValueError, "message")
  except ValueError as err:
    doAssert err.name == "ValueError"
    doAssert err.msg == "message"
    raise

static:
  try:
    someFunc()
  except:
    discard
  