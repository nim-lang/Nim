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

block: # bug #10305
  # with `-O3 -ffast-math`, generated C/C++ code is not nan compliant
  # user can pass `--passC:-ffast-math` if he doesn't care.
  proc fun() =
    # this was previously failing at compile time with a nim compiler
    # that was compiled with `nim cpp -d:release`
    let a1 = 0.0
    let a = 0.0/a1
    let b1 = a == 0.0
    let b2 = a == a
    doAssert not b1
    doAssert not b2

  proc fun2(i: int) =
    # this was previously failing simply with `nim cpp -d:release`; the
    # difference with above example is that optimization (const folding) can't
    # take place in this example to hide the non-compliant nan bug.
    let a = 0.0/(i.float)
    let b1 = a == 0.0
    let b2 = a == a
    doAssert not b1
    doAssert not b2

  static: fun()
  fun()
  fun2(0)

template main() =
  # xxx move all tests under here
  block: # bug #16469
    let a1 = 0.0
    let a2 = -0.0
    let a3 = 1.0 / a1
    let a4 = 1.0 / a2
    doAssert a3 == Inf
    doAssert a4 == -Inf
    doAssert $(a1, a2, a3, a4) == "(0.0, -0.0, inf, -inf)"

static: main()
main()
