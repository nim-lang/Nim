discard """
  output: '''Thing
Thing'''
"""

# Test of type() operator
# Bug #3710

import typetraits

type Thing = ref object
    name: string

var x = new(Thing)
var y = type(x).name
echo y
var z = x.type.name
echo z
