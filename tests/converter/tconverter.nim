discard """
  output: '''fooo fooo'''
"""

converter intToString[T](i: T): string = "fooo"

let
  foo: string = 1
  bar: string = intToString(2)

echo foo, " ", bar