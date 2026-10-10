discard """
  output: '''done'''
"""
# Issue #9617: Compiler error with sequences of destructible types
# https://github.com/nim-lang/Nim/issues/9617

type
  Foo* = object

  Bar = ref object
    s: seq[Foo]

proc `=destroy`*(self: var Foo) = echo "hi"

proc test(b: Bar) =
  for i in b.s:
    discard

test(Bar())
echo "done"
