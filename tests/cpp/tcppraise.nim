discard """
  targets: "cpp"
  output: '''foo
bar
Need odd and >= 3 digits##
baz
caught
--------
Triggered raises2
Raising ValueError
'''
"""

# bug #1888
echo "foo"
try:
  echo "bar"
  raise newException(ValueError, "Need odd and >= 3 digits")
#  echo "baz"
except ValueError:
  echo getCurrentExceptionMsg(), "##"
echo "baz"


# bug 7232
try:
 discard
except KeyError, ValueError:
  echo "except handler" # should not be invoked


#bug 7239
try:
  try:
    raise newException(ValueError, "asdf")
  except KeyError, ValueError:
    raise
except:
  echo "caught"


# issue 5549

var strs: seq[string] = @[]

try:
  discard
finally:
  for foobar in strs:
    discard


# issue #11118
echo "--------"
proc raises() =
  raise newException(ValueError, "Raising ValueError")

proc raises2() =
  try:
    raises()
  except ValueError as e:
    echo "Triggered raises2"
    raise e

try:
  raises2()
except:
  echo getCurrentExceptionMsg()
  discard

doAssert: getCurrentException() == nil

import asyncdispatch

block: # bug #14713
  proc raises(fail: bool) {.async.} =
    if fail:
      raise newException(Exception, "something bad happened")
  proc reraises() {.async.} =
    try:
      await raises(true)
    except Exception as e:
      raise e
  var caught = false
  proc catches() =
    try:
      asyncCheck reraises()
    except:
      caught = true
  catches()
  doAssert caught
