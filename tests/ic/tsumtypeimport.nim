discard """
output: '''
None Some Circle Square
2 16
Circle(x: 0.0, y: 0.0, radius: 0.0)
Some(val: (x: 1)) Some(val: 2) Some(val: 3) None()
2.5 Tree[system.float64] 7
Square(x: 0.0, y: 0.0, w: 1.0, h: 1.0) Circle(x: 0.0, y: 0.0, radius: 1.0)
Some(val: "re")
'''
"""

# The enum of branch names that is generated for a sum type, its `$` and its
# link to the owner type must survive the NIF round trip.
import msumtype
import msumtype2 as m2

echo None, " ", Some, " ", Circle, " ", Square
echo ord(Square), " ", sizeof(Opt[int])
var s: Shape
echo s

type B = object
  x: int

let n: Opt[float] = None()
echo Some(val: B(x: 1)), " ", some(2), " ", mk(3), " ", n
let t = leafs(1.5, 2.5)
{.cast(uncheckedAccess).}:
  echo t.r.v, " ", typeof(t), " ", msumtype.Leaf(v: 7).v
echo Square(w: 1.0, h: 1.0), " ", origin
let r: m2.Opt[string] = Some(val: "re")
echo r
