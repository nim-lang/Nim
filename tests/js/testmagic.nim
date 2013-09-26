discard """
  cmd: "nimrod js --hints:on -r $# $#"
  output: '''true'''
"""

# This file tests some magic

const foo = cstring("foo")
const bar = cstring("foo")
echo(foo == bar)
