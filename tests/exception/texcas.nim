discard """
  output: '''Hello
Hello
  '''
"""
proc test[T]() =
  try:
    raise newException(T, "Hello")
  except T as foobar:
    echo(foobar.msg)
  doAssert(not declared(foobar))

template testTemplate(excType: typedesc) =
  try:
    raise newException(excType, "Hello")
  except excType as foobar:
    echo(foobar.msg)
  doAssert(not declared(foobar))

proc test2() =
  testTemplate(Exception)
  doAssert(not declared(foobar))

test[Exception]()
test2()