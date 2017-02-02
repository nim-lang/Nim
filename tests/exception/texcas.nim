discard """
  output: '''Hello'''
"""
proc test[T]() =
  try:
    raise newException(T, "Hello")
  except T as foobar:
    echo(foobar.msg)

test[Exception]()
