discard """
  outputsub: "-6"
"""
type
  ESomething = object of Exception
  ESomeOtherErr = object of Exception

proc genErrors(s: string) =
  if s == "error!":
    raise newException(ESomething, "Test")
  else:
    raise newException(EsomeotherErr, "bla")

proc raiseBla(): int =
  try:
    genErrors("errssor!")
  except ESomething:
    echo("Error happened")
  except:
    raise

proc blah(): int =
  try:
    result = raiseBla()
  except ESomeOtherErr:
    result = -6

echo blah()


