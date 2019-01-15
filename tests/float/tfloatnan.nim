discard """
output: '''
Nim: nan
Nim: nan (float)
Nim: nan (double)
'''
"""

let f = NaN
echo "Nim: ", f

let f32: float32 = NaN
echo "Nim: ", f32, " (float)"

let f64: float64 = NaN
echo "Nim: ", f64, " (double)"


proc fun() =
  # issue #10305
  # with `-O3 -ffast-math`, generated C/C++ code is not nan compliant
  # user can pass `--passC:-ffast-math` if he doesn't care.
  let a1 = 0.0
  let a = 0.0/a1
  let b1 = a == 0.0
  let b2 = a == a
  doAssert not b1
  doAssert not b2

static: fun()
fun()

