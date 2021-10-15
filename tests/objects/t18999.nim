discard """
  output: '''
true
true
true
false
false
false
false
'''
"""

type
  Animal = ptr object of RootObj
  Cat = ptr object of Animal
  Plant = ptr object of RootObj
  Tree = ptr object of Plant

var cat = cast[Cat](alloc(sizeof(Cat)))
var plant = cast[Plant](alloc(sizeof(Plant)))

# true
echo cat of Cat
echo cat of Animal
echo plant of Plant

# false
echo cat of Plant
echo plant of Animal
echo plant of Cat
echo plant of Tree
