discard """
  outputsub: "ECcaught"
  exitcode: "1"
"""
type
  ESomething = object of Exception
  ESomeOtherErr = object of Exception

proc genErrors(s: string) =
  if s == "error!":
    raise newException(ESomething, "Test")
  else:
    raise newException(ESomeOtherErr, "bla")

try:
  for i in 0..3:
    try:
      genErrors("error!")
    except ESomething:
      stdout.write("E")
    stdout.write("C")
    raise newException(ESomeOtherErr, "bla")
finally:
  echo "caught"

#OUT ECcaught
