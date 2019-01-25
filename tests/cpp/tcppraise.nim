discard """
  targets: "cpp"
  output: '''foo
bar
Need odd and >= 3 digits##
baz
caught
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
