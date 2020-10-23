discard """
disabled: "arm64"
cmd: "nim c --gc:arc $file"
output: "y"
"""

{.passC: "-march=native".}

proc isAlignedCheck(p: pointer, alignment: int) = 
  doAssert (cast[uint](p) and uint(alignment - 1)) == 0

proc isAlignedCheck[T](p: ref T, alignment: int) = 
  isAlignedCheck(cast[pointer](p), alignment)

type
  m256d {.importc: "__m256d", header: "immintrin.h".} = object

proc set1(x: float): m256d {.importc: "_mm256_set1_pd", header: "immintrin.h".}
func `+`(a,b: m256d): m256d {.importc: "_mm256_add_pd", header: "immintrin.h".}
proc `$`(a: m256d): string =  
  result = $(cast[ptr float](a.unsafeAddr)[])


var res: seq[seq[m256d]]

for _ in 1..1000:
  var x = newSeq[m256d](1)
  x[0] = set1(1.0) # test if operation causes segfault
  isAlignedCheck(x[0].addr, alignof(m256d))
  res.add x

var res2: seq[m256d]
for i in 1..10000:
  res2.setLen(res2.len + 1) # check if realloc works
  isAlignedCheck(res2[0].addr, alignof(m256d))  

proc lambdaGen(a, b: float, z: ref m256d) : auto =
  var x1 = new(m256d)
  var x2 = new(m256d)
  isAlignedCheck(x1, alignof(m256d))
  isAlignedCheck(x2, alignof(m256d))
  x1[] = set1(2.0 + a)  
  x2[] = set1(-23.0 - b)
  let capturingLambda = proc(x: ref m256d): ref m256d =
    var cc = new(m256d)
    var bb = new(m256d)
    isAlignedCheck(x1, alignof(m256d))
    isAlignedCheck(x2, alignof(m256d))
    isAlignedCheck(cc, alignof(m256d))
    isAlignedCheck(bb, alignof(m256d))
    isAlignedCheck(z, alignof(m256d))
        
    cc[] = x1[] + x1[] + z[]
    bb[] = x2[] + set1(12.5) + z[]
    
    result = new(m256d)
    isAlignedCheck(result, alignof(m256d))
    result[] = cc[] + bb[] + x[]
    
  return capturingLambda

var xx = new(m256d)
xx[] = set1(10)
isAlignedCheck(xx, alignOf(m256d))

let f1 = lambdaGen(2.0 , 2.221, xx)
let f2 = lambdaGen(-1.226 , 3.5, xx)
isAlignedCheck(f1(xx), alignOf(m256d))
isAlignedCheck(f2(xx), alignOf(m256d))
echo "y"
