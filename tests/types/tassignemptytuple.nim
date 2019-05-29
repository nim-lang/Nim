discard """
  output: '''@[]
(a: @[], b: {})
'''
"""

var
  foo: seq[int]
  bar: tuple[a: seq[int], b: set[char]]

(foo, bar) = (@[], (@[], {}))
echo foo
echo bar
