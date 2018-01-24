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

# see bug #7115
doAssert(not compiles(
  try: 
    echo 1
  except [KeyError as ex1, ValueError as ex2]:
    echo 2
))
