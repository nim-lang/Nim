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
  echo(declared(foobar))
  doAssert(not declared(foobar))

template testTemplate() =
  try:
    raise newException(Exception, "Hello")
  except Exception as foobar:
    echo(foobar.msg)
  doAssert(not declared(foobar))

proc test2() =
  testTemplate()
  doAssert(not declared(foobar))

test[Exception]()
