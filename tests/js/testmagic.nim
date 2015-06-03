discard """
  output: '''true
123
'''
"""

# This file tests some magic

var foo = cstring("foo")
var bar = cstring("foo")
echo(foo == bar)
echo "01234"[1 .. ^2]
