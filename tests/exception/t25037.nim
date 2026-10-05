discard """
  matrix: "--mm:orc; --mm:arc"
  output: "ok"
"""

# bug #25037: a `raise` inside an `except` block did not pop the exception
# that was being handled when the raise was nested in a try statement without
# except branches. Such a try statement is either written by the user or
# injected by the compiler in order to run destructors. The exception being
# handled was then leaked and left behind as the "current exception".

type
  InfoError = object of ValueError

proc newInfoError(info: string, parent: ref Exception): ref InfoError =
  newException(InfoError, info, parent)

proc viaProcCall() =
  # the temporary for 'getCurrentException()' requires a hidden try/finally:
  try:
    try:
      raise newException(ValueError, "msg")
    except:
      raise newInfoError("info", getCurrentException())
  except:
    discard

proc viaExceptAs() =
  try:
    try:
      raise newException(ValueError, "msg")
    except CatchableError as e:
      raise newException(InfoError, "info", e)
  except:
    discard

proc viaUserFinally() =
  try:
    try:
      raise newException(ValueError, "msg")
    except:
      try:
        raise newException(InfoError, "info")
      finally:
        discard
  except:
    discard

template checkNoLeak(call: untyped) =
  for i in 1..1000: call
  let occupied = getOccupiedMem()
  for i in 1..20_000: call
  doAssert getCurrentExceptionMsg() == "", astToStr(call)
  doAssert getOccupiedMem() <= occupied, astToStr(call) & ": " &
    $occupied & " -> " & $getOccupiedMem()

proc main() =
  checkNoLeak viaProcCall()
  checkNoLeak viaExceptAs()
  checkNoLeak viaUserFinally()
  echo "ok"

main()
