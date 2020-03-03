discard """
  cmd: "nim $target -d:release $options $file"
  outputsub: '''tunhandledexc.nim(15)    genErrors
Error: unhandled exception: bla [ESomeOtherErr]'''
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

when true:
  try: discard except: discard

  try:
    genErrors("errssor!")
  except ESomething:
    echo("Error happened")
