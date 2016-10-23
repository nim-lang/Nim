discard """
  output: "optimized"
"""
# bug #4227
type Vector64[N: static[int]] = array[N, int]

proc `*`*[N: static[int]](a: Vector64[N]; b: float64): Vector64[N] =
  result = a

proc `+=`*[N: static[int]](a: var Vector64[N]; b: Vector64[N]) =
  echo "regular"

proc linearCombinationMut[N: static[int]](a: float64, v: var Vector64[N], w: Vector64[N])  {. inline .} =
  echo "optimized"

template rewriteLinearCombinationMut*{v += `*`(w, a)}(a: float64, v: var Vector64, w: Vector64): auto =
  linearCombinationMut(a, v, w)

proc main() =
  const scaleVal = 9.0
  var a, b: Vector64[7]
  a += b * scaleval

main()
