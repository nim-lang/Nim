discard """
  errormsg: "type mismatch"
  line: 18
"""

# bug #3998

type Vec3[T] = array[3, T]

var vg: Vec3[float32] = Vec3([1.0f, 2.0f, 3.0f])

echo "vg[0]: " & $vg[0]  # prints 1.0    OK
echo "vg[1]: " & $vg[1]  # prints 2.0    OK
echo "vg[2]: " & $vg[2]  # prints 3.0    OK
echo ""

var ve: Vec3[float64]
ve = vg     # compiles, this MUST NOT be allowed!

