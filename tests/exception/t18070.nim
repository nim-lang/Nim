discard """
  matrix: "--mm:orc"

"""

# bug #18070
proc main() =
  try:
    try:
      raise newException(CatchableError, "something")
    except:
      raise newException(CatchableError, "something else")
  except:
    doAssert getCurrentExceptionMsg() == "something else"

  let msg = getCurrentExceptionMsg()
  doAssert msg == "", "expected empty string but got: " & $msg

main()
