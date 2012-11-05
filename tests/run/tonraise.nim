discard """
  output: '''i: 1
success'''
"""

type
  ESomething = object of E_Base
  ESomeOtherErr = object of E_Base

proc genErrors(s: string) =
  if s == "error!":
    raise newException(ESomething, "Test")
  else:
    raise newException(EsomeotherErr, "bla")

proc foo() =
  var i = 0
  try:
    inc i
    onRaise(proc (e: ref E_Base): bool =
      echo "i: ", i)
    genErrors("errssor!")
  except ESomething:
    echo("ESomething happened")
  except:
    echo("Some other error happened")
    
  # test that raise handler is gone:
  try:
    genErrors("error!")
  except ESomething:
    echo "success"

foo()
