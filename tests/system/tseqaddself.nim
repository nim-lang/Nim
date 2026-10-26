discard """
  targets: "c js"
  matrix: "--mm:refc; --mm:orc"
  output: '''
@["a", "b", "c", "a", "b", "c"]
@[1, 2, 3, 4, 2, 3]
@[1, 2, 1, 2]
'''
"""

# `add` of a seq to itself: the argument is a view into the seq that grows
var s = @["a", "b", "c"]
s.add s
echo s
var t = @[1, 2, 3, 4]
t.add t.toOpenArray(1, 2)
echo t
const v = block:
  var v = @[1, 2]
  v.add v
  v
echo v
