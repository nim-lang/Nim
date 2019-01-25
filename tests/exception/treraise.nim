discard """
  outputsub: "Error: unhandled exception: bla [ESomeOtherErr]"
  exitcode: "1"
"""
type
  ESomething = object of Exception
  ESomeOtherErr = object of Exception

proc genErrors(s: string) =
  if s == "error!":
    raise newException(ESomething, "Test")
  else:
    raise newException(EsomeotherErr, "bla")

try:
  genErrors("errssor!")
except ESomething:
  echo("Error happened")
except:
  raise
