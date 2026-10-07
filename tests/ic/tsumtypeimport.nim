discard """
output: '''
None Some Circle Square
2 16
(x: 0.0, y: 0.0, `kind: Circle, radius: 0.0)
'''
"""

# The enum of branch names that is generated for a sum type, its `$` and its
# link to the owner type must survive the NIF round trip.
import msumtype

echo None, " ", Some, " ", Circle, " ", Square
echo ord(Square), " ", sizeof(Opt[int])
var s: Shape
echo s
