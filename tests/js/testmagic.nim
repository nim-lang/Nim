discard """
  cmd: "nimrod js --hints:on -r $# $#"
  output: '''true'''
"""

# This file tests some magic

var foo = cstring("foo")
var bar = cstring("foo")
echo(foo == bar)
