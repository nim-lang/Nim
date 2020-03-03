discard """
  outputsub: "-6"
"""
type
  ESomething = object of Exception
  ESomeOtherErr = object of Exception
  ESomethingGen[T] = object of Exception
  ESomethingGenRef[T] = ref object of Exception

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

# Issue #7845, raise generic exception
var x: ref ESomethingGen[int]
new(x)
try:
  raise x
except ESomethingGen[int] as e:
  discard

try:
  raise new(ESomethingGenRef[int])
except ESomethingGenRef[int] as e:
  discard
except:
  discard