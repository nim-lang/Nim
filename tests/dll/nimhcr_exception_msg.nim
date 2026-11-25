discard """
  output: '''
boom
set by hand
true'''
"""

# With hot code reloading the program uses nimrtl, which holds the current
# exception of the thread. `getCurrentExceptionMsg` and `setCurrentException`
# read and wrote a copy of that state in the program instead, which nothing
# raised into: the message came back empty, and a set exception was not seen
# by `getCurrentException`.

try:
  raise newException(ValueError, "boom")
except ValueError:
  echo getCurrentExceptionMsg()

let e = newException(IOError, "set by hand")
setCurrentException(e)
echo getCurrentExceptionMsg()
echo getCurrentException() == e
setCurrentException(nil)
