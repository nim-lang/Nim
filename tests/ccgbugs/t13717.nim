discard """
  output: "ok"
"""

# bug #13717: redefinition of a struct in the generated C code
import m13717a, m13717b
type TypeM3[P] = P
var v: TypeM3[TypeM1]
echo "ok"
