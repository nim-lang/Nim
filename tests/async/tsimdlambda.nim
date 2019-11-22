discard """
disabled: windows
output: '''
[-2.721, -2.721]
[-35.452, -35.452]
'''
"""

# flag specifically for gcc an clang
{.passC: "-march=native".}

type
  m128d {.importc: "__m128d", header: "immintrin.h".} = object

proc add(a: m128d; b: m128d): m128d {.importc: "_mm_add_pd", header: "immintrin.h".}
proc set1*(a: float): m128d {.importc: "_mm_set1_pd", header: "immintrin.h".}
func `+`(a,b: m128d): m128d = add(a, b)
proc `$`(arg: m128d): string =
  return $cast[ptr array[2,float64]](arg.unsafeAddr)[]

proc lambdaGen(a, b: float64): proc(x: m128d): m128d =
  let x1 = set1(2.0 + a)
  let x2 = set1(-23.0 - b)
  result = proc(x: m128d): m128d =
    let cc = x1 + x1
    let bb = x2 + set1(12.5)
    result = cc + bb + x

let f1 = lambdaGen(2.0 , 2.221)
let f2 = lambdaGen(-1.226 , 3.5)

echo f1(set1(2.0))
echo f2(set1(-23.0))
