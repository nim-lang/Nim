discard """
  output: '''
NodeNode
3
'''
"""
# without the feature `owned` is erased
type Node = ref object
  next: owned Node
var x: owned[Node]
var y = Node()
x = y
echo typeof(x), typeof(owned(Node))
proc ident[T](x: owned T): owned T = x
echo ident(3)
