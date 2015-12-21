discard """
  cmd: "nim cpp $file"
  output: '''foo
bar
Need odd and >= 3 digits##
baz'''
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
