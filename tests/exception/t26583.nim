discard """
  matrix: "--mm:orc; --mm:refc; --exceptions:setjmp; --backend:cpp; --backend:cpp --mm:refc"
  output: "ok"
"""

# bug #26583: an exception escaping from an `except` section left the exception
# that section handled on the chain of current exceptions, forever. #25037 only
# covered a `raise` that is lexically inside the `except` section with goto
# based exceptions; a raise from a called proc and setjmp based exceptions
# (the default for --mm:refc) still leaked.

type
  InfoError = object of ValueError

proc newInfoError(info: string, parent: ref Exception): ref InfoError =
  newException(InfoError, info, parent)

proc raiseInfo() =
  raise newInfoError("info", getCurrentException())

proc viaProcCall() =
  try:
    try:
      raise newException(ValueError, "msg")
    except:
      raise newInfoError("info", getCurrentException())
  except:
    discard

proc viaCalledProc() =
  try:
    try:
      raise newException(ValueError, "msg")
    except:
      raiseInfo()
  except:
    discard

proc viaReraise() =
  try:
    try:
      raise newException(ValueError, "msg")
    finally:
      discard
  except:
    discard

proc viaNestedReraise() =
  try:
    try:
      raise newException(ValueError, "msg")
    except:
      raise
  except:
    discard

proc nestedHandlers() =
  try:
    raise newException(ValueError, "outer")
  except:
    try:
      raise newException(IOError, "inner")
    except:
      doAssert getCurrentExceptionMsg() == "inner"
    doAssert getCurrentExceptionMsg() == "outer"
    try:
      try:
        raise newException(IOError, "inner")
      except:
        raiseInfo()
    except:
      doAssert getCurrentExceptionMsg() == "info"
      doAssert getCurrentException().parent.msg == "inner"
    doAssert getCurrentExceptionMsg() == "outer"
  doAssert getCurrentException() == nil

proc occupied(): int =
  when defined(gcRefc):
    GC_fullCollect()
  getOccupiedMem()

template checkNoLeak(call: untyped) =
  for i in 1..1000: call
  let before = occupied()
  for i in 1..20_000: call
  doAssert getCurrentException() == nil, astToStr(call)
  # refc's cycle collector is not precise, allow for a little slack
  doAssert occupied() <= before + 4096, astToStr(call) & ": " &
    $before & " -> " & $occupied()

proc main() =
  checkNoLeak viaProcCall()
  checkNoLeak viaCalledProc()
  checkNoLeak viaReraise()
  checkNoLeak viaNestedReraise()
  checkNoLeak nestedHandlers()
  echo "ok"

main()
