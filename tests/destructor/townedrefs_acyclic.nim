discard """
  output: '''
Node false
Plain true
A true B true
Tree false
Widget false Widget2 true
Env false
'''
"""
# owning edges form a forest: a type whose references are all `owned` or
# `.cursor` cannot be part of a cycle and stays out of the cycle collector.
{.experimental: "ownedRefs".}
import std/typetraits
type
  Node = ref object
    next: owned Node
    data: int
  Plain = ref object
    next: Plain
  A = ref object
    b: owned B
  B = ref object
    a: A
  Tree = ref object
    kids: seq[owned Tree]
    parent {.cursor.}: Tree
  Widget = ref object
    onChange: owned proc ()
  Widget2 = ref object
    onChange: proc ()
  Env = ref object
    w: owned Widget
    x: owned Node

echo "Node ", canFormCycles(Node)
echo "Plain ", canFormCycles(Plain)
echo "A ", canFormCycles(A), " B ", canFormCycles(B)
echo "Tree ", canFormCycles(Tree)
echo "Widget ", canFormCycles(Widget), " Widget2 ", canFormCycles(Widget2)
echo "Env ", canFormCycles(Env)
