discard """
output: '''
None Some Circle Square
2 16
(x: 0.0, y: 0.0, `kind: Circle, radius: 0.0)
(`kind: Some, val: (x: 1)) (`kind: Some, val: 2) (`kind: Some, val: 3) (`kind: None)
2.5 Tree[system.float64] 7
(x: 0.0, y: 0.0, `kind: Square, w: 1.0, h: 1.0) (x: 0.0, y: 0.0, `kind: Circle, radius: 1.0)
(`kind: Some, val: "re")
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
echo t.r.v, " ", typeof(t), " ", msumtype.Leaf(v: 7).v
echo Square(w: 1.0, h: 1.0), " ", origin
let r: m2.Opt[string] = Some(val: "re")
echo r
